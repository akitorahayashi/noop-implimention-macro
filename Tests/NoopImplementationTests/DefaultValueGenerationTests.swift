import Foundation // Date, Data, UUID のテストのため
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(NoopImplementationMacros)
    import NoopImplementationMacros
#endif

final class NIDefaultValueGenerationTests: XCTestCase {
    // 各テストで使用するマクロを保持
    var testMacros: [String: Macro.Type] = [:]

    override func setUp() {
        #if canImport(NoopImplementationMacros)
            testMacros = [
                "NoopImplementation": NoopImplementationMacro.self,
            ]
        #endif
    }

    // 様々な基本的な型 (Int, String, Bool, Optional, Array, Dictionary) を含むプロトコルに適用した場合、
    // それぞれに対応する正しいデフォルト値が生成されることを確認
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
                    internal var count: Int = 0
                    internal var name: String = ""
                    internal var enabled: Bool = false
                    internal var optionalValue: Double? = nil
                    internal var list: [String] = [: ]
                    internal var mapping: [Int: String] = [: ]
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

    // Foundation 型 (Date, Data, UUID) を含むプロトコルに適用した場合、
    // `.init()` によるデフォルト値が生成されることを確認
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
                    internal var timestamp: Date = Date()
                    internal var payload: Data = Data()
                    internal var identifier: UUID = UUID()
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
