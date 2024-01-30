# swift-interception

[![SwiftPM 5.9](https://img.shields.io/badge/swiftpm-5.9-ED523F.svg?style=flat)](https://swift.org/download/) ![Platforms](https://img.shields.io/badge/Platforms-iOS_|_macOS_|_Catalyst_|_tvOS_|_watchOS-ED523F.svg?style=flat) [![@capturecontext](https://img.shields.io/badge/contact-@capturecontext-1DA1F2.svg?style=flat&logo=twitter)](https://twitter.com/capture_context) 

Package for interception of objc selectors in Swift.

Macros: [`swift-interception-macros`](https://github.com/capturecontext/swift-interception-macros)

## Usage

### Basic

Observe any selectors on NSObject instances

```swift
import Interception

navigationController.setInterceptionHandler(
  for: _makeMethodSelector(
    selector: UINavigationController.popViewController,
    signature: UINavigationController.popViewController
  )
) { result in 
  print(result.args) // `animated` flag
  print(result.output) // popped `UIViewController?``
}
```

You can set up multiple interception handlers as well, just make sure that you use different keys for each handler

```swift
import Intercexption

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

<!--- See [`combine-interception`](https://github.com/capturecontext/combine-interception) for usage example. --->

## Installation

### Basic

You can add CombineInterception to an Xcode project by adding it as a package dependency.

1. From the **File** menu, select **Swift Packages › Add Package Dependency…**
2. Enter [`"https://github.com/capturecontext/swift-interception.git"`](https://github.com/capturecontext/swift-interception.git) into the package repository URL text field
3. Choose products you need to link them to your project.

### Recommended

If you use SwiftPM for your project, you can add CombineInterception to your package file.

```swift
.package(
  url: "https://github.com/capturecontext/swift-interception.git", 
  .upToNextMinor(from: "0.1.0")
)
```

Do not forget about target dependencies:

```swift
.product(
  name: "Interception", 
  package: "swift-interception"
)
```

## License

This library is released under the MIT license. See [LICENCE](LICENCE) for details.

See [ACKNOWLEDGMENTS](ACKNOWLEDGMENTS) for inspiration references and their licences.
