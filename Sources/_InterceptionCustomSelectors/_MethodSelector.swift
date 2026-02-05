#if appleOS
import Foundation

public protocol _MethodSelectorProtocol<Args, Output> {
	associatedtype Args
	associatedtype Output
	var wrappedValue: Selector { get }
}

public struct _MethodSelector<Args, Output>: _MethodSelectorProtocol {
	public var wrappedValue: Selector

	fileprivate init(_ selector: Selector) {
		self.wrappedValue = selector
	}

	public static func _unchecked(_ selector: Selector) -> _MethodSelector {
		return .init(selector)
	}
}

public func _makeMethodSelector<Output>(
	selector: Selector,
	signature: (() -> Output)?
) -> _MethodSelector<Void, Output> {
	return ._unchecked(selector)
}

public func _makeMethodSelector<Arg, Output>(
	selector: Selector,
	signature: ((Arg) -> Output)?
) -> _MethodSelector<(Arg), Output> {
	return ._unchecked(selector)
}

@_disfavoredOverload
public func _makeMethodSelector<each Arg, Output>(
	selector: Selector,
	signature: ((repeat each Arg) -> Output)?
) -> _MethodSelector<(repeat each Arg), Output> {
	return ._unchecked(selector)
}

public func _makeMethodSelector<Object, Output>(
	selector: Selector,
	signature: (Object) -> (() -> Output)?
) -> _MethodSelector<Void, Output> {
	return ._unchecked(selector)
}

public func _makeMethodSelector<Object, Arg, Output>(
	selector: Selector,
	signature: (Object) -> ((Arg) -> Output)?
) -> _MethodSelector<(Arg), Output> {
	return ._unchecked(selector)
}

@_disfavoredOverload
public func _makeMethodSelector<Object, each Arg, Output>(
	selector: Selector,
	signature: (Object) -> ((repeat each Arg) -> Output)?
) -> _MethodSelector<(repeat each Arg), Output> {
	return ._unchecked(selector)
}

public func _makeMethodSelector<Object, Output>(
	selector: Selector,
	signature: (Object) -> () -> Output
) -> _MethodSelector<Void, Output> {
	return ._unchecked(selector)
}

public func _makeMethodSelector<Object, Arg, Output>(
	selector: Selector,
	signature: (Object) -> (Arg) -> Output
) -> _MethodSelector<(Arg), Output> {
	return ._unchecked(selector)
}

@_disfavoredOverload
public func _makeMethodSelector<Object, each Arg, Output>(
	selector: Selector,
	signature: (Object) -> (repeat each Arg) -> Output
) -> _MethodSelector<(repeat each Arg), Output> {
	return ._unchecked(selector)
}
#endif
