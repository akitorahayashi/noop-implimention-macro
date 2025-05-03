import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(NoopImplementationMacros)
    import NoopImplementationMacros
#endif

final class NoopImplementationAccessLevelTests: XCTestCase {
    // 各テストで使用するマクロを保持
    var testMacros: [String: Macro.Type] = [:]

    override func setUp() {
        #if canImport(NoopImplementationMacros)
            testMacros = [
                "NoopImplementation": NoopImplementationMacro.self,
            ]
        #endif
    }

    // `public` なプロトコルに適用した場合、
    // 生成される Noop クラスとメンバーも `public` になることを確認
    func test_PublicProtocol_GeneratesPublicMembers() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                @NoopImplementation
                public protocol PublicService {
                    var version: String { get }
                    public func fetchStatus()
                }
                """,
                expandedSource: """
                public protocol PublicService {
                    var version: String { get }
                    public func fetchStatus()
                }

                public final class NoopPublicService: PublicService {
                    public var version: String = ""
                    public func fetchStatus() {
                    }
                    public init() {
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("マクロはホストプラットフォームでのテスト実行時のみサポートされます")
        #endif
    }

    // `internal` なプロトコル (または修飾子なし) に適用した場合、
    // 生成される Noop クラスとメンバーが `internal` になることを確認
    func test_InternalProtocol_GeneratesInternalMembers() throws {
        #if canImport(NoopImplementationMacros)
            // `internal` はデフォルトなので、修飾子なしでテスト
            assertMacroExpansion(
                """
                @NoopImplementation
                protocol InternalService {
                    var data: Data { get }
                    func doInternalWork()
                }
                """,
                expandedSource: """
                protocol InternalService {
                    var data: Data { get }
                    func doInternalWork()
                }

                internal final class NoopInternalService: InternalService {
                    internal var data: Data = Data()
                    internal func doInternalWork() {
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
