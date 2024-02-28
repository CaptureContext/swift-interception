import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros
import Foundation

public struct MethodSelectorMacro: ExpressionMacro {
	public static func expansion<
		Node: FreestandingMacroExpansionSyntax,
		Context: MacroExpansionContext
	>(
		of node: Node,
		in context: Context
	) -> ExprSyntax {
		guard let arg = node.argumentList.first.map(\.expression)
		else { fatalError("compiler bug: the macro does not have any arguments") }

		return """
		_makeMethodSelector(
			selector: #selector(\(arg)),
			signature: \(arg)
		)
		"""
	}
}
