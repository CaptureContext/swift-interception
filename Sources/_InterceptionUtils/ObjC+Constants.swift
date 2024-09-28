import Foundation

// Unavailable selectors in Swift.
public enum ObjCSelector {
	public static let forwardInvocation = Selector((("forwardInvocation:")))
	public static let methodSignatureForSelector = Selector((("methodSignatureForSelector:")))
	public static let getClass = Selector((("class")))
}

// Method encoding of the unavailable selectors.
public enum ObjCMethodEncoding {
	nonisolated(unsafe)
	public static let forwardInvocation = extract("v@:@")

	nonisolated(unsafe)
	public static let methodSignatureForSelector = extract("v@::")

	nonisolated(unsafe)
	public static let getClass = extract("#@:")

	private static func extract(_ string: StaticString) -> UnsafePointer<CChar> {
		return UnsafeRawPointer(string.utf8Start).assumingMemoryBound(to: CChar.self)
	}
}

/// Objective-C type encoding.
///
/// The enum does not cover all options, but only those that are expressive in
/// Swift.
public enum ObjCTypeEncoding: Int8 {
	case char = 99
	case int = 105
	case short = 115
	case long = 108
	case longLong = 113
	
	case unsignedChar = 67
	case unsignedInt = 73
	case unsignedShort = 83
	case unsignedLong = 76
	case unsignedLongLong = 81
	
	case float = 102
	case double = 100
	
	case bool = 66
	
	case object = 64
	case type = 35
	case selector = 58

	case void = 118
	case undefined = -1
}
