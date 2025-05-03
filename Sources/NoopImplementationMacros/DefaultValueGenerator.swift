import SwiftSyntax
import Foundation // Date, Data, UUID を使うため

// 他ファイルからアクセス可能にするため public
public struct DefaultValueGenerator {
    /// 指定された TypeSyntax に対するデフォルト値の文字列を生成します。
    public static func generate(for type: TypeSyntax) -> String {
        if let simpleType = type.as(IdentifierTypeSyntax.self)?.name.text {
            switch simpleType {
            case "Bool": return "false"
            case "Int", "UInt", "Double", "Float", "CGFloat": return "0"
            case "String": return "\"\"" // 空文字列リテラル
            case "Void": return ""
            case "Date": return "Date()"
            // Foundation のインポートが必要
            case "Data": return "Data()"
            case "UUID": return "UUID()"
            default:
                // 不明な単純型の場合は fatalError を生成
                return "fatalError(\"Cannot generate default value for type '\(simpleType)'\")"
            }
        } else if type.is(OptionalTypeSyntax.self) {
            return "nil"
        } else if type.is(ArrayTypeSyntax.self) || type.is(DictionaryTypeSyntax.self) {
            return "[: ]" // 配列・辞書の空リテラル
        } else if type.is(TupleTypeSyntax.self) {
            // タプルは未対応 (fatalError)
            return "fatalError(\"Default tuple generation not implemented\")"
        } else if type.description.hasPrefix("some ") { // `some Protocol` の処理
             // 型の文字列表現からプロトコル部分を抽出して再帰
             let constraintString = String(type.description.dropFirst("some ".count))
             let constraintType = TypeSyntax(stringLiteral: constraintString)
             return generate(for: constraintType)
        }
        // 複雑な型や未知の型の場合は fatalError を生成
        return "fatalError(\"Cannot generate default value for type \(type.description)\")"
    }
} 