import Foundation
import ObjectBox

public enum ObjectBoxTypeMapper {
    case string, long, int, short, byte, float, double, bool, date, byteVector
    
    public var propertyType: PropertyType {
        switch self {
        case .string: return .string
        case .long: return .long
        case .int: return .int
        case .short: return .short
        case .byte: return .byte
        case .float: return .float
        case .double: return .double
        case .bool: return .bool
        case .date: return .date
        case .byteVector: return .byteVector
        }
    }
    
    public static func from(_ type: any Serializable.Type) -> ObjectBoxTypeMapper {
        switch type {
        case is String.Type: return .string
        case is Int.Type, is Int64.Type, is UInt.Type, is UInt64.Type: return .long
        case is Int32.Type, is UInt32.Type: return .int
        case is Int16.Type, is UInt16.Type: return .short
        case is Int8.Type, is UInt8.Type: return .byte
        case is Float.Type: return .float
        case is Double.Type: return .double
        case is Bool.Type: return .bool
        case is Date.Type: return .date
        case is Data.Type: return .byteVector
        default: return .byteVector
        }
    }
}

// Drop-in replacement
public func toOboxType(_ type: any Serializable.Type) -> PropertyType {
    return ObjectBoxTypeMapper.from(type).propertyType
}