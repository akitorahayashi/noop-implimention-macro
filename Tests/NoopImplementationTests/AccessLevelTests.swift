import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(NoopImplementationMacros)
    @testable import NoopImplementationMacros
#endif

final class NoopImplementationAccessLevelTests: XCTestCase {
    var testMacros: [String: Macro.Type] = [:]

    override func setUp() {
        super.setUp()
        #if canImport(NoopImplementationMacros)
            testMacros = [
                "NoopImplementation": NoopImplementationMacro.self,
            ]
        #endif
    }

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
                    public var version: String {
                        get {
                            return ""
                        }
                    }
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

    func test_InternalProtocol_GeneratesInternalMembers() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                import Foundation
                @NoopImplementation
                protocol InternalService {
                    var data: Data { get }
                    func doInternalWork()
                }
                """,
                expandedSource: """
                import Foundation
                protocol InternalService {
                    var data: Data { get }
                    func doInternalWork()
                }

                internal final class NoopInternalService: InternalService {
                    internal var data: Data {
                        get {
                            return Data()
                        }
                    }
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
