import XCTest
import MacroTesting
import InterceptionMacrosPlugin

final class PropertySelectorTests: XCTestCase {
	override func invokeTest() {
		withMacroTesting(
			record: false,
			macros: [
				"propertySelector": PropertySelectorMacro.self
			]
		) {
			super.invokeTest()
		}
	}

	func testApplication() {
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
