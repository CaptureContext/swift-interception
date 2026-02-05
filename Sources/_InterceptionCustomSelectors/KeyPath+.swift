import Foundation

#if canImport(Darwin) && canImport(ObjectiveC)
extension KeyPath {
	public var getterSelector: Selector? {
		guard let property = _kvcKeyPathString else { return nil }
		return Selector(property)
	}
}

extension WritableKeyPath {
	public var setterSelector: Selector? {
		guard let property = _kvcKeyPathString else { return nil }
		return Selector("set" + property.first!.uppercased() + String(property.dropFirst()) + ":")
	}
}
#endif
