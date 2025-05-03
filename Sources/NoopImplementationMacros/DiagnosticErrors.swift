import SwiftDiagnostics
import SwiftSyntax

// MARK: - Diagnostic Messages

// 他ファイルからアクセス可能にするため public
public struct SimpleDiagnosticMessage: DiagnosticMessage, Error {
    public let message: String
    public let diagnosticID: MessageID
    public let severity: DiagnosticSeverity

    // public な static プロパティとして定義
    public static let notAProtocol = SimpleDiagnosticMessage(
        message: "@NoopImplementation はプロトコルにのみ適用できます。",
        diagnosticID: MessageID(domain: "NoopImplementationMacro", id: "notAProtocol"),
        severity: .error
    )
    public static let invalidArgument = SimpleDiagnosticMessage(
        message: "@NoopImplementation に無効な引数が指定されました。",
        diagnosticID: MessageID(domain: "NoopImplementationMacro", id: "invalidArgument"),
        severity: .warning
    )

    // overrides 引数関連のエラー
    public static let invalidOverrideArgument = SimpleDiagnosticMessage(
        message: "'overrides' 引数の値が無効です。辞書リテラル (例: [\"String\": \"Value\", \"Int\": 0]) を期待します。",
        diagnosticID: MessageID(domain: "NoopImplementationMacro", id: "invalidOverrideArgument"),
        severity: .error
    )
    public static let invalidOverrideKey = SimpleDiagnosticMessage(
        message: "'overrides' 辞書のキーが無効です。型名を表す文字列リテラルを期待します。",
        diagnosticID: MessageID(domain: "NoopImplementationMacro", id: "invalidOverrideKey"),
        severity: .error
    )

    // デフォルト値生成失敗時の Diagnostic (fatalError / throw 用)
    public static func fatalErrorDefaultValue(typeName: String) -> SimpleDiagnosticMessage {
        SimpleDiagnosticMessage(
            message: "型 '\(typeName)' のデフォルト値を決定できませんでした。 fatalError が挿入されます。'overrides' 引数でカスタムデフォルトを指定するか、型がパラメータなしイニシャライザを持つことを確認してください。",
            diagnosticID: MessageID(domain: "NoopImplementationMacro", id: "fatalErrorDefaultValue"),
            severity: .warning
        )
    }

    // その他のパースエラーなど
    public static func other(_ message: String) -> SimpleDiagnosticMessage {
        SimpleDiagnosticMessage(
            message: message,
            diagnosticID: MessageID(domain: "NoopImplementationMacro", id: "otherError"),
            severity: .error
        )
    }
}

// MARK: - Noop Error Type

// マクロが throw する可能性のあるエラー型
public enum NoopError: Error, CustomStringConvertible {
    case defaultValueUnavailable(typeName: String)

    public var description: String {
        switch self {
            case let .defaultValueUnavailable(typeName):
                "NoopImplementation: throws する関数内で型 '\(typeName)' のデフォルト値を決定できませんでした。"
        }
    }
}
