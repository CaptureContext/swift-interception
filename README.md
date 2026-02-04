# swift-interception

[![CI](https://github.com/capturecontext/swift-interception/actions/workflows/ci.yml/badge.svg)](https://github.com/capturecontext/swift-interception/actions/workflows/ci.yml) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcapturecontext%2Fswift-interception%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/capturecontext/swift-interception) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcapturecontext%2Fswift-interception%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/capturecontext/swift-interception)

A Swift package for intercepting Objective-C selector invocations on NSObject instances, enabling observation and transformation of delegate-style APIs.

## Table of contents

- [Motivation](#motivation)
- [Usage](#usage)
  - [Basic](#basic)
  - [Library development](#library-development)
- [Installation](#installation)
- [License](#license)

## Motivation

Several frameworks, including `ReactiveCocoa`, `RxCocoa`, and `CombineCocoa`, use Objective-C selector interception internally to implement delegate proxies and similar abstractions.

This package extracts a generic interception implementation from that approach and makes it available as a standalone dependency. The extracted code has been slightly generalized, supplemented with tests, and extended with a small set of ergonomic helpers for working with selectors.

The result is a small package that provides convenient tools for setting up selector interception without requiring a dependency on a larger framework.

## Usage

### Basic

Observe selectors on NSObject instances

```swift
import Interception

navigationController.setInterceptionHandler(
  for: _makeMethodSelector(
    selector: UINavigationController.popViewController,
    signature: navigationController.popViewController
  )
) { result in 
  print(result.args) // `animated` flag
  print(result.output) // popped `UIViewController?`
}
```

You can also simplify creating method selector with `InterceptionMacros` if you are open for macros

```swift
import InterceptionMacros

navigationController.setInterceptionHandler(
  for: #methodSelector(UINavigationController.popViewController)
) { result in 
  print(result.args) // `animated` flag
  print(result.output) // popped `UIViewController?`
}
```

> Macros require `swift-syntax` compilation, so it will affect cold compilation time

You can set up multiple interception handlers as well, just make sure that you use different keys for each handler

```swift
import Interception

object.setInterceptionHandler(
  for: _makeMethodSelector(
    selector: #selector(MyObject.someMethod(arg1:arg2)),
    signature: MyObject.someMethod(arg1:arg2)
  ),
  key: "argumentsPrinter"
) { result in 
  // In case of multiple arguments
  // you can access them as a tuple
  print(result.args.0)
  print(result.args.1)
}
```

```swift
import InterceptionMacros

object.setInterceptionHandler(
  for: #methodSelector(MyObject.someMethod(arg1:arg2)),
  key: "argumentsPrinter"
) { result in 
  // In case of multiple arguments
  // you can access them as a tuple
  print(result.args.0)
  print(result.args.1)
}
```

### Library development

If you use it to create a library it may be a good idea to export custom selectors implicitly

```swift
// Exports.swift
@_exported import _InterceptionCustomSelectors
```

Also you may find some `@_spi` methods and Utils helpful

```swift
@_spi(Internals) import Interception
import _InterceptionUtils // Is not shown in the autocomplete
```

See [`combine-interception`](https://github.com/capturecontext/combine-interception) for usage example.

## Installation

### Basic

You can add Interception to an Xcode project by adding it as a package dependency.

1. From the **File** menu, select **Swift Packages › Add Package Dependency…**
2. Enter [`"https://github.com/capturecontext/swift-interception.git"`](https://github.com/capturecontext/swift-interception.git) into the package repository URL text field
3. Choose products you need to link them to your project.

### Recommended

If you use SwiftPM for your project, you can add Interception to your package file.

```swift
.package(
  url: "https://github.com/capturecontext/swift-interception.git", 
  .upToNextMinor(from: "0.4.0")
)
```

Do not forget about target dependencies:

```swift
.product(
  name: "Interception", 
  package: "swift-interception"
)
```

```swift
.product(
  name: "InterceptionMacros",
  package: "swift-interception"
)
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

See [ACKNOWLEDGMENTS](ACKNOWLEDGMENTS) for inspiration references and their licences.
