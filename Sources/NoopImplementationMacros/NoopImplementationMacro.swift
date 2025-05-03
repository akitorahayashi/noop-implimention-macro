import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - マクロ実装

public struct NoopImplementationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            // プロトコル以外に適用された場合、エラーとして診断
            let diagnostic = Diagnostic(node: Syntax(node), message: SimpleDiagnosticMessage.notAProtocol)
            context.diagnose(diagnostic)
            return []
        }

        // プロトコル宣言からアクセスレベルを決定 (デフォルトは internal)
        let protocolAccessModifier = protocolDecl.modifiers.first(where: { [
            .keyword(.public),
            .keyword(.internal),
            .keyword(.fileprivate),
            .keyword(.private),
        ].contains($0.name.tokenKind) }) ?? DeclModifierSyntax(name: .keyword(.internal))

        let members = protocolDecl.memberBlock.members
        var noopStructMembers: [DeclSyntax] = []
        for member in members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                // 関数定義から No-Op 関数を生成 (アクセス修飾子を渡す)
                noopStructMembers.append(Self.generateNoopFunction(
                    from: funcDecl,
                    accessModifier: protocolAccessModifier,
                    in: context
                ))
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // 変数定義から No-Op プロパティを生成 (アクセス修飾子を渡す)
                noopStructMembers.append(contentsOf: Self.generateNoopProperty(
                    from: varDecl,
                    accessModifier: protocolAccessModifier,
                    in: context
                ))
            }
        }

        // 決定されたアクセスレベルでデフォルトイニシャライザを追加
        noopStructMembers.append(DeclSyntax("\(raw: protocolAccessModifier.name.text) init() {}"))

        let protocolName = protocolDecl.name.text
        let noopClassName = determineNoopClassName(protocolName: protocolName)

        // クラス宣言を生成 (final)
        // 決定されたアクセス修飾子を適用
        let classDecl = ClassDeclSyntax(
            modifiers: [protocolAccessModifier, DeclModifierSyntax(name: .keyword(.final))],
            name: TokenSyntax.identifier(noopClassName),
            inheritanceClause: InheritanceClauseSyntax {
                InheritedTypeSyntax(type: TypeSyntax(stringLiteral: protocolName))
            }
        ) {
            for member in noopStructMembers {
                member
            }
        }

        return [DeclSyntax(classDecl)]
    }

    /// 生成する No-Op クラスの名前を決定
    private static func determineNoopClassName(protocolName: String) -> String {
        "Noop" + protocolName
    }

    /// No-Op 関数実装を生成
    private static func generateNoopFunction(
        from funcDecl: FunctionDeclSyntax,
        accessModifier: DeclModifierSyntax,
        in context: some MacroExpansionContext
    ) -> DeclSyntax {
        // 元の関数宣言をコピーして変更を開始
        var newFunc = funcDecl

        // 不要なトリビア（コメントや空白）をクリア
        newFunc.leadingTrivia = []
        newFunc.trailingTrivia = []
        // func キーワードや関数名、パラメータ句などのトリビアもクリア
        newFunc.funcKeyword = newFunc.funcKeyword.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
        newFunc.name = newFunc.name.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
        newFunc.signature.parameterClause = newFunc.signature.parameterClause.with(\.leadingTrivia, []).with(
            \.trailingTrivia,
            []
        )
        if var returnClause = newFunc.signature.returnClause {
            returnClause.arrow = returnClause.arrow.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
            returnClause.type = returnClause.type.with(\.leadingTrivia, []).with(\.trailingTrivia, []) // 型のトリビアもクリア
            newFunc.signature.returnClause = returnClause
        }

        // 元の effects 指定子 (async, throws) を保持
        newFunc.signature.effectSpecifiers = funcDecl.signature.effectSpecifiers
        // 引数で渡されたアクセス修飾子を適用
        newFunc.modifiers = [accessModifier]

        if let returnClause = funcDecl.signature.returnClause {
            // 型のトリビアをクリアしたバージョンを使用
            let returnType = returnClause.type.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
            // デフォルト値生成クラスを使用
            let defaultValueString = DefaultValueGenerator.generate(for: returnType)

            // デフォルト値生成の結果を確認
            if defaultValueString.starts(with: "fatalError") {
                // 関数が throw できる場合、fatalError の代わりにエラーを throw する
                if funcDecl.signature.effectSpecifiers?.throwsSpecifier != nil {
                    // 型名に含まれるダブルクォートをエスケープ
                    let typeName = returnType.description.replacingOccurrences(of: "\"", with: "\\\"")

                    // NoopError 呼び出しの FunctionCallExprSyntax を構築
                    let calledExpression = MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .identifier("NoopError")),
                        name: .identifier("defaultValueUnavailable")
                    )
                    let argument = LabeledExprSyntax(
                        label: "typeName",
                        expression: StringLiteralExprSyntax(content: typeName)
                    )
                    let errorExpr = FunctionCallExprSyntax(
                        calledExpression: calledExpression,
                        leftParen: .leftParenToken(),
                        arguments: LabeledExprListSyntax([argument]),
                        rightParen: .rightParenToken()
                    )
                    // throw 文を生成
                    let throwStmt = ThrowStmtSyntax(expression: errorExpr)

                    // デフォルト値生成不可の場合の診断 (必要であれば追加)
                    // context.diagnose(...)
                    newFunc.body = CodeBlockSyntax {
                        throwStmt
                    }
                } else {
                    // それ以外の場合、fatalError を生成 (コンパイルエラーを意図)
                    // fatalError 生成に関する診断を報告
                    let diagnostic = Diagnostic(
                        node: Syntax(returnType), // トリビアをクリアした型ノードを使用
                        message: SimpleDiagnosticMessage.fatalErrorDefaultValue(typeName: returnType.trimmedDescription)
                    )
                    context.diagnose(diagnostic)
                    // fatalError(...) は値を返さない式
                    let fatalErrorString =
                        "fatalError(\"Cannot generate default value for type '\(returnType.trimmedDescription)\'\")"
                    newFunc.body = CodeBlockSyntax {
                        ExprSyntax(stringLiteral: fatalErrorString)
                    }
                }
            } else {
                // デフォルト値の生成に成功
                // ReturnStmtSyntax で return 文を生成
                newFunc.body = CodeBlockSyntax {
                    ReturnStmtSyntax(expression: ExprSyntax(stringLiteral: defaultValueString))
                }
            }
        } else { // 戻り値がない (Void) 関数の場合
            newFunc.body = CodeBlockSyntax {}
        }

        // 実装において、パラメータの属性 (@escaping など) を削除
        let cleanedParameters = funcDecl.signature.parameterClause.parameters.map { param in
            var newParam = param
            newParam.attributes = []
            // パラメータのトリビアもクリア
            newParam.leadingTrivia = []
            newParam.trailingTrivia = []
            // firstName は non-optional なので直接クリア
            newParam.firstName.leadingTrivia = []
            newParam.firstName.trailingTrivia = []
            // secondName は optional なので if var でクリア
            if var secondName = newParam.secondName {
                secondName.leadingTrivia = []
                secondName.trailingTrivia = []
                newParam.secondName = secondName
            }
            // type は non-optional なので直接クリア
            newParam.type.leadingTrivia = []
            newParam.type.trailingTrivia = []

            return newParam
        }
        newFunc.signature.parameterClause.parameters = FunctionParameterListSyntax(cleanedParameters)

        // 実装シグネチャからジェネリック制約を削除
        newFunc.genericWhereClause = nil
        newFunc.genericParameterClause = nil

        return DeclSyntax(newFunc)
    }

    /// No-Op プロパティ実装を生成します。
    private static func generateNoopProperty(
        from varDecl: VariableDeclSyntax,
        accessModifier: DeclModifierSyntax,
        in context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        var generatedProperties: [DeclSyntax] = []

        // 引数で渡されたアクセス修飾子を適用
        // let accessModifier = DeclModifierSyntax(name: accessLevel) // <- この行は冗長

        // 各 binding を処理
        for binding in varDecl.bindings {
            // 元の binding からトリビアをクリアしたコピーを作成
            var cleanBinding = binding
            cleanBinding.leadingTrivia = []
            cleanBinding.trailingTrivia = []
            if var pat = cleanBinding.pattern.as(IdentifierPatternSyntax.self) {
                pat.identifier = pat.identifier.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
                cleanBinding.pattern = PatternSyntax(pat)
            }
            if var ta = cleanBinding.typeAnnotation {
                ta.colon = ta.colon.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
                ta.type = ta.type.with(\.leadingTrivia, []).with(\.trailingTrivia, []) // 型のトリビアをクリア
                cleanBinding.typeAnnotation = ta
            }
            cleanBinding.initializer = nil // 元の初期化子は不要

            guard let pattern = cleanBinding.pattern.as(IdentifierPatternSyntax.self),
                  let typeAnnotation = cleanBinding.typeAnnotation
            else {
                continue
            }

            _ = pattern.identifier.text // 未使用変数の警告抑制のため参照
            let varType = typeAnnotation.type // トリビアがクリアされた型
            // デフォルト値生成クラスを使用
            let defaultValue = DefaultValueGenerator.generate(for: varType)

            // デフォルト値生成が fatalError になったか確認
            if defaultValue.starts(with: "fatalError") {
                // fatalError 生成に関する診断を報告
                let diagnostic = Diagnostic(
                    node: Syntax(varType), // トリビアをクリアした型ノードを使用
                    message: SimpleDiagnosticMessage.fatalErrorDefaultValue(typeName: varType.trimmedDescription)
                )
                context.diagnose(diagnostic)
            }

            // 新しい VariableDecl を生成 (アクセス修飾子を適用)
            let newBinding = PatternBindingSyntax(
                pattern: cleanBinding.pattern,
                typeAnnotation: cleanBinding.typeAnnotation,
                initializer: InitializerClauseSyntax(value: ExprSyntax(stringLiteral: defaultValue))
            )
            let newVarDecl = VariableDeclSyntax(
                modifiers: [accessModifier],
                bindingSpecifier: .keyword(.var),
                bindings: [newBinding]
            )
            generatedProperties.append(DeclSyntax(newVarDecl))
        }
        return generatedProperties
    }
}
