import Foundation

// MARK: - Error Type for Macro

// This error is thrown by generated code when a default value cannot be created.
public enum NoopError: Error, CustomStringConvertible {
    case defaultValueUnavailable(typeName: String)

    public var description: String {
        switch self {
        case .defaultValueUnavailable(let typeName):
            return "NoopImplementation could not generate a default value for type '\(typeName)'. The function throwing this error is effectively unimplemented."
        }
    }
} 