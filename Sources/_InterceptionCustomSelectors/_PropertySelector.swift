#if appleOS
import Foundation

public protocol _PropertySelectorProtocol<Value> {
	associatedtype Value
	var getter: Selector { get }
}

public struct _ReadonlyPropertySelector<Value>: _PropertySelectorProtocol {
	public var getter: Selector

	private init(getter: Selector) {
		self.getter = getter
	}

	public init?<Object: NSObject>(_ keyPath: KeyPath<Object, Value>) {
		guard let getter = keyPath.getterSelector else { return nil }
		self.init(getter: getter)
	}

	public static func _unchecked(_ selector: Selector) -> _ReadonlyPropertySelector {
		return .init(getter: selector)
	}
}

public func _unsafeMakePropertySelector<Object: NSObject, Value>(
	_ keyPath: KeyPath<Object, Value>
) -> _ReadonlyPropertySelector<Value> {
	return .init(keyPath)!
}
#endif
