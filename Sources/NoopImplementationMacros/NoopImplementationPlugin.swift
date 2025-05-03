import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct NoopImplementationPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        NoopImplementationMacro.self, // このマクロを提供する
    ]
}
