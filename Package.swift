// swift-tools-version: 5.9
import PackageDescription

let package = Package(
	name: "swift-interception",
	products: [
		.library(
			name: "_InterceptionCustomSelectors",
			type: .static,
			targets: ["_InterceptionCustomSelectors"]
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
		)
	],
	targets: [
		.target(name: "_InterceptionCustomSelectors"),
		.target(name: "_InterceptionUtilsObjc"),
		.target(
			name: "_InterceptionUtils",
			dependencies: [
				.target(name: "_InterceptionUtilsObjc"),
			]
		),
		.target(
			name: "Interception",
			dependencies: [
				.target(name: "_InterceptionCustomSelectors"),
				.target(name: "_InterceptionUtils"),
			]
		),
		.testTarget(
			name: "InterceptionTests",
			dependencies: [
				.target(name: "Interception"),
			]
		),
	]
)
