#if canImport(Combine)
import Foundation
import _InterceptionUtils
import _InterceptionCustomSelectors

/// Whether the runtime subclass has already been prepared for method
/// interception.
private let interceptedKey = AssociationKey(default: false)

/// Holds the method signature cache of the runtime subclass.
private let signatureCacheKey = AssociationKey<SignatureCache>()

/// Holds the method selector cache of the runtime subclass.
private let selectorCacheKey = AssociationKey<SelectorCache>()

internal let noImplementation: IMP = unsafeBitCast(Int(0), to: IMP.self)

extension NSObject {
	/// Sets interception handler, which accepts ``InterceptionResult`` containing a tuple
	/// of bridged arguments and bridged output, at the end of every invocation of `selector` on the object.
	///
	/// - warning: Handlers should not call the method specified by the selector.
	///
	/// - Parameters:
	///  - selector: The selector to observe.
	///  - key: Registration key for the interception handler
	///  - action: Action to perform when `selector` was triggered
	public func setInterceptionHandler(
		for selector: Selector,
		key: AnyHashable? = nil,
		action: ((InterceptionResult<Any, Any>) -> Void)?
	) {
		let handler = _intercept(selector)
		handler.register(
			action.map(SimpleInterceptionHandler.init),
			for: SwiftInterceptionDefaultInterceptionHandlerKey.unwrap(key)
		)
	}

	/// Sets interception handler, which accepts ``InterceptionResult`` containing a tuple
	/// of casted arguments and casted output, at the end of every invocation of `selector` on the object.
	///
	/// - warning: Handlers should not call the method specified by the selector.
	///
	/// - Parameters:
	///  - selector: The selector to observe.
	///  - key: Registration key for the interception handler
	///  - action: Action to perform when `selector` was triggered
	public func setInterceptionHandler<Args, Output>(
		for selector: _MethodSelector<Args, Output>,
		key: AnyHashable? = nil,
		action: ((InterceptionResult<Args, Output>) -> Void)?
	) {
		let handler = _intercept(selector.wrappedValue)

		guard let action else {
			handler.register(nil, for: SwiftInterceptionDefaultInterceptionHandlerKey.unwrap(key))
			return
		}

		handler.register(
			SimpleInterceptionHandler {
				action($0.unsafeCast(
					args: Args.self,
					output: Output.self
				))
			},
			for: SwiftInterceptionDefaultInterceptionHandlerKey.unwrap(key)
		)
	}

	/// Setup the method interception.
	@_spi(Internals)
	@nonobjc public func _intercept(_ selector: Selector) -> InterceptionHandlers {
		guard let method = class_getInstanceMethod(objcClass, selector) else {
			fatalError(
				"Selector `\(selector)` does not exist in class `\(String(describing: objcClass))`."
			)
		}
		
		let typeEncoding = method_getTypeEncoding(method)!
		assert(checkTypeEncoding(typeEncoding))
		
		return synchronized(self) {
			let alias = selector.alias
			let handlerKey = AssociationKey<InterceptionHandlers?>(alias)
			let interopAlias = selector.interopAlias
			
			if let handler = associations.value(forKey: handlerKey) {
				return handler
			}
			
			let subclass: AnyClass = swizzleClass(self)
			let subclassAssociations = Associations(subclass as AnyObject)
			
			synchronized(subclass) {
				let isSwizzled = subclassAssociations.value(forKey: interceptedKey)
				
				let signatureCache: SignatureCache
				let selectorCache: SelectorCache
				
				if isSwizzled {
					signatureCache = subclassAssociations.value(forKey: signatureCacheKey)
					selectorCache = subclassAssociations.value(forKey: selectorCacheKey)
				}
				else {
					signatureCache = SignatureCache()
					selectorCache = SelectorCache()
					
					subclassAssociations.setValue(signatureCache, forKey: signatureCacheKey)
					subclassAssociations.setValue(selectorCache, forKey: selectorCacheKey)
					subclassAssociations.setValue(true, forKey: interceptedKey)
					
					enableMessageForwarding(subclass, selectorCache)
					setupMethodSignatureCaching(subclass, signatureCache)
				}
				
				selectorCache.cache(selector)
				
				if signatureCache[selector] == nil {
					let signature = NSMethodSignature.objcSignature(withObjCTypes: typeEncoding)
					signatureCache[selector] = signature
				}
				
				// If an immediate implementation of the selector is found in the
				// runtime subclass the first time the selector is intercepted,
				// preserve the implementation.
				//
				// Example: KVO setters if the instance is swizzled by KVO before combine-interception
				//          does.
				if !class_respondsToSelector(subclass, interopAlias) {
					let immediateImpl = class_getImmediateMethod(subclass, selector)
						.flatMap(method_getImplementation)
						.flatMap { $0 != _swiftInterceptionMsgForward ? $0 : nil }

					if let impl = immediateImpl {
						let succeeds = class_addMethod(subclass, interopAlias, impl, typeEncoding)
						precondition(
							succeeds,
							"combine-interception attempts to swizzle a selector that has message forwarding enabled with a runtime injected implementation. This is unsupported in the current version."
						)
					}
				}
			}
			
			let handler = InterceptionHandlers()
			associations.setValue(handler, forKey: handlerKey)

			// Start forwarding the messages of the selector.
			_ = class_replaceMethod(subclass, selector, _swiftInterceptionMsgForward, typeEncoding)

			return handler
		}
	}
}

/// Swizzle `realClass` to enable message forwarding for method interception.
///
/// - parameters:
///   - realClass: The runtime subclass to be swizzled.
private func enableMessageForwarding(_ realClass: AnyClass, _ selectorCache: SelectorCache) {
	let perceivedClass: AnyClass = class_getSuperclass(realClass)!
	
	typealias ForwardInvocationImpl = @convention(block) (Unmanaged<NSObject>, AnyObject) -> Void
	let newForwardInvocation: ForwardInvocationImpl = { objectRef, invocation in
		let selector = invocation.selector!
		let alias = selectorCache.alias(for: selector)
		let interopAlias = selectorCache.interopAlias(for: selector)
		
		defer {
			let handlerKey = AssociationKey<InterceptionHandlers?>(alias)
			if let handler = objectRef.takeUnretainedValue().associations.value(forKey: handlerKey) {
				handler(invocation)
			}
		}
		
		let method = class_getInstanceMethod(perceivedClass, selector)
		let typeEncoding: String
		
		if let runtimeTypeEncoding = method.flatMap(method_getTypeEncoding) {
			typeEncoding = String(cString: runtimeTypeEncoding)
		}
		else {
			let methodSignature = (objectRef.takeUnretainedValue() as AnyObject)
				.objcMethodSignature(for: selector)
			let encodings = (0..<methodSignature.objcNumberOfArguments!)
				.map { UInt8(methodSignature.objcArgumentType(at: $0).pointee) }
			typeEncoding = String(bytes: encodings, encoding: .ascii)!
		}
		
		if class_respondsToSelector(realClass, interopAlias) {
			// combine-interception has preserved an immediate implementation found in the runtime
			// subclass that was supplied by an external party.
			//
			// As the KVO setter relies on the selector to work, it has to be invoked
			// by swapping in the preserved implementation and restore to the message
			// forwarder afterwards.
			//
			// However, the IMP cache would be thrashed due to the swapping.
			
			let topLevelClass: AnyClass = object_getClass(objectRef.takeUnretainedValue())!
			
			// The locking below prevents combine-interception swizzling attempts from intervening the
			// invocation.
			//
			// Given the implementation of `swizzleClass`, `topLevelClass` can only be:
			// (1) the same as `realClass`; or (2) a subclass of `realClass`. In other
			// words, this would deadlock only if the locking order is not followed in
			// other nested locking scenarios of these metaclasses at compile time.
			
			synchronized(topLevelClass) {
				func swizzle() {
					let interopImpl = class_getMethodImplementation(topLevelClass, interopAlias)!
					
					let previousImpl = class_replaceMethod(topLevelClass, selector, interopImpl, typeEncoding)
					invocation.objcInvoke()
					
					_ = class_replaceMethod(
						topLevelClass,
						selector,
						previousImpl ?? noImplementation,
						typeEncoding
					)
				}
				
				if topLevelClass != realClass {
					synchronized(realClass) {
						// In addition to swapping in the implementation, the message
						// forwarding needs to be temporarily disabled to prevent circular
						// invocation.
						_ = class_replaceMethod(realClass, selector, noImplementation, typeEncoding)
						swizzle()
						_ = class_replaceMethod(
							realClass,
							selector,
							_swiftInterceptionMsgForward,
							typeEncoding
						)
					}
				}
				else {
					swizzle()
				}
			}
			
			return
		}
		
		let impl: IMP = method.map(method_getImplementation) ?? _swiftInterceptionMsgForward
		if impl != _swiftInterceptionMsgForward {
			// The perceived class, or its ancestors, responds to the selector.
			//
			// The implementation is invoked through the selector alias, which
			// reflects the latest implementation of the selector in the perceived
			// class.
			
			if class_getMethodImplementation(realClass, alias) != impl {
				// Update the alias if and only if the implementation has changed, so as
				// to avoid thrashing the IMP cache.
				_ = class_replaceMethod(realClass, alias, impl, typeEncoding)
			}
			
			invocation.objcSetSelector(alias)
			invocation.objcInvoke()
			
			return
		}
		
		// Forward the invocation to the closest `forwardInvocation(_:)` in the
		// inheritance hierarchy, or the default handler returned by the runtime
		// if it finds no implementation.
		typealias SuperForwardInvocation = @convention(c) (Unmanaged<NSObject>, Selector, AnyObject) ->
		Void
		let forwardInvocationImpl = class_getMethodImplementation(
			perceivedClass,
			ObjCSelector.forwardInvocation
		)
		let forwardInvocation = unsafeBitCast(forwardInvocationImpl, to: SuperForwardInvocation.self)
		forwardInvocation(objectRef, ObjCSelector.forwardInvocation, invocation)
	}
	
	_ = class_replaceMethod(
		realClass,
		ObjCSelector.forwardInvocation,
		imp_implementationWithBlock(newForwardInvocation as Any),
		ObjCMethodEncoding.forwardInvocation
	)
}

/// Swizzle `realClass` to accelerate the method signature retrieval, using a
/// signature cache that covers all known intercepted selectors of `realClass`.
///
/// - parameters:
///   - realClass: The runtime subclass to be swizzled.
///   - signatureCache: The method signature cache.
private func setupMethodSignatureCaching(_ realClass: AnyClass, _ signatureCache: SignatureCache) {
	let perceivedClass: AnyClass = class_getSuperclass(realClass)!
	
	let newMethodSignatureForSelector:
	@convention(block) (Unmanaged<NSObject>, Selector) -> AnyObject? = { objectRef, selector in
		if let signature = signatureCache[selector] {
			return signature
		}
		
		typealias SuperMethodSignatureForSelector = @convention(c) (
			Unmanaged<NSObject>, Selector, Selector
		) -> AnyObject?
		let impl = class_getMethodImplementation(
			perceivedClass,
			ObjCSelector.methodSignatureForSelector
		)
		let methodSignatureForSelector = unsafeBitCast(impl, to: SuperMethodSignatureForSelector.self)
		return methodSignatureForSelector(
			objectRef,
			ObjCSelector.methodSignatureForSelector,
			selector
		)
	}
	
	_ = class_replaceMethod(
		realClass,
		ObjCSelector.methodSignatureForSelector,
		imp_implementationWithBlock(newMethodSignatureForSelector as Any),
		ObjCMethodEncoding.methodSignatureForSelector
	)
}

@_spi(Internals)
public struct SwiftInterceptionDefaultInterceptionHandlerKey: Hashable {
	public static let shared: Self = .init()

	private init() {}

	public static func unwrap(_ key: AnyHashable?) -> AnyHashable {
		key ?? Self.shared as AnyHashable
	}
}

@_spi(Internals)
public protocol InterceptionHandlerProtocol {
	func handle(_ result: InterceptionResult<Any, Any>)
}

extension InterceptionHandlerProtocol {
	@inlinable
	public func callAsFunction(_ result: InterceptionResult<Any, Any>) {
		self.handle(result)
	}
}

@_spi(Internals)
public struct SimpleInterceptionHandler: InterceptionHandlerProtocol {
	private var _action: (InterceptionResult<Any, Any>) -> Void

	public init(_ action: @escaping (InterceptionResult<Any, Any>) -> Void) {
		self._action = action
	}

	public func handle(_ result: InterceptionResult<Any, Any>) {
		self._action(result)
	}
}

/// The state of an intercepted method specific to an instance.
@_spi(Internals)
public final class InterceptionHandlers {
	private var storage: [AnyHashable: InterceptionHandlerProtocol] = [:]

	public subscript(key: AnyHashable) -> InterceptionHandlerProtocol? {
		set { self.storage[key] = newValue }
		_read { yield self.storage[key] }
		_modify { yield &self.storage[key] }
	}

	public func register(_ handler: InterceptionHandlerProtocol?, for key: AnyHashable) {
		storage[key] = handler
	}

	public func callAsFunction(_ invocation: AnyObject) {
		let unpackedInvocation = unpackInvocation(invocation)
		storage.values.forEach { $0(unpackedInvocation) }
	}
}

private final class SelectorCache {
	private var map: [Selector: (main: Selector, interop: Selector)] = [:]
	
	init() {}
	
	/// Cache the aliases of the specified selector in the cache.
	///
	/// - warning: Any invocation of this method must be synchronized against the
	///            runtime subclass.
	@discardableResult
	func cache(_ selector: Selector) -> (main: Selector, interop: Selector) {
		if let pair = map[selector] {
			return pair
		}
		
		let aliases = (selector.alias, selector.interopAlias)
		map[selector] = aliases
		
		return aliases
	}
	
	/// Get the alias of the specified selector.
	///
	/// - parameters:
	///   - selector: The selector alias.
	func alias(for selector: Selector) -> Selector {
		if let (main, _) = map[selector] {
			return main
		}
		
		return selector.alias
	}
	
	/// Get the secondary alias of the specified selector.
	///
	/// - parameters:
	///   - selector: The selector alias.
	func interopAlias(for selector: Selector) -> Selector {
		if let (_, interop) = map[selector] {
			return interop
		}
		
		return selector.interopAlias
	}
}

// The signature cache for classes that have been swizzled for method
// interception.
//
// Read-copy-update is used here, since the cache has multiple readers but only
// one writer.
private final class SignatureCache {
	// `Dictionary` takes 8 bytes for the reference to its storage and does CoW.
	// So it should not encounter any corrupted, partially updated state.
	private var map: [Selector: AnyObject] = [:]
	
	init() {}
	
	/// Get or set the signature for the specified selector.
	///
	/// - warning: Any invocation of the setter must be synchronized against the
	///            runtime subclass.
	///
	/// - parameters:
	///   - selector: The method signature.
	subscript(selector: Selector) -> AnyObject? {
		set {
			if map[selector] == nil {
				map[selector] = newValue
			}
		}
		_read { yield self.map[selector] }
		_modify {
			yield &self.map[selector]
		}
	}
}

/// Assert that the method does not contain types that cannot be intercepted.
///
/// - parameters:
///   - types: The type encoding C string of the method.
///
/// - returns: `true`.
private func checkTypeEncoding(_ types: UnsafePointer<CChar>) -> Bool {
	// Some types, including vector types, are not encoded. In these cases the
	// signature starts with the size of the argument frame.
	assert(
		types.pointee < Int8(UInt8(ascii: "1")) || types.pointee > Int8(UInt8(ascii: "9")),
		"unknown method return type not supported in type encoding: \(String(cString: types))"
	)
	
	assert(types.pointee != Int8(UInt8(ascii: "(")), "union method return type not supported")
	assert(types.pointee != Int8(UInt8(ascii: "{")), "struct method return type not supported")
	assert(types.pointee != Int8(UInt8(ascii: "[")), "array method return type not supported")
	
	assert(types.pointee != Int8(UInt8(ascii: "j")), "complex method return type not supported")
	
	return true
}

/// Extract the arguments of an `NSInvocation` as an array of objects.
///
/// - parameters:
///   - invocation: The `NSInvocation` to unpack.
///
/// - returns: An array of objects.
private func unpackInvocation(_ invocation: AnyObject) -> InterceptionResult<Any, Any> {
	let invocation = invocation as AnyObject
	let methodSignature = invocation.objcMethodSignature!
	let count = methodSignature.objcNumberOfArguments!
	
	var args: Any = ()

	if count > 2 {
		args = decodeValueFromInvocation(
			rawEncoding: methodSignature.objcArgumentType(at: 2),
			value: { invocation.objcCopy(to: $0, forArgumentAt: 2) }
		)
	}

	if count > 3 {
		// Ignore `self` and `_cmd` at index 0 and 1.
	 for position in 3..<count {
		 args = (args, decodeValueFromInvocation(
			 rawEncoding: methodSignature.objcArgumentType(at: position),
			 value: { invocation.objcCopy(to: $0, forArgumentAt: Int(position)) }
		 ))
	 }
	}
	
	let output = decodeValueFromInvocation(
		rawEncoding: methodSignature.objcMethodReturnType,
		value: { invocation.objcCopyReturnValue(to: $0) }
	)
	
	return InterceptionResult(
		args: args,
		output: output
	)
}

private func decodeValueFromInvocation(
	rawEncoding: UnsafePointer<CChar>,
	value extractValueToBuffer: (UnsafeMutableRawPointer) -> Void
) -> Any {
	let encoding = ObjCTypeEncoding(rawValue: rawEncoding.pointee) ?? .undefined
	let value: Any
	
	func extract<T>(_ type: T.Type) -> T {
		let pointer = UnsafeMutableRawPointer.allocate(
			byteCount: MemoryLayout<T>.size,
			alignment: MemoryLayout<T>.alignment
		)
		
		defer {
			pointer.deallocate()
		}
		
		extractValueToBuffer(pointer)
		return pointer.assumingMemoryBound(to: type).pointee
	}
	
	switch encoding {
	case .char:
		value = NSNumber(value: extract(CChar.self))
	case .int:
		value = NSNumber(value: extract(CInt.self))
	case .short:
		value = NSNumber(value: extract(CShort.self))
	case .long:
		value = NSNumber(value: extract(CLong.self))
	case .longLong:
		value = NSNumber(value: extract(CLongLong.self))
	case .unsignedChar:
		value = NSNumber(value: extract(CUnsignedChar.self))
	case .unsignedInt:
		value = NSNumber(value: extract(CUnsignedInt.self))
	case .unsignedShort:
		value = NSNumber(value: extract(CUnsignedShort.self))
	case .unsignedLong:
		value = NSNumber(value: extract(CUnsignedLong.self))
	case .unsignedLongLong:
		value = NSNumber(value: extract(CUnsignedLongLong.self))
	case .float:
		value = NSNumber(value: extract(CFloat.self))
	case .double:
		value = NSNumber(value: extract(CDouble.self))
	case .bool:
		value = NSNumber(value: extract(CBool.self))
	case .object:
		value = extract(Optional<AnyObject>.self) as Any
	case .type:
		value = extract(Optional<AnyClass>.self) as Any
	case .selector:
		value = extract(Optional<Selector>.self) as Any
	case .void:
		value = ()
	case .undefined:
		var (size, alignment) = (0, 0)
		NSGetSizeAndAlignment(rawEncoding, &size, &alignment)
		let buffer = UnsafeMutableRawPointer.allocate(
			byteCount: size, 
			alignment: alignment
		)
		defer { buffer.deallocate() }
		
		extractValueToBuffer(buffer)
		value = NSValue(bytes: buffer, objCType: rawEncoding)
	}
	
	return value
}
#endif
