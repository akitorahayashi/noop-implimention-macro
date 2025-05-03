import Foundation

// このエラーは、デフォルト値を生成できない場合に生成されたコードによってスローされます。
public enum NoopError: Error, CustomStringConvertible {
    case defaultValueUnavailable(typeName: String)

    public var description: String {
        switch self {
            case let .defaultValueUnavailable(typeName):
                "NoopImplementation could not generate a default value for type '\(typeName)'. " +
                    "The function throwing this error is effectively unimplemented."
        }
    }
}
