import Foundation
import Runtime

/// A protocol to represent a "union" of simple types that can be persisted.
/// Swift doesn't have a direct equivalent of a union type alias, but a protocol
/// can be used to group types together for type checking.
public protocol Serializable {}

extension Bool: Serializable {}
extension Float: Serializable {}
extension Double: Serializable {}
extension Data: Serializable {}
extension String: Serializable {}
extension Date: Serializable {}
extension Int: Serializable {}
extension Int8: Serializable {}
extension Int16: Serializable {}
extension Int32: Serializable {}
extension Int64: Serializable {}
extension UInt: Serializable {}
extension UInt8: Serializable {}
extension UInt16: Serializable {}
extension UInt32: Serializable {}
extension UInt64: Serializable {}

public struct SimpleType {
    public static func check(_ type: Any.Type) -> Bool {
        return type is Serializable.Type
    }
    public static func check(_ typeName: String) -> Bool {
        guard let type: any Any.Type = SimpleType.fromString(typeName) else {
            return false
        }
        return type is Serializable.Type
    }
    public static func fromString(_ typeName: String) -> Serializable.Type? {
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
}

enum FieldType {
    case simple
    case array
    case object
}

enum ContainerType {
    case simple(Any.Type)
    case object(TypeInfo)
}

extension PropertyInfo {
    var fieldInfo: TypeInfo? {
        do {

            return try typeInfo(of: self.type)
        } catch {
            return nil
        }

    }

}

extension TypeInfo {
    var containerArgs: ContainerType? {
        if self.genericTypes.count == 1 {
            let genericType = self.genericTypes[0]
            if SimpleType.check(genericType) {
                return ContainerType.simple(genericType)
            } else {
                do {
                    let tinfo = try typeInfo(of: genericType)
                    if tinfo.fieldType == FieldType.object {
                        return ContainerType.object(tinfo)
                    }
                } catch {
                    return nil
                }
            }
        }
        return nil
    }

    var fieldType: FieldType? {
        if SimpleType.check(self.type) {
            return FieldType.simple
        }
        if self.name.hasPrefix("Array<") {
            return FieldType.array
        } else {
            if (self.kind == Kind.class) || (self.kind == Kind.struct) {
                return FieldType.object
            } else {
                return nil
            }
        }
    }

    var isOptional: Bool {
        switch self.kind {
        case .optional:
            return true
        default:
            return false
        }
    }

}

public struct SimpleAnnotation {
    public let type: any Serializable.Type
}

public struct ObjectAnnotation {
    var name: String
    var fields: Attributes

    public static func build(_ target: Any.Type) -> ObjectAnnotation {
        let typeDefinition: TypeInfo = try! typeInfo(of: target)
        var objectDef: ObjectAnnotation = ObjectAnnotation(name: typeDefinition.name, fields: [:])
        for propInfo: PropertyInfo in typeDefinition.properties {
            let fieldName: String = propInfo.name
            guard let attribute: AttributeType = AttributeType(rawValue: propInfo) else {
                continue
            }
            objectDef.fields[fieldName] = attribute
        }
        return objectDef
    }
}

public struct SimpleArrayAnnotation {
    var type: any Serializable.Type
}

public struct RecordArrayAnnotation {
    var object: ObjectAnnotation
}

typealias Attributes = [String: AttributeType]

public enum AttributeType {
    case simpleAtt(SimpleAnnotation)
    case objectAtt(ObjectAnnotation)
    case simpleArrayAtt(SimpleArrayAnnotation)
    case recordArrayAtt(RecordArrayAnnotation)

    init?(rawValue: PropertyInfo) {
        let fieldInfo: TypeInfo? = rawValue.fieldInfo
        let fieldType = fieldInfo?.fieldType
        switch fieldType {
        case .simple:
            let typeVal = SimpleType.fromString(fieldInfo?.name as! String)
            self = .simpleAtt(SimpleAnnotation(type: typeVal!))
        case .array:
            if let containerArgs = fieldInfo?.containerArgs {
                switch containerArgs {
                case .simple(let simpleType):
                    self = .simpleArrayAtt(
                        SimpleArrayAnnotation(type: simpleType as! Serializable.Type))
                case .object(let objectType):
                    self = .recordArrayAtt(
                        RecordArrayAnnotation(object: ObjectAnnotation.build(objectType.type)))
                }
            } else {
                return nil
            }
        case .object:
            self = .objectAtt(ObjectAnnotation.build(fieldInfo!.type))
        default:
            return nil
        }
    }
}
public func unWrapAnn(_ att: AttributeType) -> Any {
    switch att {
    case .simpleAtt(let simpleAnn):
        return simpleAnn
    case .objectAtt(let objectAnn):
        return objectAnn
    case .simpleArrayAtt(let simpleArrAnn):
        return simpleArrAnn
    case .recordArrayAtt(let recordArrayAnn):
        return recordArrayAnn
    }
}

extension String {
    func toType<T>() -> T.Type? {
        let t: Any.Type? = SimpleType.fromString(self)
        return t as? T.Type
    }

}
