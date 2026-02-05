#if appleOS
import Foundation

public protocol _MutablePropertySelectorProtocol<Value>: _PropertySelectorProtocol {
	var setter: Selector { get }
}

public struct _MutablePropertySelector<Value>: _MutablePropertySelectorProtocol {
	public var getter: Selector
	public var setter: Selector

	private init(
		getter: Selector,
		setter: Selector
	) {
		self.getter = getter
		self.setter = setter
	}

	public init?<Object: NSObject>(_ keyPath: WritableKeyPath<Object, Value>) {
		guard 
			let getter = keyPath.getterSelector,
			let setter = keyPath.setterSelector
		else { return nil }
		self.init(
			getter: getter,
			setter: setter
		)
	}

	public static func _unchecked(
		getter: Selector,
		setter: Selector
	) -> _MutablePropertySelector {
		return .init(
			getter: getter,
			setter: setter
		)
	}
}

public func _unsafeMakePropertySelector<Object: NSObject, Value>(
	_ keyPath: WritableKeyPath<Object, Value>
) -> _MutablePropertySelector<Value> {
	return .init(keyPath)!
}
#endif
