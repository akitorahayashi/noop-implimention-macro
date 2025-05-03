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

    // デフォルト値が生成できず fatalError を生成する場合の診断メッセージ
    public static func fatalErrorDefaultValue(typeName: String) -> SimpleDiagnosticMessage {
        SimpleDiagnosticMessage(
            message: "型 '\(typeName)' のデフォルト値を生成できないため、 fatalError を挿入します。",
            diagnosticID: MessageID(domain: "NoopImplementationMacro", id: "fatalErrorDefaultValue"),
            severity: .warning // 警告とし、コンパイルエラーでユーザーに知らせる
        )
    }
}
