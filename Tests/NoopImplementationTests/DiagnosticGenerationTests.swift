import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(NoopImplementationMacros)
import NoopImplementationMacros
#endif

final class NoopImplementationDiagnosticGenerationTests: XCTestCase {
    // 各テストで使用するマクロを保持
    var testMacros: [String: Macro.Type] = [:]

    override func setUp() {
        #if canImport(NoopImplementationMacros)
        testMacros = [
            "NoopImplementation": NoopImplementationMacro.self,
        ]
        #endif
    }

    // プロトコル以外 (struct) に適用した場合、
    // 正しいエラー診断メッセージが生成されることを確認
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
                // エラーメッセージ、行、列、重大度を検証
                DiagnosticSpec(message: "@NoopImplementation はプロトコルにのみ適用できます。", line: 1, column: 1, severity: .error)
            ],
            macros: self.testMacros
        )
        #else
        throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    // プロトコル以外 (class) に適用した場合、
    // 正しいエラー診断メッセージが生成されることを確認
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
                DiagnosticSpec(message: "@NoopImplementation はプロトコルにのみ適用できます。", line: 1, column: 1, severity: .error)
            ],
            macros: self.testMacros
        )
        #else
        throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    // デフォルト値を生成できない型を返す `throws` 関数がある場合、
    // NoopError を throw するコードが生成されることを確認 (診断は出ない)
    func test_UnresolvableTypeInThrowsFunc_GeneratesThrowNoopErrorWithoutDiagnostic() throws {
        #if canImport(NoopImplementationMacros)
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
                internal func getValue() throws -> Uninitializable {
                    throw NoopError.defaultValueUnavailable(typeName: "Uninitializable")
                }
                internal init() {
                }
            }
            """,
            // 診断が出ないことを確認
            diagnostics: [],
            macros: self.testMacros
        )
        #else
        throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    // デフォルト値を生成できない型を返す非 `throws` 関数がある場合、
    // `fatalError` を呼び出すコードと警告診断メッセージが生成されることを確認
    func test_UnresolvableTypeInNonThrowsFunc_GeneratesFatalErrorAndWarningDiagnostic() throws {
        #if canImport(NoopImplementationMacros)
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
                // メッセージ内の型名をトリムされたものに、列番号を調整
                DiagnosticSpec(message: "型 'Uninitializable' のデフォルト値を生成できないため、 fatalError を挿入します。", line: 4, column: 24, severity: .warning)
            ],
            macros: self.testMacros
        )
        #else
        throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

     // デフォルト値を生成できない型のプロパティがある場合、
     // `fatalError` を呼び出すコードと警告診断メッセージが生成されることを確認
    func test_UnresolvablePropertyType_GeneratesFatalErrorAndWarningDiagnostic() throws {
        #if canImport(NoopImplementationMacros)
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
                internal var value: Uninitializable = fatalError("Cannot generate default value for type 'Uninitializable'")
                internal init() {
                }
            }
            """,
            diagnostics: [
                // メッセージ内の型名をトリムされたものに、列番号を調整
                DiagnosticSpec(message: "型 'Uninitializable' のデフォルト値を生成できないため、 fatalError を挿入します。", line: 4, column: 15, severity: .warning)
            ],
            macros: self.testMacros
        )
        #else
        throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    func test_UnresolvablePropertyProtocol_GeneratesFatalErrorAndWarningDiagnostic() throws {
        #if canImport(NoopImplementationMacros)
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
                public  var unresolvable: NonExistentType = fatalError("Cannot generate default value for type 'NonExistentType'")
                public init() {
                }
            }
            """,
            diagnostics: [
                // 期待される診断: 不明な型に対する警告
                DiagnosticSpec(
                    message: "型 'NonExistentType' のデフォルト値を生成できないため、 fatalError を挿入します。",
                    line: 3,
                    column: 22,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
        #endif
    }
} 