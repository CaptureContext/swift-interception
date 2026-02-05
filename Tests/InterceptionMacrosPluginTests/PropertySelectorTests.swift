import Testing

#if appleOS
import MacroTesting
import InterceptionMacrosPlugin

@Suite(
	.macros(
		["propertySelector": PropertySelectorMacro.self],
		record: .missing // Record only missing snapshots
	)
)
struct PropertySelectorTests {
	@Test
	func main() async throws {
		assertMacro {
			#"""
			#propertySelector(\Object.someProperty)
			"""#
		} expansion: {
			#"""
			_unsafeMakePropertySelector(\Object.someProperty)
			"""#
		}
	}
}
#endif
