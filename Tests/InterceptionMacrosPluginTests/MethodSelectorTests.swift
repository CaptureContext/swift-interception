import Testing

#if appleOS
import MacroTesting
import InterceptionMacrosPlugin

@Suite(
	.macros(
		["methodSelector": MethodSelectorMacro.self],
		record: .missing
	)
)
struct MethodSelectorTests {
	@Test
	func main() async throws {
		assertMacro {
			"""
			#methodSelector(Object.someFunc)
			"""
		} expansion: {
			"""
			_makeMethodSelector(
				selector: #selector(Object.someFunc),
				signature: Object.someFunc
			)
			"""
		}
	}
}
#endif
