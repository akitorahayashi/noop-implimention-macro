import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder // ExprSyntax を簡単に作るために便利

/// 指定された型に対してデフォルト値の式を生成する
public enum DefaultValueGenerator {
    // 指定された TypeSyntax に対するデフォルト値の文字列を生成します。

    // 戻り値を ExprSyntax? に変更。Diagnostic は返さず、失敗時は nil を返す
    // swiftlint:disable:next cyclomatic_complexity
    public static func generateSyntax(for type: TypeSyntax) -> ExprSyntax? {
        if type.is(OptionalTypeSyntax.self) {
            // Optional 型は nil を生成
            return ExprSyntax(NilLiteralExprSyntax())
        }

        if let simpleType = type.as(IdentifierTypeSyntax.self) {
            let typeName = simpleType.name.text
            let typeIdentifierExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: simpleType.name))

            switch typeName {
                case "Int", "UInt", "Double", "Float", "CGFloat", "TimeInterval", "NSInteger", "NSUInteger":
                    return ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral("0")))
                case "String", "NSString":
                    return ExprSyntax(StringLiteralExprSyntax(content: ""))
                case "Bool":
                    return ExprSyntax(BooleanLiteralExprSyntax(literal: .keyword(.false)))
                case "Void", "()":
                    // Void は式として表現できないため nil (生成失敗)
                    return nil
                // Foundation 型 (イニシャライザ呼び出しで生成)
                case "Date", "Data", "UUID":
                    let initCall = FunctionCallExprSyntax(
                        calledExpression: typeIdentifierExpr,
                        leftParen: .leftParenToken(),
                        arguments: LabeledExprListSyntax([]),
                        rightParen: .rightParenToken()
                    )
                    return ExprSyntax(initCall)
                case "URL":
                    let urlStringLiteral = StringLiteralExprSyntax(content: "https://apple.com")
                    let argument = LabeledExprSyntax(label: "string", expression: urlStringLiteral)
                    let initCall = FunctionCallExprSyntax(
                        calledExpression: typeIdentifierExpr,
                        leftParen: .leftParenToken(),
                        arguments: LabeledExprListSyntax([argument]),
                        rightParen: .rightParenToken()
                    )
                    let forceUnwrap = ForceUnwrapExprSyntax(expression: initCall)
                    return ExprSyntax(forceUnwrap)
                default:
                    // 不明な IdentifierType: Type() を試さず nil (生成失敗) を返す
                    return nil
            }
        }

        if type.is(ArrayTypeSyntax.self) {
            return ExprSyntax(ArrayExprSyntax(elements: []))
        }

        if type.is(DictionaryTypeSyntax.self) {
            // 空の辞書リテラル [:] を生成するように修正
            return ExprSyntax(DictionaryExprSyntax(content: .colon(.colonToken())))
        }

        if let tupleType = type.as(TupleTypeSyntax.self) {
            var elements: [LabeledExprSyntax] = []
            for element in tupleType.elements {
                let elementType = element.type
                // 再帰呼び出し。要素生成に失敗したらタプル全体も nil (生成失敗)
                guard let elementExpr = generateSyntax(for: elementType) else {
                    return nil
                }
                let tupleElement = LabeledExprSyntax(
                    label: element.firstName,
                    colon: element.firstName != nil ? .colonToken(trailingTrivia: .space) : nil,
                    expression: elementExpr
                )
                elements.append(tupleElement)
            }
            return ExprSyntax(TupleExprSyntax(elements: LabeledExprListSyntax(elements)))
        }

        // FunctionTypeSyntax (クロージャ) の処理を追加
        if let closureType = type.as(FunctionTypeSyntax.self) {
            // dump(closureType) // デバッグ用 dump は一旦コメントアウト
            // 引数なし、戻り値 Void のシンプルなクロージャのみ対応
            // closureType.returnClause と returnClause.type は非オプショナルとして扱う
            if closureType.parameters.isEmpty {
                let returnType = closureType.returnClause.type
                if let returnTypeIdentifier = returnType.as(IdentifierTypeSyntax.self),
                   returnTypeIdentifier.name.text == "Void" || returnTypeIdentifier.name.text == "()"
                {
                    // 空のクロージャ式 {} を生成
                    return ExprSyntax(ClosureExprSyntax(statements: []))
                } else {
                    // Void 以外の戻り値を持つクロージャは未対応
                    return nil
                }
            } else {
                // 引数を持つクロージャは未対応
                return nil
            }
        }

        // その他の未対応型 (クロージャ等)
        return nil
    }
}
