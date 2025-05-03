import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(NoopImplementationMacros)
    @testable import NoopImplementationMacros
#endif

// swiftlint:disable:next type_body_length
final class CustomDefaultValueTests: XCTestCase {
    var testMacros: [String: Macro.Type] = [:]

    override func setUp() {
        super.setUp()
        #if canImport(NoopImplementationMacros)
            testMacros = [
                "NoopImplementation": NoopImplementationMacro.self,
            ]
        #endif
    }

    func testBasicCustomDefaults() {
        assertMacroExpansion(
            """
            @NoopImplementation(overrides: ["String": "\\\"Custom Default\\\"", "Int": 42, "Bool": true])
            protocol MyService {
                func getName() -> String
                func getCount() -> Int
                var isActive: Bool { get }
                func getStandardValue() -> Double // Not overridden
            }
            """,
            expandedSource: """
            protocol MyService {
                func getName() -> String
                func getCount() -> Int
                var isActive: Bool { get }
                func getStandardValue() -> Double // Not overridden
            }

            internal final class NoopMyService: MyService {
                internal func getName() -> String {
                    return "\\\"Custom Default\\\""
                }
                internal func getCount() -> Int {
                    return 42
                }
                internal var isActive: Bool {
                    get {
                        return true
                    }
                }
                internal func getStandardValue() -> Double {
                    return 0
                }
                internal init() {
                }
            }
            """,
            macros: testMacros
        )
    }

    func testPropertyCustomDefault() {
        // Define MyStruct locally for this test if not available globally
        // Note: The actual struct definition doesn't affect macro expansion itself,
        // but is needed for the source code to be syntactically valid.
        assertMacroExpansion(
            """
            struct MyStruct { let id: String }
            @NoopImplementation(overrides: ["URL": URL(string: "https://overridden.com")!, "MyStruct": MyStruct(id: "custom")])
            protocol ConfigProvider {
                var defaultURL: URL { get }
                var customStruct: MyStruct { get }
                var standardInt: Int { get }
            }
            """,
            expandedSource: """
            struct MyStruct { let id: String }
            protocol ConfigProvider {
                var defaultURL: URL { get }
                var customStruct: MyStruct { get }
                var standardInt: Int { get }
            }

            internal final class NoopConfigProvider: ConfigProvider {
                internal var defaultURL: URL {
                    get {
                        return URL(string: "https://overridden.com")!
                    }
                }
                internal var customStruct: MyStruct {
                    get {
                        return MyStruct(id: "custom")
                    }
                }
                internal var standardInt: Int {
                    get {
                        return 0
                    }
                }
                internal init() {
                }
            }
            """,
            macros: testMacros
        )
    }

    func testMixedDefaults() {
        assertMacroExpansion(
            """
            import Foundation // Needed for Data
            @NoopImplementation(overrides: ["String": "\\\"Specific Override\\\""])
            protocol DataFetcher {
                func fetchString() -> String
                var count: Int { get }
                var data: Data { get }
            }
            """,
            expandedSource: """
            import Foundation // Needed for Data
            protocol DataFetcher {
                func fetchString() -> String
                var count: Int { get }
                var data: Data { get }
            }

            internal final class NoopDataFetcher: DataFetcher {
                internal func fetchString() -> String {
                    return "\\\"Specific Override\\\""
                }
                internal var count: Int {
                    get {
                        return 0
                    }
                }
                internal var data: Data {
                    get {
                        return Data()
                    }
                }
                internal init() {
                }
            }
            """,
            macros: testMacros
        )
    }

    func testNoOverridesArgument() {
        assertMacroExpansion(
            """
            @NoopImplementation
            protocol SimpleProtocol {
                func getString() -> String
                var number: Int { get }
            }
            """,
            expandedSource: """
            protocol SimpleProtocol {
                func getString() -> String
                var number: Int { get }
            }

            internal final class NoopSimpleProtocol: SimpleProtocol {
                internal func getString() -> String {
                    return ""
                }
                internal var number: Int {
                    get {
                        return 0
                    }
                }
                internal init() {
                }
            }
            """,
            macros: testMacros
        )
    }

    func testInvalidOverrideArgumentTypeDiagnostic() {
        assertMacroExpansion(
            """
            @NoopImplementation(overrides: "Not A Dictionary")
            protocol BadArgsProtocol {
                func getValue() -> Int
            }
            """,
            expandedSource: """
            protocol BadArgsProtocol {
                func getValue() -> Int
            }

            internal final class NoopBadArgsProtocol: BadArgsProtocol {
                internal func getValue() -> Int {
                    return 0
                }
                internal init() {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'overrides' 引数の値が無効です。辞書リテラル (例: [\"String\": \"Value\", \"Int\": 0]) を期待します。",
                    line: 1,
                    column: 32,
                    severity: .error
                ),
            ],
            macros: testMacros
        )
    }

    func testInvalidOverrideKeyTypeDiagnostic() {
        assertMacroExpansion(
            """
            @NoopImplementation(overrides: [123: "Value"])
            protocol BadKeyProtocol {
                func getValue() -> Int
            }
            """,
            expandedSource: """
            protocol BadKeyProtocol {
                func getValue() -> Int
            }

            internal final class NoopBadKeyProtocol: BadKeyProtocol {
                internal func getValue() -> Int {
                    return 0
                }
                internal init() {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'overrides' 辞書のキーが無効です。型名を表す文字列リテラルを期待します。",
                    line: 1,
                    column: 33,
                    severity: .error
                ),
            ],
            macros: testMacros
        )
    }

    func testThrowingFunctionWithCustomDefaultAndFailure() {
        assertMacroExpansion(
            """
            enum MyError: Error { case oops }
            @NoopImplementation(overrides: ["String": "\\\"Custom Throwing Default\\\""])
            protocol ThrowingService {
                func maybeGetString() throws -> String
                func standardThrow() throws -> Bool // Standard default ok
                func complexThrow() throws -> () -> Void // Default generator fails -> throw NoopError
            }
            """,
            expandedSource: """
            enum MyError: Error { case oops }
            protocol ThrowingService {
                func maybeGetString() throws -> String
                func standardThrow() throws -> Bool // Standard default ok
                func complexThrow() throws -> () -> Void // Default generator fails -> throw NoopError
            }

            internal final class NoopThrowingService: ThrowingService {
                internal func maybeGetString() throws -> String {
                    return "\\\"Custom Throwing Default\\\""
                }
                internal func standardThrow() throws -> Bool {
                    return false
                }
                internal func complexThrow() throws -> () -> Void {
                    return {
                    }
                }
                internal init() {
                }
            }
            """,
            macros: testMacros
        )
    }
}
