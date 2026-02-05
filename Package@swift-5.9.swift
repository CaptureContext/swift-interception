// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let applePlatforms: [Platform] = [
	.iOS,
	.macOS,
	.macCatalyst,
	.watchOS,
	.tvOS,
	.visionOS
]

let package = Package(
	name: "swift-interception",
	platforms: [
		.iOS(.v13),
		.macOS(.v10_15),
		.tvOS(.v13),
		.macCatalyst(.v13),
		.watchOS(.v6),
	],
	products: [
		.library(
			name: "_InterceptionCustomSelectors",
			type: .static,
			targets: ["_InterceptionCustomSelectors"]
		),
		.library(
			name: "_InterceptionMacros",
			type: .static,
			targets: ["_InterceptionMacros"]
		),
		.library(
			name: "_InterceptionUtils",
			type: .static,
			targets: ["_InterceptionUtils"]
		),
		.library(
			name: "Interception",
			type: .static,
			targets: ["Interception"]
		),
		.library(
			name: "InterceptionMacros",
			type: .static,
			targets: ["InterceptionMacros"]
		),
	],
	dependencies: [
		.package(
			url: "https://github.com/stackotter/swift-macro-toolkit.git",
			"0.5.0"..<"0.9.0",
		),
		.package(
			url: "https://github.com/pointfreeco/swift-macro-testing.git",
			.upToNextMinor(from: "0.6.0")
		)
	],
	targets: [
		.target(
			name: "_InterceptionMacros",
			dependencies: [
				.target(name: "InterceptionMacrosPlugin"),
				.target(name: "_InterceptionCustomSelectors")
			]
		),
		.target(name: "_InterceptionCustomSelectors"),
		.target(
			name: "_InterceptionUtils",
			dependencies: [
				.target(
					name: "_InterceptionUtilsObjc",
					condition: .when(platforms: applePlatforms)
				),
			]
		),
		.target(name: "_InterceptionUtilsObjc"),
		.target(
			name: "Interception",
			dependencies: [
				.target(name: "_InterceptionCustomSelectors"),
				.target(name: "_InterceptionUtils"),
			]
		),
		.target(
			name: "InterceptionMacros",
			dependencies: [
				.target(name: "_InterceptionMacros"),
				.target(name: "Interception")
			]
		),
		.macro(
			name: "InterceptionMacrosPlugin",
			dependencies: [
				.product(
					name: "MacroToolkit",
					package: "swift-macro-toolkit"
				)
			]
		),
		.testTarget(
			name: "InterceptionMacrosPluginTests",
			dependencies: [
				.target(name: "InterceptionMacrosPlugin"),
				.product(name: "MacroTesting", package: "swift-macro-testing"),
			]
		),
		.testTarget(
			name: "InterceptionTests",
			dependencies: [
				.target(name: "Interception"),
			]
		),
		.testTarget(
			name: "InterceptionMacrosTests",
			dependencies: [
				.target(name: "InterceptionMacros"),
			]
		),
	]
)
