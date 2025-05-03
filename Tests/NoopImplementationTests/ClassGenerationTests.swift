import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(NoopImplementationMacros)
    import NoopImplementationMacros
#endif

final class NoopImplementationClassGenerationTests: XCTestCase {
    var testMacros: [String: Macro.Type] = [:]

    override func setUp() {
        #if canImport(NoopImplementationMacros)
            testMacros = [
                "NoopImplementation": NoopImplementationMacro.self,
            ]
        #endif
    }

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
                    internal var id: Int {
                        get {
                            return 0
                        }
                    }
                    internal func execute() {
                    }
                    internal func fetchValue(key: String) -> String? {
                        return nil
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

    func test_ProtocolWithoutSuffix_GeneratesCorrectClassName() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                @NoopImplementation
                protocol MyService {
                    func doWork()
                }
                """,
                expandedSource: """
                protocol MyService {
                    func doWork()
                }

                internal final class NoopMyService: MyService {
                    internal func doWork() {
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

    func test_EmptyProtocol_GeneratesEmptyNoopClass() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                @NoopImplementation
                protocol Empty {
                }
                """,
                expandedSource: """
                protocol Empty {
                }

                internal final class NoopEmpty: Empty {
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

    func test_ProtocolWithOnlyProperties_GeneratesNoopProperties() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                @NoopImplementation
                protocol ConfigStore {
                    var timeout: Double { get }
                    var retries: Int? { get set } // get/set プロパティ (現状 get のみ実装)
                }
                """,
                expandedSource: """
                protocol ConfigStore {
                    var timeout: Double { get }
                    var retries: Int? { get set } // get/set プロパティ (現状 get のみ実装)
                }

                internal final class NoopConfigStore: ConfigStore {
                    internal var timeout: Double {
                        get {
                            return 0
                        }
                    }
                    internal var retries: Int? {
                        get {
                            return nil
                        }
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
