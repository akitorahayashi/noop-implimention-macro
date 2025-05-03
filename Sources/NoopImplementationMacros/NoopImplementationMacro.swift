import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - マクロ実装

// swiftlint:disable:next type_body_length
public struct NoopImplementationMacro: PeerMacro {
    // PeerMacro の expansion メソッド
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol, // MemberMacro の providingMembersOf から変更
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // --- 引数解析処理 (MemberMacro と同様) ---
        var overrideValues: [String: ExprSyntax] = [:]
        if let arguments = node.arguments?.as(LabeledExprListSyntax.self),
           let overridesArgument = arguments.first(where: { $0.label?.text == "overrides" })
        {
            if let dictionaryExpr = overridesArgument.expression.as(DictionaryExprSyntax.self) {
                if let elements = dictionaryExpr.content.as(DictionaryElementListSyntax.self) {
                    for element in elements {
                        guard let keyExpr = element.key.as(StringLiteralExprSyntax.self),
                              let typeName = keyExpr.segments.first?.as(StringSegmentSyntax.self)?.content.text
                        else {
                            let diagnostic = Diagnostic(
                                node: Syntax(element.key),
                                message: SimpleDiagnosticMessage.invalidOverrideKey
                            )
                            context.diagnose(diagnostic)
                            continue
                        }
                        let valueExpr = element.value
                        overrideValues[typeName] = valueExpr
                    }
                }
            } else if !overridesArgument.expression.is(NilLiteralExprSyntax.self) {
                let diagnostic = Diagnostic(
                    node: Syntax(overridesArgument.expression),
                    message: SimpleDiagnosticMessage.invalidOverrideArgument
                )
                context.diagnose(diagnostic)
            }
        }
        // --- 引数解析処理 ここまで ---

        // プロトコル宣言の取得
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            let diagnostic = Diagnostic(node: Syntax(declaration), message: SimpleDiagnosticMessage.notAProtocol)
            context.diagnose(diagnostic)
            return []
        }

        // No-op メンバー生成 (generateNoopMembers 呼び出し)
        let (noopMembers, accessModifier) = try generateNoopMembers(
            for: protocolDecl,
            overrides: overrideValues,
            in: context
        )

        let protocolName = protocolDecl.name.text
        let noopClassName = "Noop" + protocolName

        // No-op クラス宣言の生成 (final, プロトコル継承)
        let classDecl = ClassDeclSyntax(
            modifiers: [accessModifier, DeclModifierSyntax(name: .keyword(.final))],
            name: TokenSyntax.identifier(noopClassName),
            inheritanceClause: InheritanceClauseSyntax {
                InheritedTypeSyntax(type: TypeSyntax(stringLiteral: protocolName))
            }
        ) {
            for member in noopMembers {
                member
            }
        }

        // 生成されたクラス宣言の先頭に空行を1つ追加 (改行2つ)
        let finalClassDecl = classDecl.with(\.leadingTrivia, .newlines(2))

        return [DeclSyntax(finalClassDecl)]
    }

    private static func generateNoopMembers(
        for protocolDecl: ProtocolDeclSyntax,
        overrides: [String: ExprSyntax],
        in context: some MacroExpansionContext
    ) throws -> (members: [DeclSyntax], accessModifier: DeclModifierSyntax) {
        // アクセス修飾子の決定
        let protocolAccessModifier = protocolDecl.modifiers.first(where: { [
            .keyword(.public),
            .keyword(.internal),
            .keyword(.fileprivate),
            .keyword(.private),
        ].contains($0.name.tokenKind) }) ?? DeclModifierSyntax(name: .keyword(.internal))

        let members = protocolDecl.memberBlock.members
        var noopMembers: [DeclSyntax] = []

        for member in members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                noopMembers.append(Self.generateNoopFunction(
                    from: funcDecl,
                    accessModifier: protocolAccessModifier,
                    overrides: overrides,
                    in: context
                ))
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                noopMembers.append(contentsOf: Self.generateNoopProperty(
                    from: varDecl,
                    accessModifier: protocolAccessModifier,
                    overrides: overrides,
                    in: context
                ))
            }
        }

        noopMembers.append(DeclSyntax("\(raw: protocolAccessModifier.name.text) init() {}"))

        return (noopMembers, protocolAccessModifier)
    }

    /// No-op 関数実装を生成
    private static func generateNoopFunction(
        from funcDecl: FunctionDeclSyntax,
        accessModifier: DeclModifierSyntax,
        overrides: [String: ExprSyntax],
        in context: some MacroExpansionContext
    ) -> DeclSyntax {
        var newFunc = funcDecl
        newFunc.leadingTrivia = []
        newFunc.trailingTrivia = []
        newFunc.funcKeyword = newFunc.funcKeyword.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
        newFunc.name = newFunc.name.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
        newFunc.signature.parameterClause = newFunc.signature.parameterClause.with(\.leadingTrivia, []).with(
            \.trailingTrivia,
            []
        )
        if var returnClause = newFunc.signature.returnClause {
            returnClause.arrow = returnClause.arrow.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
            returnClause.type = returnClause.type.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
            newFunc.signature.returnClause = returnClause
        }
        newFunc.signature.effectSpecifiers = funcDecl.signature.effectSpecifiers
        newFunc.modifiers = [accessModifier]
        newFunc.genericWhereClause = nil
        newFunc.genericParameterClause = nil
        let cleanedParameters = funcDecl.signature.parameterClause.parameters.map { param in
            var newParam = param
            newParam.attributes = []
            newParam.leadingTrivia = []
            newParam.trailingTrivia = []
            newParam.firstName.leadingTrivia = []
            newParam.firstName.trailingTrivia = []
            if var secondName = newParam.secondName {
                secondName.leadingTrivia = []
                secondName.trailingTrivia = []
                newParam.secondName = secondName
            }
            if var paramType = newParam.type.as(AttributedTypeSyntax.self) {
                paramType.baseType = paramType.baseType.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
                newParam.type = TypeSyntax(paramType.baseType)
            } else {
                newParam.type = newParam.type.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
            }
            return newParam
        }
        newFunc.signature.parameterClause.parameters = FunctionParameterListSyntax(cleanedParameters)

        if let returnClause = funcDecl.signature.returnClause {
            let returnType = returnClause.type.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
            let returnTypeName = returnType.trimmedDescription

            let bodyExpr: ExprSyntax
            var shouldReturn = true

            if let customDefaultExpr = overrides[returnTypeName] {
                bodyExpr = customDefaultExpr
            } else {
                if let defaultExpr = DefaultValueGenerator.generateSyntax(for: returnType) {
                    bodyExpr = defaultExpr
                } else {
                    let diagnostic = Diagnostic(
                        node: Syntax(returnType),
                        message: SimpleDiagnosticMessage.fatalErrorDefaultValue(typeName: returnTypeName)
                    )
                    context.diagnose(diagnostic)

                    if funcDecl.signature.effectSpecifiers?.throwsSpecifier != nil {
                        let typeNameForError = returnTypeName.replacingOccurrences(of: "\"", with: "\\\"")
                        bodyExpr =
                            ExprSyntax(
                                stringLiteral: "throw NoopError.defaultValueUnavailable(typeName: \"\(typeNameForError)\")"
                            )
                        shouldReturn = false
                    } else {
                        bodyExpr =
                            ExprSyntax(
                                stringLiteral: "fatalError(\"Cannot generate default value for type '\(returnTypeName)'\")"
                            )
                        shouldReturn = false
                    }
                }
            }

            if shouldReturn {
                newFunc.body = CodeBlockSyntax {
                    let returnKeyword = TokenSyntax.keyword(.return, trailingTrivia: .spaces(1))
                    ReturnStmtSyntax(returnKeyword: returnKeyword, expression: bodyExpr)
                }
            } else {
                newFunc.body = CodeBlockSyntax { bodyExpr }
            }
        } else {
            newFunc.body = CodeBlockSyntax {}
        }

        return DeclSyntax(newFunc)
    }

    /// No-op プロパティ実装を生成
    private static func generateNoopProperty(
        from varDecl: VariableDeclSyntax,
        accessModifier: DeclModifierSyntax,
        overrides: [String: ExprSyntax],
        in context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        var generatedProperties: [DeclSyntax] = []

        for binding in varDecl.bindings {
            var cleanBinding = binding
            cleanBinding.leadingTrivia = []
            cleanBinding.trailingTrivia = []
            if var pat = cleanBinding.pattern.as(IdentifierPatternSyntax.self) {
                pat.identifier = pat.identifier.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
                cleanBinding.pattern = PatternSyntax(pat)
            }
            if var ta = cleanBinding.typeAnnotation {
                ta.colon = ta.colon.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
                ta.type = ta.type.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
                cleanBinding.typeAnnotation = ta
            }
            cleanBinding.initializer = nil
            cleanBinding.accessorBlock = nil

            guard let pattern = cleanBinding.pattern.as(IdentifierPatternSyntax.self),
                  let typeAnnotation = cleanBinding.typeAnnotation
            else {
                context.diagnose(Diagnostic(
                    node: Syntax(binding),
                    message: SimpleDiagnosticMessage.other("Could not parse property binding")
                ))
                continue
            }

            _ = pattern.identifier
            let varType = typeAnnotation.type
            let varTypeName = varType.trimmedDescription

            let getterBodyExpr: ExprSyntax
            var getterShouldReturn = true

            if let customDefaultExpr = overrides[varTypeName] {
                getterBodyExpr = customDefaultExpr
            } else {
                if let defaultExpr = DefaultValueGenerator.generateSyntax(for: varType) {
                    getterBodyExpr = defaultExpr
                } else {
                    let diagnostic = Diagnostic(
                        node: Syntax(varType),
                        message: SimpleDiagnosticMessage.fatalErrorDefaultValue(typeName: varTypeName)
                    )
                    context.diagnose(diagnostic)
                    getterBodyExpr =
                        ExprSyntax(
                            stringLiteral: "fatalError(\"Cannot generate default value for type '\(varTypeName)'\")"
                        )
                    getterShouldReturn = false
                }
            }

            let getterBody = if getterShouldReturn {
                CodeBlockSyntax {
                    let returnKeyword = TokenSyntax.keyword(.return, trailingTrivia: .spaces(1))
                    ReturnStmtSyntax(returnKeyword: returnKeyword, expression: getterBodyExpr)
                }
            } else {
                CodeBlockSyntax { getterBodyExpr }
            }

            let getter = AccessorDeclSyntax(
                accessorSpecifier: .keyword(.get),
                body: getterBody
            )

            cleanBinding.accessorBlock = AccessorBlockSyntax(accessors: .accessors([getter]))

            let newVar = VariableDeclSyntax(
                leadingTrivia: [],
                modifiers: [accessModifier],
                bindingSpecifier: varDecl.bindingSpecifier.with(\.leadingTrivia, [])
            ) {
                cleanBinding
            }

            generatedProperties.append(DeclSyntax(newVar))
        }

        return generatedProperties
    }
}
