import Foundation // Date, Data, UUID のテストのため
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(NoopImplementationMacros)
    import NoopImplementationMacros
#endif

final class NIDefaultValueGenerationTests: XCTestCase {
    var testMacros: [String: Macro.Type] = [:]

    override func setUp() {
        #if canImport(NoopImplementationMacros)
            testMacros = [
                "NoopImplementation": NoopImplementationMacro.self,
            ]
        #endif
    }

    func test_BasicTypes_GeneratesCorrectDefaultValues() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                @NoopImplementation
                protocol DataTypes {
                    var count: Int { get }
                    var name: String { get }
                    var enabled: Bool { get }
                    var optionalValue: Double? { get }
                    var list: [String] { get }
                    var mapping: [Int: String] { get }
                    func processVoid()
                }
                """,
                expandedSource: """
                protocol DataTypes {
                    var count: Int { get }
                    var name: String { get }
                    var enabled: Bool { get }
                    var optionalValue: Double? { get }
                    var list: [String] { get }
                    var mapping: [Int: String] { get }
                    func processVoid()
                }

                internal final class NoopDataTypes: DataTypes {
                    internal var count: Int {
                        get {
                            return 0
                        }
                    }
                    internal var name: String {
                        get {
                            return ""
                        }
                    }
                    internal var enabled: Bool {
                        get {
                            return false
                        }
                    }
                    internal var optionalValue: Double? {
                        get {
                            return nil
                        }
                    }
                    internal var list: [String] {
                        get {
                            return []
                        }
                    }
                    internal var mapping: [Int: String] {
                        get {
                            return [:]
                        }
                    }
                    internal func processVoid() {
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

    func test_FoundationTypes_GeneratesInitDefaultValues() throws {
        #if canImport(NoopImplementationMacros)
            assertMacroExpansion(
                """
                import Foundation
                @NoopImplementation
                protocol FoundationData {
                    var timestamp: Date { get }
                    var payload: Data { get }
                    var identifier: UUID { get }
                }
                """,
                expandedSource: """
                import Foundation
                protocol FoundationData {
                    var timestamp: Date { get }
                    var payload: Data { get }
                    var identifier: UUID { get }
                }

                internal final class NoopFoundationData: FoundationData {
                    internal var timestamp: Date {
                        get {
                            return Date()
                        }
                    }
                    internal var payload: Data {
                        get {
                            return Data()
                        }
                    }
                    internal var identifier: UUID {
                        get {
                            return UUID()
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
