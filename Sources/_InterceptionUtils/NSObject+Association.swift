import Foundation
import _InterceptionUtilsObjc

public struct AssociationKey<Value> {
	fileprivate let address: UnsafeRawPointer
	fileprivate let `default`: Value!
	
	/// Create an ObjC association key.
	///
	/// - warning: The key must be uniqued.
	///
	/// - parameters:
	///   - default: The default value, or `nil` to trap on undefined value. It is
	///              ignored if `Value` is an optional.
	public init(default: Value? = nil) {
		self.address = UnsafeRawPointer(
			UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
		)
		self.default = `default`
	}
	
	/// Create an ObjC association key from a `StaticString`.
	///
	/// - precondition: `key` has a pointer representation.
	///
	/// - parameters:
	///   - default: The default value, or `nil` to trap on undefined value. It is
	///              ignored if `Value` is an optional.
	public init(_ key: StaticString, default: Value? = nil) {
		assert(key.hasPointerRepresentation)
		self.address = UnsafeRawPointer(key.utf8Start)
		self.default = `default`
	}
	
	/// Create an ObjC association key from a `Selector`.
	///
	/// - parameters:
	///   - default: The default value, or `nil` to trap on undefined value. It is
	///              ignored if `Value` is an optional.
	public init(_ key: Selector, default: Value? = nil) {
		self.address = UnsafeRawPointer(key.utf8Start)
		self.default = `default`
	}
}

public struct Associations<Base: AnyObject> {
	fileprivate let base: Base
	
	public init(_ base: Base) {
		self.base = base
	}
}

extension NSObjectProtocol {
	/// Retrieve the associated value for the specified key. If the value does not
	/// exist, `initial` would be called and the returned value would be
	/// associated subsequently.
	///
	/// - parameters:
	///   - key: An optional key to differentiate different values.
	///   - initial: The action that supples an initial value.
	///
	/// - returns: The associated value for the specified key.
	public func associatedValue<T>(
		forKey key: StaticString = #function,
		initial: (Self) -> T
	) -> T {
		let key = AssociationKey<T?>(key)
		
		if let value = associations.value(forKey: key) {
			return value
		}
		
		let value = initial(self)
		associations.setValue(value, forKey: key)
		
		return value
	}
}

extension NSObjectProtocol {
	@nonobjc public var associations: Associations<Self> {
		return Associations(self)
	}
}

extension Associations {
	/// Retrieve the associated value for the specified key.
	///
	/// - parameters:
	///   - key: The key.
	///
	/// - returns: The associated value, or the default value if no value has been
	///            associated with the key.
	public func value<Value>(
		forKey key: AssociationKey<Value>
	) -> Value {
		return (objc_getAssociatedObject(base, key.address) as! Value?) ?? key.default
	}
	
	/// Retrieve the associated value for the specified key.
	///
	/// - parameters:
	///   - key: The key.
	///
	/// - returns: The associated value, or `nil` if no value is associated with
	///            the key.
	public func value<Value>(
		forKey key: AssociationKey<Value?>
	) -> Value? {
		return objc_getAssociatedObject(base, key.address) as! Value?
	}
	
	/// Set the associated value for the specified key.
	///
	/// - parameters:
	///   - value: The value to be associated.
	///   - key: The key.
	public func setValue<Value>(
		_ value: Value,
		forKey key: AssociationKey<Value>,
		policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC
	) {
		objc_setAssociatedObject(base, key.address, value, policy)
	}
	
	/// Set the associated value for the specified key.
	///
	/// - parameters:
	///   - value: The value to be associated.
	///   - key: The key.
	public func setValue<Value>(
		_ value: Value?,
		forKey key: AssociationKey<Value?>,
		policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC
	) {
		objc_setAssociatedObject(base, key.address, value, policy)
	}
}

/// Set the associated value for the specified key.
///
/// - parameters:
///   - value: The value to be associated.
///   - key: The key.
///   - address: The address of the object.
public func unsafeSetAssociatedValue<Value>(
	_ value: Value?,
	forKey key: AssociationKey<Value>,
	forObjectAt address: UnsafeRawPointer,
	policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC
) {
	_swiftInterceptionSetAssociatedObject(
		address,
		key.address,
		value,
		policy
	)
}
