import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroToolkit

/// Macro that converts a regular struct into an ObjectBox entity
/// Adds required ID property, initializers, and Entity protocol conformance
public struct StatefulObjectMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let structDecl = StructDeclSyntax(declaration) else {
            throw MacroError("@StatefulObject can only be applied to structs")
        }
        
        // TODO: Implement ObjectBox entity generation logic
        // This is where you'll add your type filtering and code generation
        
        var members: [DeclSyntax] = []
        
        // Add ID property if missing
        members.append("var id: Id = 0")
        
        // Add default initializer
        members.append("""
            init() {
                self.id = 0
            }
            """)
        
        return members
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        // Add Entity protocol conformance
        let entityExtension = try ExtensionDeclSyntax("extension \(type): Entity {}")
        return [entityExtension]
    }
}

struct MacroError: Error, CustomStringConvertible {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var description: String {
        return message
    }
}

