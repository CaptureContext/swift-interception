import Foundation
import _InterceptionCustomSelectors

// MARK: - PropertySelectors

@freestanding(expression)
public macro propertySelector<Object: NSObject, Value>(
	_: KeyPath<Object, Value>
) -> _ReadonlyPropertySelector<Value> =
#externalMacro(module: "InterceptionMacrosPlugin", type: "PropertySelectorMacro")

@freestanding(expression)
public macro propertySelector<Object: NSObject, Value>(
	_: WritableKeyPath<Object, Value>
) -> _MutablePropertySelector<Value> =
#externalMacro(module: "InterceptionMacrosPlugin", type: "PropertySelectorMacro")

// MARK: - MethodSelectors

@freestanding(expression)
public macro methodSelector<Output>(
	_: (() -> Output)?
) -> _MethodSelector<Void, Output> =
#externalMacro(module: "InterceptionMacrosPlugin", type: "MethodSelectorMacro")

@freestanding(expression)
public macro methodSelector<Arg, Output>(
	_: ((Arg) -> Output)?
) -> _MethodSelector<Arg, Output> =
#externalMacro(module: "InterceptionMacrosPlugin", type: "MethodSelectorMacro")

@freestanding(expression)
public macro methodSelector<each Arg, Output>(
	_: ((repeat each Arg) -> Output)?
) -> _MethodSelector<(repeat each Arg), Output> =
#externalMacro(module: "InterceptionMacrosPlugin", type: "MethodSelectorMacro")

@freestanding(expression)
public macro methodSelector<Object, Output>(
	_: (Object) -> (() -> Output)?
) -> _MethodSelector<Void, Output> =
#externalMacro(module: "InterceptionMacrosPlugin", type: "MethodSelectorMacro")

@freestanding(expression)
public macro methodSelector<Object, Arg, Output>(
	_: (Object) -> ((Arg) -> Output)?
) -> _MethodSelector<Arg, Output> =
#externalMacro(module: "InterceptionMacrosPlugin", type: "MethodSelectorMacro")

@freestanding(expression)
public macro methodSelector<Object, each Arg, Output>(
	_: (Object) -> ((repeat each Arg) -> Output)?
) -> _MethodSelector<(repeat each Arg), Output> =
#externalMacro(module: "InterceptionMacrosPlugin", type: "MethodSelectorMacro")

@freestanding(expression)
public macro methodSelector<Object, Output>(
	_: (Object) -> () -> Output
) -> _MethodSelector<Void, Output> =
#externalMacro(module: "InterceptionMacrosPlugin", type: "MethodSelectorMacro")

@freestanding(expression)
public macro methodSelector<Object, Arg, Output>(
	_: (Object) -> (Arg) -> Output
) -> _MethodSelector<Arg, Output> =
#externalMacro(module: "InterceptionMacrosPlugin", type: "MethodSelectorMacro")

@freestanding(expression)
public macro methodSelector<Object, each Arg, Output>(
	_: (Object) -> (repeat each Arg) -> Output
) -> _MethodSelector<(repeat each Arg), Output> =
#externalMacro(module: "InterceptionMacrosPlugin", type: "MethodSelectorMacro")
