import Foundation
import Runtime

// MARK: - ObjectBuilder Protocol
protocol ObjectBuilderProtocol {
    associatedtype ResultType

    func handleSimple(type: Any.Type, key: String, keyPath: String) -> Any
    func handleArray(signature: ArraySignature, key: String, keyPath: String) -> Any
    func handleOptional(signature: OptionalSignature, key: String, keyPath: String) -> Any
    func handleObject(signature: ObjectSignature, key: String, keyPath: String) -> Any
    func finalize(state: [String: Any]) -> ResultType
}

// MARK: - ObjectBuilder Class
class ObjectBuilder<Builder: ObjectBuilderProtocol> {
    public let builder: Builder
    public let signature: ObjectSignature
    public let keyPath: String
    public let include: Set<String>
    var state: [String: Any] = [:]

    init(
        builder: Builder,
        signature: ObjectSignature,
        keyPath: String = "",
        include: [String] = []
    ) {
        self.builder = builder
        self.signature = signature
        self.keyPath = keyPath
        self.include = include.isEmpty ? Set(getAllKeyPaths(from: signature)) : Set(include)
    }

    func transform() -> Builder.ResultType {
        buildProperties()
        return builder.finalize(state: state)
    }

    private func buildProperties() {
        for (propertyName, propertyType) in signature.properties {
            let fullKeyPath = keyPath.isEmpty ? propertyName : "\(keyPath).\(propertyName)"

            if include.contains(fullKeyPath) {
                let result = buildPropertyType(
                    propertyType, key: propertyName, keyPath: fullKeyPath)
                state[propertyName] = result
            }
        }
    }

    private func buildPropertyType(_ propertyType: PropertyType, key: String, keyPath: String)
        -> Any
    {
        return propertyType.visit(
            onSimple: { type in
                builder.handleSimple(type: type, key: key, keyPath: keyPath)
            },
            onArray: { arraySignature in
                builder.handleArray(signature: arraySignature, key: key, keyPath: keyPath)
            },
            onOptional: { optionalSignature in
                builder.handleOptional(signature: optionalSignature, key: key, keyPath: keyPath)
            },
            onObject: { objectSignature in
                builder.handleObject(signature: objectSignature, key: key, keyPath: keyPath)
            }
        )
    }
}

// MARK: - Helper Functions
func getAllKeyPaths(from signature: ObjectSignature, prefix: String = "") -> [String] {
    var keyPaths: [String] = []

    for (propertyName, propertyType) in signature.properties {
        let currentPath = prefix.isEmpty ? propertyName : "\(prefix).\(propertyName)"
        keyPaths.append(currentPath)

        // Add nested paths
        _ = propertyType.visit(
            onSimple: { _ in /* no nested paths */ },
            onArray: { arraySignature in
                _ = arraySignature.elementType.visit(
                    onSimple: { _ in },
                    onArray: { _ in },
                    onOptional: { _ in },
                    onObject: { elementObjectSignature in
                        let arrayPath = "\(currentPath)[]"
                        keyPaths.append(
                            contentsOf: getAllKeyPaths(
                                from: elementObjectSignature, prefix: arrayPath))
                    }
                )
            },
            onOptional: { optionalSignature in
                _ = optionalSignature.wrappedType.visit(
                    onSimple: { _ in },
                    onArray: { _ in },
                    onOptional: { _ in },
                    onObject: { optionalObjectSignature in
                        keyPaths.append(
                            contentsOf: getAllKeyPaths(
                                from: optionalObjectSignature, prefix: currentPath))
                    }
                )
            },
            onObject: { objectSignature in
                keyPaths.append(
                    contentsOf: getAllKeyPaths(from: objectSignature, prefix: currentPath))
            }
        )
    }

    return keyPaths
}

// MARK: - Example Builders

/// Dictionary Builder - builds a nested dictionary structure
struct DictionaryBuilder: ObjectBuilderProtocol {
    typealias ResultType = [String: Any]

    func handleSimple(type: Any.Type, key: String, keyPath: String) -> Any {
        return String(describing: type)
    }

    func handleArray(signature: ArraySignature, key: String, keyPath: String) -> Any {
        let elementDescription = signature.elementType.visit(
            onSimple: { type in String(describing: type) },
            onArray: { _ in "Array" },
            onOptional: { _ in "Optional" },
            onObject: { objSig in objSig.name }
        )
        return ["type": "Array", "element": elementDescription]
    }

    func handleOptional(signature: OptionalSignature, key: String, keyPath: String) -> Any {
        let wrappedDescription = signature.wrappedType.visit(
            onSimple: { type in String(describing: type) },
            onArray: { _ in "Array" },
            onOptional: { _ in "Optional" },
            onObject: { objSig in objSig.name }
        )
        return ["type": "Optional", "wrapped": wrappedDescription]
    }

    func handleObject(signature: ObjectSignature, key: String, keyPath: String) -> Any {
        // Create nested builder for this object
        let nestedBuilder = ObjectBuilder(
            builder: self,
            signature: signature,
            keyPath: keyPath
        )
        return nestedBuilder.transform()
    }

    func finalize(state: [String: Any]) -> [String: Any] {
        return state
    }
}

/// Type Registry Builder - builds a map of property paths to types
struct TypeRegistryBuilder: ObjectBuilderProtocol {
    typealias ResultType = [String: Any.Type]

    func handleSimple(type: Any.Type, key: String, keyPath: String) -> Any {
        return type
    }

    func handleArray(signature: ArraySignature, key: String, keyPath: String) -> Any {
        return signature.elementType.visit(
            onSimple: { elementType in Array<Any>.self },  // Could be more specific
            onArray: { _ in Array<[Any]>.self },
            onOptional: { _ in Array<Any?>.self },
            onObject: { _ in Array<Any>.self }
        )
    }

    func handleOptional(signature: OptionalSignature, key: String, keyPath: String) -> Any {
        return signature.wrappedType.visit(
            onSimple: { wrappedType in wrappedType },
            onArray: { _ in [Any]?.self },
            onOptional: { _ in Any??.self },
            onObject: { _ in Any?.self }
        )
    }

    func handleObject(signature: ObjectSignature, key: String, keyPath: String) -> Any {
        // For objects, just return a generic type or create nested registry
        
        let nestedObjectBuilder = ObjectBuilder(
            builder: TypeRegistryBuilder(),
            signature: signature,
            keyPath: keyPath
         
        )
        let nestedTransformed: TypeRegistryBuilder.ResultType = nestedObjectBuilder.transform()
        return nestedTransformed
    }

    func finalize(state: [String: Any]) -> [String: Any.Type] {
        return state.compactMapValues { $0 as? Any.Type }
    }
}

/// JSON Schema Builder - builds JSON schema representation
struct JSONSchemaBuilder: ObjectBuilderProtocol {
    typealias ResultType = [String: Any]

    func handleSimple(type: Any.Type, key: String, keyPath: String) -> Any {
        switch type {
        case is String.Type:
            return ["type": "string"]
        case is Int.Type, is Int8.Type, is Int16.Type, is Int32.Type, is Int64.Type,
            is UInt.Type, is UInt8.Type, is UInt16.Type, is UInt32.Type, is UInt64.Type:
            return ["type": "integer"]
        case is Bool.Type:
            return ["type": "boolean"]
        case is Double.Type, is Float.Type:
            return ["type": "number"]
        default:
            return ["type": "string", "format": String(describing: type)]
        }
    }

    func handleArray(signature: ArraySignature, key: String, keyPath: String) -> Any {
        let itemSchema = signature.elementType.visit(
            onSimple: { type in handleSimple(type: type, key: "item", keyPath: "\(keyPath)[]") },
            onArray: { arraySig in
                handleArray(signature: arraySig, key: "item", keyPath: "\(keyPath)[]")
            },
            onOptional: { optSig in
                handleOptional(signature: optSig, key: "item", keyPath: "\(keyPath)[]")
            },
            onObject: { objSig in
                handleObject(signature: objSig, key: "item", keyPath: "\(keyPath)[]")
            }
        )
        return ["type": "array", "items": itemSchema]
    }

    func handleOptional(signature: OptionalSignature, key: String, keyPath: String) -> Any {
        return signature.wrappedType.visit(
            onSimple: { type in
                var schema = handleSimple(type: type, key: key, keyPath: keyPath) as! [String: Any]
                schema["nullable"] = true
                return schema
            },
            onArray: { arraySig in
                var schema =
                    handleArray(signature: arraySig, key: key, keyPath: keyPath) as! [String: Any]
                schema["nullable"] = true
                return schema
            },
            onOptional: { optSig in handleOptional(signature: optSig, key: key, keyPath: keyPath) },
            onObject: { objSig in
                var schema =
                    handleObject(signature: objSig, key: key, keyPath: keyPath) as! [String: Any]
                schema["nullable"] = true
                return schema
            }
        )
    }

    func handleObject(signature: ObjectSignature, key: String, keyPath: String) -> Any {
        let nestedBuilder = ObjectBuilder(
            builder: JSONSchemaBuilder(),
            signature: signature,
            keyPath: keyPath
        )
        let properties = nestedBuilder.transform()
        return [
            "type": "object",
            "properties": properties,
        ]
    }

    func finalize(state: [String: Any]) -> [String: Any] {
        return [
            "type": "object",
            "properties": state,
        ]
    }
}
