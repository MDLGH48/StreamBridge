
import SwiftCompilerPlugin
import SwiftSyntaxMacros
@main
struct MacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StatefulObjectMacro.self, // Fixed to match your actual macro
    ]
}