import Foundation
import Runtime

struct Annotation {
    let definition: Any
    let cls: PropertyType
}
// Define the struct types for the signature
struct PropertySignature {
    let name: String
    let type: PropertyType
}

indirect enum PropertyType {
    case simple(Any.Type)
    case array(ArraySignature)
    case optional(OptionalSignature)
    case object(ObjectSignature)
}

struct ArraySignature {
    let elementType: PropertyType
}

struct OptionalSignature {
    let wrappedType: PropertyType
}

struct ObjectSignature {
    let name: String
    let properties: [String: PropertyType]

    var typedDict: [String: Annotation] {
        var typedDictProps: [String: Annotation] = [:]

        for prop: (key: String, value: PropertyType) in properties {
            let ann = getAnnotation(propType: prop.value)
            if ann != nil {
                typedDictProps[prop.key] = ann
            }

        }
        return typedDictProps
    }
    func getAnnotation(propType: PropertyType) -> Annotation? {

        if propType.isSimple {
            let definition: (any Any.Type)? = StructureInspector.getTypeFromString(
                propType.simpleTypeName!)

            return Annotation(
                definition: definition!,
                cls: propType)

        } else if propType.isArray {
            let ptype: PropertyType? = propType.arraySignature?.elementType
            return Annotation(
                definition: self.getAnnotation(propType: ptype!)!,
                cls: propType)

        } else if propType.isObject {
            let ptype: [String: Annotation]? = propType.objectSignature?.typedDict
            return Annotation(
                definition: ptype!,
                cls: propType)

        } else if propType.isOptional {
            let ptype: PropertyType? = propType.optionalSignature?.wrappedType
            return Annotation(
                definition: self.getAnnotation(propType: ptype!)!,
                cls: propType)
        } else {
            return nil
        }

    }
}

// Make PropertyType conform to common protocols for easier handling
extension PropertyType: CustomStringConvertible {
    var description: String {
        switch self {
        case .simple(let type):
            return String(describing: type)
        case .array(let arraySignature):
            return "[\(arraySignature.elementType)]"
        case .optional(let optionalSignature):
            return "\(optionalSignature.wrappedType)?"
        case .object(let objectSignature):
            return "Object with \(objectSignature.properties.count) properties"
        }
    }
}

class StructureInspector {
    public let sig: ObjectSignature
    public init<T>(target: T.Type) throws {
        let sig: ObjectSignature = try StructureInspector.createSignature(for: target)
        self.sig = sig
    }

    // Main function to create a signature from any type
    static func createSignature<T>(for type: T.Type) throws -> ObjectSignature {
        let typeInfo = try Runtime.typeInfo(of: type)
        let properties = try extractProperties(from: typeInfo)
        return ObjectSignature(name: typeInfo.name, properties: properties)
    }

    // Extract properties and their types
    private static func extractProperties(from typeInfo: TypeInfo) throws -> [String: PropertyType]
    {
        var properties: [String: PropertyType] = [:]

        for property in typeInfo.properties {
            let propertyType = try createPropertyType(for: property)
            properties[property.name] = propertyType
        }

        return properties
    }

    // Create the appropriate PropertyType for each property
    private static func createPropertyType(for property: PropertyInfo) throws -> PropertyType {

        // For simple types, return simple type
        if isSimpleType(property.type) {
            return .simple(property.type)
        }

        // For arrays, handle element types
        if let arrayElementType = getArrayElementType(property.type) {
            let elementPropertyType = try createPropertyTypeFromType(arrayElementType)
            return .array(ArraySignature(elementType: elementPropertyType))
        }

        // For optionals, handle wrapped types
        if let optionalWrappedType = getOptionalWrappedType(property.type) {
            let wrappedPropertyType = try createPropertyTypeFromType(optionalWrappedType)
            return .optional(OptionalSignature(wrappedType: wrappedPropertyType))
        }

        // For structs/classes, recursively create nested objects
        if isStructOrClass(property.type) {
            let nestedTypeInfo = try Runtime.typeInfo(of: property.type)
            let nestedProperties = try extractProperties(from: nestedTypeInfo)
            return .object(ObjectSignature(name: nestedTypeInfo.name, properties: nestedProperties))
        }

        // For other complex types, return as simple type
        return .simple(property.type)
    }

    // Helper to create PropertyType from Any.Type
    private static func createPropertyTypeFromType(_ type: Any.Type) throws -> PropertyType {
        if isSimpleType(type) {
            return .simple(type)
        } else if let arrayElementType = getArrayElementType(type) {
            let elementPropertyType = try createPropertyTypeFromType(arrayElementType)
            return .array(ArraySignature(elementType: elementPropertyType))
        } else if let optionalWrappedType = getOptionalWrappedType(type) {
            let wrappedPropertyType = try createPropertyTypeFromType(optionalWrappedType)
            return .optional(OptionalSignature(wrappedType: wrappedPropertyType))
        } else if isStructOrClass(type) {
            let typeInfo = try Runtime.typeInfo(of: type)
            let properties = try extractProperties(from: typeInfo)
            return .object(ObjectSignature(name: typeInfo.name, properties: properties))
        } else {
            return .simple(type)
        }
    }

    // Extract element type from Array
    private static func getArrayElementType(_ type: Any.Type) -> Any.Type? {
        let typeString = String(describing: type)

        // Handle Array<T> format
        if typeString.hasPrefix("Array<") && typeString.hasSuffix(">") {
            let elementTypeName = String(typeString.dropFirst(6).dropLast(1))
            return getTypeFromString(elementTypeName)
        }

        // Handle [T] format
        if typeString.hasPrefix("[") && typeString.hasSuffix("]") {
            let elementTypeName = String(typeString.dropFirst(1).dropLast(1))
            return getTypeFromString(elementTypeName)
        }

        return nil
    }

    // Extract wrapped type from Optional
    private static func getOptionalWrappedType(_ type: Any.Type) -> Any.Type? {
        let typeString = String(describing: type)

        if typeString.hasPrefix("Optional<") && typeString.hasSuffix(">") {
            let wrappedTypeName = String(typeString.dropFirst(9).dropLast(1))
            return getTypeFromString(wrappedTypeName)
        }

        return nil
    }

    // Helper to get Type from string name
    public static func getTypeFromString(_ typeName: String) -> Any.Type? {
        switch typeName {
        case "Bool": return Bool.self
        case "Float": return Float.self
        case "Double": return Double.self
        case "Data": return Data.self
        case "String": return String.self
        case "Date": return Date.self
        case "Int": return Int.self
        case "Int8": return Int8.self
        case "Int16": return Int16.self
        case "Int32": return Int32.self
        case "Int64": return Int64.self
        case "UInt": return UInt.self
        case "UInt8": return UInt8.self
        case "UInt16": return UInt16.self
        case "UInt32": return UInt32.self
        case "UInt64": return UInt64.self
        default: return nil
        }
    }

    // Check if type is a simple/primitive type
    private static func isSimpleType(_ type: Any.Type) -> Bool {
        return type == Int.self || type == String.self || type == Bool.self || type == Double.self
            || type == Float.self || type == Int32.self || type == Int64.self || type == UInt.self
            || type == UInt32.self || type == UInt64.self
            || type == Int8.self || type == Int16.self || type == UInt8.self || type == UInt16.self
            || type == Data.self || type == Date.self
    }

    // Check if type is a struct or class
    private static func isStructOrClass(_ type: Any.Type) -> Bool {
        do {
            let typeInfo = try Runtime.typeInfo(of: type)
            return typeInfo.kind == .struct || typeInfo.kind == .class
        } catch {
            return false
        }
    }

    // Get clean Swift type name
    private static func getSwiftTypeName(_ type: Any.Type) -> String {
        let fullName = String(describing: type)

        if fullName.contains(".") {
            return String(fullName.split(separator: ".").last ?? "Unknown")
        }
        return fullName
    }
}

// Extension for easier access and manipulation
extension ObjectSignature {

    // Get a property by name
    func getProperty(_ name: String) -> PropertyType? {
        return properties[name]
    }

    // Check if property exists
    func hasProperty(_ name: String) -> Bool {
        return properties[name] != nil
    }

    // Get all property names
    var propertyNames: [String] {
        return Array(properties.keys)
    }

    // Get simple properties only
    var simpleProperties: [String: Any.Type] {
        return properties.compactMapValues { propertyType in
            if case .simple(let type) = propertyType {
                return type
            }
            return nil
        }
    }

    // Get array properties only
    var arrayProperties: [String: ArraySignature] {
        return properties.compactMapValues { propertyType in
            if case .array(let arraySignature) = propertyType {
                return arraySignature
            }
            return nil
        }
    }

    // Get optional properties only
    var optionalProperties: [String: OptionalSignature] {
        return properties.compactMapValues { propertyType in
            if case .optional(let optionalSignature) = propertyType {
                return optionalSignature
            }
            return nil
        }
    }

    // Get nested object properties only
    var objectProperties: [String: ObjectSignature] {
        return properties.compactMapValues { propertyType in
            if case .object(let objectSignature) = propertyType {
                return objectSignature
            }
            return nil
        }
    }
}

// Helper functions for PropertyType
extension PropertyType {

    var isSimple: Bool {
        if case .simple = self { return true }
        return false
    }

    var isArray: Bool {
        if case .array = self { return true }
        return false
    }

    var isOptional: Bool {
        if case .optional = self { return true }
        return false
    }

    var isObject: Bool {
        if case .object = self { return true }
        return false
    }

    // Get the simple type if it's a simple type
    var simpleType: Any.Type? {
        if case .simple(let type) = self {
            return type
        }
        return nil
    }

    // Get the simple type name if it's a simple type
    var simpleTypeName: String? {
        if case .simple(let type) = self {
            return String(describing: type)
        }
        return nil
    }

    // Get the array signature if it's an array
    var arraySignature: ArraySignature? {
        if case .array(let signature) = self {
            return signature
        }
        return nil
    }

    // Get the optional signature if it's optional
    var optionalSignature: OptionalSignature? {
        if case .optional(let signature) = self {
            return signature
        }
        return nil
    }

    // Get the object signature if it's an object
    var objectSignature: ObjectSignature? {
        if case .object(let signature) = self {
            return signature
        }
        return nil
    }
}

extension PropertyType {
    func visit<T>(
        onSimple: (Any.Type) -> T,
        onArray: (ArraySignature) -> T,
        onOptional: (OptionalSignature) -> T,
        onObject: (ObjectSignature) -> T
    ) -> T {
        switch self {
        case .simple(let type):
            return onSimple(type)
        case .array(let arraySignature):
            return onArray(arraySignature)
        case .optional(let optionalSignature):
            return onOptional(optionalSignature)
        case .object(let objectSignature):
            return onObject(objectSignature)
        }
    }
}
