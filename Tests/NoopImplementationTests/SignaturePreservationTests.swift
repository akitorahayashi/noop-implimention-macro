@testable import NoopImplementationMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(NoopImplementationMacros)
    import NoopImplementationMacros
#endif

final class NISignaturePreservationTests: XCTestCase {
    // 各テストで使用するマクロを保持
    var testMacros: [String: Macro.Type] = [:]

    override func setUp() {
        #if canImport(NoopImplementationMacros)
            testMacros = [
                "NoopImplementation": NoopImplementationMacro.self,
            ]
        #endif
    }

    // `async` 関数を含むプロトコルに適用した場合、
    // `async` キーワードが保持された No-Op 関数が生成されることを確認
    func test_AsyncFunction_GeneratesAsyncNoopFunction() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                @NoopImplementation
                protocol AsyncWorker {
                    func performAsyncTask() async -> Int
                }
                """,
                expandedSource: """
                protocol AsyncWorker {
                    func performAsyncTask() async -> Int
                }

                internal final class NoopAsyncWorker: AsyncWorker {
                    internal func performAsyncTask() async -> Int {
                        return 0
                    }
                    internal init() {
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    // `throws` 関数を含むプロトコルに適用した場合、
    // `throws` キーワードが保持された No-Op 関数が生成されることを確認
    func test_ThrowsFunction_GeneratesThrowsNoopFunction() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                @NoopImplementation
                protocol RiskyOperation {
                    func attempt() throws -> Bool
                }
                """,
                expandedSource: """
                protocol RiskyOperation {
                    func attempt() throws -> Bool
                }

                internal final class NoopRiskyOperation: RiskyOperation {
                    internal func attempt() throws -> Bool {
                        return false
                    }
                    internal init() {
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    // `async throws` 関数を含むプロトコルに適用した場合、
    // `async` と `throws` キーワードが保持された No-Op 関数が生成されることを確認
    func test_AsyncThrowsFunction_GeneratesAsyncThrowsNoopFunction() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                @NoopImplementation
                protocol ComplexTask {
                    func executeComplex() async throws -> String
                }
                """,
                expandedSource: """
                protocol ComplexTask {
                    func executeComplex() async throws -> String
                }

                internal final class NoopComplexTask: ComplexTask {
                    internal func executeComplex() async throws -> String {
                        return ""
                    }
                    internal init() {
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }
}
