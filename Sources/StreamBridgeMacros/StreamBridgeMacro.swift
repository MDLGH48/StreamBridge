import MacroToolkit
import ObjectBox
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Macro that converts a regular struct into an ObjectBox entity
/// Adds required ID property, initializers, and Entity protocol conformance
public struct StatefulObjectGenMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // guard let structDecl: StructDeclSyntax = StructDeclSyntax(declaration) else {
        //     throw MacroError("@StatefulObject can only be applied to structs")
        // }

        // TODO: Implement ObjectBox entity generation logic
        // This is where you'll add your type filtering and code generation

        // var members: [DeclSyntax] = []

        // // Add ID property if missing
        // members.append("var id: Id = 0")

        // // Add default initializer
        // members.append(
        //     """
        //     init() {
        //         self.id = 0
        //     }
        //     """)

        return [DeclSyntax(fromProtocol: declaration)]
    }
}

// public struct MacroError: Error, CustomStringConvertible {
//     let message: String

//     init(_ message: String) {
//         self.message = message
//     }

//     public var description: String {
//         return message
//     }
// }

@main
struct StreamBridgePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StatefulObjectGenMacro.self  // Fixed to match your actual macro
    ]
}
