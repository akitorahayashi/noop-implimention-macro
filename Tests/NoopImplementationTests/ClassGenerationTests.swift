import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(NoopImplementationMacros)
import NoopImplementationMacros
#endif

final class NoopImplementationClassGenerationTests: XCTestCase {
    // 各テストで使用するマクロを保持
    var testMacros: [String: Macro.Type] = [:]

    override func setUp() {
        #if canImport(NoopImplementationMacros)
        testMacros = [
            "NoopImplementation": NoopImplementationMacro.self,
        ]
        #endif
    }

    // `var` と `func` を含む基本的なプロトコルに適用した場合、
    // Noop クラスが正しく生成されることを確認 (アクセスレベルは別クラスでテスト)
    func test_BasicProtocol_GeneratesNoopClass() throws {
        #if canImport(NoopImplementationMacros)
        assertMacroExpansion(
            """
            @NoopImplementation
            protocol ServiceProtocol {
                var id: Int { get }
                func execute()
                func fetchValue(key: String) -> String?
            }
            """,
            expandedSource: """
            protocol ServiceProtocol {
                var id: Int { get }
                func execute()
                func fetchValue(key: String) -> String?
            }

            internal final class NoopServiceProtocol: ServiceProtocol {
                internal var id: Int = 0
                internal func execute() {
                }
                internal func fetchValue(key: String) -> String? {
                    return nil
                }
                internal init() {
                }
            }
            """,
            macros: self.testMacros
        )
        #else
        throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    // プロトコル名に "Protocol" 接尾辞がない場合でも、
    // Noop クラス名が正しく "Noop" + プロトコル名になることを確認
    func test_ProtocolWithoutSuffix_GeneratesCorrectClassName() throws {
        #if canImport(NoopImplementationMacros)
        assertMacroExpansion(
            """
            @NoopImplementation
            protocol SimpleService {
                func performAction()
            }
            """,
            expandedSource: """
            protocol SimpleService {
                func performAction()
            }

            internal final class NoopSimpleService: SimpleService {
                internal func performAction() {
                }
                internal init() {
                }
            }
            """,
            macros: self.testMacros
        )
        #else
        throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    // 空のプロトコルに適用した場合でも、
    // Noop クラスとデフォルトイニシャライザが生成されることを確認
    func test_EmptyProtocol_GeneratesEmptyNoopClass() throws {
        #if canImport(NoopImplementationMacros)
        assertMacroExpansion(
            """
            @NoopImplementation
            protocol EmptyProtocol {}
            """,
            expandedSource: """
            protocol EmptyProtocol {}

            internal final class NoopEmptyProtocol: EmptyProtocol {
                internal init() {
                }
            }
            """,
            macros: self.testMacros
        )
        #else
        throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    // プロパティのみを持つプロトコルに適用した場合、
    // プロパティに対する No-Op 実装が正しく生成されることを確認
    func test_ProtocolWithOnlyProperties_GeneratesNoopProperties() throws {
        #if canImport(NoopImplementationMacros)
        assertMacroExpansion(
            """
            @NoopImplementation
            protocol ConfigStore {
                var timeout: Double { get }
                var retries: Int? { get set }
            }
            """,
            expandedSource: """
            protocol ConfigStore {
                var timeout: Double { get }
                var retries: Int? { get set }
            }

            internal final class NoopConfigStore: ConfigStore {
                internal var timeout: Double = 0
                internal var retries: Int? = nil
                internal init() {
                }
            }
            """,
            macros: self.testMacros
        )
        #else
        throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }
} 