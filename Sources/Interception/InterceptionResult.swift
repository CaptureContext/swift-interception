public struct InterceptionResult<Args, Output> {
	public var args: Args
	public var output: Output

	@_spi(Internals)
	public init(args: Args, output: Output) {
		self.args = args
		self.output = output
	}
}

extension InterceptionResult where Args == Any, Output == Any {
	@_spi(Internals)
	public func unsafeCast<NewArgs, NewOutput>(
		args: NewArgs.Type = NewArgs.self,
		output: NewOutput.Type = NewOutput.self
	) -> InterceptionResult<NewArgs, NewOutput> {
		return .init(
			args: self.args as! NewArgs,
			output: self.output as! NewOutput
		)
	}
}
