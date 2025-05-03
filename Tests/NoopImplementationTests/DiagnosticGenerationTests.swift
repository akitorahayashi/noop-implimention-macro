import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(NoopImplementationMacros)
    import NoopImplementationMacros
#endif

final class NIDiagnosticGenerationTests: XCTestCase {
    var testMacros: [String: Macro.Type] = [:]

    override func setUp() {
        #if canImport(NoopImplementationMacros)
            testMacros = [
                "NoopImplementation": NoopImplementationMacro.self,
            ]
        #endif
    }

    func test_AppliedToStruct_GeneratesErrorDiagnostic() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                @NoopImplementation
                struct NotAProtocol {}
                """,
                expandedSource: """
                struct NotAProtocol {}
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@NoopImplementation はプロトコルにのみ適用できます。",
                        line: 1,
                        column: 1,
                        severity: .error
                    ),
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    func test_AppliedToClass_GeneratesErrorDiagnostic() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                @NoopImplementation
                class NotAProtocol {}
                """,
                expandedSource: """
                class NotAProtocol {}
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@NoopImplementation はプロトコルにのみ適用できます。",
                        line: 1,
                        column: 1,
                        severity: .error
                    ),
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    func test_UnresolvableTypeInThrowsFunc_GeneratesThrowNoopErrorWithoutDiagnostic() {
        assertMacroExpansion(
            """
            struct Uninitializable {}
            @NoopImplementation
            protocol Unresolvable {
                func getValue() throws -> Uninitializable
            }
            """,
            expandedSource: """
            struct Uninitializable {}
            protocol Unresolvable {
                func getValue() throws -> Uninitializable
            }

            internal final class NoopUnresolvable: Unresolvable {
                internal func getValue() throws -> Uninitializable {throw NoopError.defaultValueUnavailable(typeName: "Uninitializable")
                }
                internal init() {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "型 'Uninitializable' のデフォルト値を決定できませんでした。 fatalError が挿入されます。'overrides' 引数でカスタムデフォルトを指定するか、型がパラメータなしイニシャライザを持つことを確認してください。",
                    line: 4,
                    column: 31,
                    severity: .warning
                ),
            ],
            macros: testMacros
        )
    }

    func test_UnresolvableTypeInNonThrowsFunc_GeneratesFatalErrorAndWarningDiagnostic() {
        assertMacroExpansion(
            """
            struct Uninitializable {}
            @NoopImplementation
            protocol UnresolvableNonThrow {
                func getValue() -> Uninitializable // throws しない
            }
            """,
            expandedSource: """
            struct Uninitializable {}
            protocol UnresolvableNonThrow {
                func getValue() -> Uninitializable // throws しない
            }

            internal final class NoopUnresolvableNonThrow: UnresolvableNonThrow {
                internal func getValue() -> Uninitializable {
                    fatalError("Cannot generate default value for type 'Uninitializable'")
                }
                internal init() {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "型 'Uninitializable' のデフォルト値を決定できませんでした。 fatalError が挿入されます。'overrides' 引数でカスタムデフォルトを指定するか、型がパラメータなしイニシャライザを持つことを確認してください。",
                    line: 4,
                    column: 24,
                    severity: .warning
                ),
            ],
            macros: testMacros
        )
    }

    func test_UnresolvablePropertyType_GeneratesFatalErrorAndWarningDiagnostic() {
        assertMacroExpansion(
            """
            struct Uninitializable {}
            @NoopImplementation
            protocol UnresolvableProperty {
                var value: Uninitializable { get } // プロパティ
            }
            """,
            expandedSource: """
            struct Uninitializable {}
            protocol UnresolvableProperty {
                var value: Uninitializable { get } // プロパティ
            }

            internal final class NoopUnresolvableProperty: UnresolvableProperty {
                internal var value: Uninitializable {
                    get {
                        fatalError("Cannot generate default value for type 'Uninitializable'")
                    }
                }
                internal init() {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "型 'Uninitializable' のデフォルト値を決定できませんでした。 fatalError が挿入されます。'overrides' 引数でカスタムデフォルトを指定するか、型がパラメータなしイニシャライザを持つことを確認してください。",
                    line: 4,
                    column: 15,
                    severity: .warning
                ),
            ],
            macros: testMacros
        )
    }

    func test_UnresolvablePropertyProtocol_GeneratesFatalErrorAndWarningDiagnostic() {
        assertMacroExpansion(
            """
            @NoopImplementation
            public protocol UnresolvablePropertyProtocol {
                var unresolvable: NonExistentType { get }
            }
            """,
            expandedSource: """
            public protocol UnresolvablePropertyProtocol {
                var unresolvable: NonExistentType { get }
            }

            public final class NoopUnresolvablePropertyProtocol: UnresolvablePropertyProtocol {
                public var unresolvable: NonExistentType {
                    get {
                        fatalError("Cannot generate default value for type 'NonExistentType'")
                    }
                }
                public init() {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "型 'NonExistentType' のデフォルト値を決定できませんでした。 fatalError が挿入されます。'overrides' 引数でカスタムデフォルトを指定するか、型がパラメータなしイニシャライザを持つことを確認してください。",
                    line: 3,
                    column: 22,
                    severity: .warning
                ),
            ],
            macros: testMacros
        )
    }
}
