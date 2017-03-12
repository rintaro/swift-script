import Runes
import TryParsec


fileprivate func asExpr(expr: Expression) -> Expression {
    return expr
}

let expr = _expr(isBasic: false)
let exprBasic = _expr(isBasic: true)

func _expr(isBasic: Bool) -> SwiftParser<Expression> {
    return exprSequence(isBasic: isBasic)
}

func exprSequence(isBasic: Bool) -> SwiftParser<Expression> {
    return exprSequenceElement(isBasic: isBasic)
            >>- { lhs in binarySuffix(lhs: lhs, isBasic: isBasic) }
}

let binOp = tok(.oper_binary_spaced)
    <|> tok(.oper_binary_unspaced)
    <|> kw_as
    <|> kw_is
    <|> equal

func binarySuffix(lhs: Expression, isBasic: Bool) -> SwiftParser<Expression> {
    let bin: SwiftParser<Expression> = { op in { rhs in
        BinaryOperation(leftOperand: lhs, operatorSymbol: op.text, rightOperand: rhs) }}
        <^> binOp <*> _expr(isBasic: isBasic)
    return (bin >>- { lhs in binarySuffix(lhs: lhs, isBasic: isBasic) })
        <|> pure(lhs)
}

func exprSequenceElement(isBasic: Bool) -> SwiftParser<Expression> {
    let parseTry
        = ({ _ in "try!" } <^> kw_try *> tok(.exclaim_postfix))
            <|> ({ _ in "try?" } <^> kw_try *> tok(.question_postfix))
            <|> ({ _ in "try" } <^> kw_try)
            <|> pure(nil)
    return { op in { subExpr in
        op != nil ? PrefixUnaryOperation(operatorSymbol: op!, operand: subExpr) : subExpr }}
        <^> parseTry
        <*> exprUnary(isBasic: isBasic)
}

func exprUnary(isBasic: Bool) -> SwiftParser<Expression> {
    return { op in { subExpr in
        op != nil ? PrefixUnaryOperation(operatorSymbol: op!.text, operand: subExpr) : subExpr }}
        <^> zeroOrOne(tok(.oper_prefix))
        <*> exprAtom(isBasic: isBasic)
}

func exprAtom(isBasic: Bool) -> SwiftParser<Expression> {
    return exprPrimitive >>- exprSuffix(isBasic: isBasic)
}

//-----------------------------------------------------------------------
// primitive expressions

let exprPrimitive = _exprPrimitive()
func _exprPrimitive() -> SwiftParser<Expression> {
    return (exprStringLiteral <&> asExpr)
        <|> (exprFloatLiteral <&> asExpr)
        <|> (exprIntegerLiteral <&> asExpr)
        <|> (exprNilLiteral <&> asExpr)
        <|> (exprArrayLiteral <&> asExpr)
        <|> (exprDictionaryLiteral <&> asExpr)
        <|> (exprIdentifier <&> asExpr)
        <|> (exprSelf <&> asExpr)
        <|> (exprSuper <&> asExpr)
        <|> (exprTuple <&> asExpr)
        <|> (exprImplicitMember <&> asExpr)
        <|> (exprWildcard <&> asExpr)
        <|> (exprClosure <&> asExpr)
}

let genericArgs = _genericArgs()
func _genericArgs() -> SwiftParser<[Type_]> {
    return list(l_angle, type, comma, r_angle)
}

let exprIdentifier = _exprIdentifier()
func _exprIdentifier() -> SwiftParser<IdentifierExpression> {
    return { ident in { generics in
        IdentifierExpression(identifier: ident) }}
        <^> (identifier <|> dollarIdentifier)
        <*> zeroOrOne(genericArgs)
}

let exprSelf = _exprSelf()
func _exprSelf() -> SwiftParser<SelfExpression>  {
    return { _ in SelfExpression() } <^> kw_self
}

let exprSuper = _exprSuper()
func _exprSuper() -> SwiftParser<SuperclassExpression>  {
    return { _ in SuperclassExpression() } <^> kw_super
}

let exprClosure = _exprClosure()
func _exprClosure() -> SwiftParser<ClosureExpression>  {
    typealias Param = (String, Type_?)
    let name: SwiftParser<String> = (identifier <|> (kw__ <&> { _ in "" }))
    let nameParam: SwiftParser<Param> = name <&> { name in (name, nil) }
    let paramsName: SwiftParser<[Param]> = sepBy1(nameParam, comma)
    let paramsNameTuple: SwiftParser<[Param]> = list(l_paren, nameParam, comma, r_paren)

    let typedName: SwiftParser<Param> = { name in { ty in (name, ty) }} <^> name <*> (colon *> type)
    let paramsTyped: SwiftParser<[Param]> = list(l_paren, typedName, comma, r_paren)

    let sig = { args in { th in { ty in (args: args, hasThrows: th != nil, result: ty) }}}
        <^> (paramsName <|> paramsNameTuple <|> paramsTyped)
        <*> zeroOrOne(kw_throws)
        <*> zeroOrOne(arrow *> type)
        <* kw_in
    
    return { sig in { body in
        ClosureExpression(
            arguments: sig?.args ?? [],
            hasThrows: sig?.hasThrows ?? false,
            result: sig?.result,
            statements: body) }}
        <^> l_brace
        *> zeroOrOne(sig)
        <*> stmtBraceItems
        <* r_brace
}

let exprTuple = _exprTuple()
func _exprTuple() -> SwiftParser<Expression>  {
    let element = { label in { value in (label, value) }}
        <^> zeroOrOne(keywordOrIdentifier <* colon)
        <*> expr
    
    return { elements in
        if elements.count == 1  && elements[0].0 == nil {
            return ParenthesizedExpression(expression: elements[0].1)
        } else {
            return TupleExpression(elements: elements)
        }}
        <^> list(l_paren, element, comma, r_paren)
 }

let exprImplicitMember = _exprImplicitMember()
func _exprImplicitMember() -> SwiftParser<ImplicitMemberExpression>  {
    return { ident in ImplicitMemberExpression() }
        <^> (period *> identifier)
}


let exprWildcard = _exprWildcard()
func _exprWildcard() -> SwiftParser<WildcardExpression> {
    return { _ in WildcardExpression() }
        <^> kw__
}

//-----------------------------------------------------------------------
// suffix expressions

func exprSuffix(isBasic: Bool) -> (Expression) -> SwiftParser<Expression> {
    return { subj in exprSuffix(subj: subj, isBasic: isBasic) }
}

func exprSuffix(subj: Expression, isBasic: Bool) -> SwiftParser<Expression> {
    var parser = (_exprPostfixSelf(subj) >>- exprSuffix(isBasic: isBasic))
        <|> (_exprInitializer(subj) >>- exprSuffix(isBasic: isBasic))
        <|> (_exprExplicitMember(subj) >>- exprSuffix(isBasic: isBasic))
        <|> (_exprFunctionCall(subj) >>- exprSuffix(isBasic: isBasic))
        <|> (_exprSubscript(subj) >>- exprSuffix(isBasic: isBasic))
        <|> (_exprOptionalChaining(subj) >>- exprSuffix(isBasic: isBasic))
        <|> (_exprPostfixUnary(subj) >>- exprSuffix(isBasic: isBasic))
    if !isBasic {
        parser = parser
            <|> (_exprTrailingClosure(subj) >>- exprSuffix(isBasic: isBasic))
    }
    return parser <|> pure(subj)
}

func _exprPostfixSelf(_ subj: Expression) -> SwiftParser<PostfixSelfExpression>  {
    return { _ in PostfixSelfExpression() }
        <^> period *> kw_self
}

func _exprFunctionCall(_ subj: Expression) -> SwiftParser<FunctionCallExpression> {
    let arg = { label in { value in (label, value) }}
        <^> zeroOrOne(keywordOrIdentifier <* colon) <*> expr
    return { args in { trailingClosure in
        FunctionCallExpression(expression: subj, arguments: args, trailingClosure: trailingClosure) }}
        <^> (peek({ !$0.isAtStartOfLine }) *> list(l_paren, arg, comma, r_paren))
        <*> zeroOrOne(exprClosure)
}

func _exprTrailingClosure(_ subj: Expression) -> SwiftParser<FunctionCallExpression> {
    return { trailingClosure in
        FunctionCallExpression(expression: subj, arguments: [], trailingClosure: trailingClosure) }
        <^> exprClosure
}

func _exprInitializer(_ subj: Expression) -> SwiftParser<InitializerExpression> {
    return { _ in InitializerExpression() }
        <^> period *> kw_init
}


func _exprExplicitMember(_ subj: Expression) -> SwiftParser<ExplicitMemberExpression> {
    return { name in { generics in
        ExplicitMemberExpression(expression: subj, member: name) }}
        <^> period *> keywordOrIdentifier
        <*> zeroOrOne(genericArgs)
}


func _exprSubscript(_ subj: Expression) -> SwiftParser<SubscriptExpression> {
    return { args in
        SubscriptExpression(expression: subj, arguments: args) }
        <^> (peek({ !$0.isAtStartOfLine }) *> list(l_square, expr, comma, r_square))
}

func _exprOptionalChaining(_ subj: Expression) -> SwiftParser<OptionalChainingExpression> {
    return { name in { generics in
        OptionalChainingExpression(expression: subj, member: name) }}
        <^> tok(.question_postfix) *> period *> keywordOrIdentifier
        <*> zeroOrOne(genericArgs)
}

func _exprDynamicType(_ subj: Expression) -> SwiftParser<DynamicTypeExpression> {
    return fail("not implemented")
}

func _exprPostfixUnary(_ subj: Expression) -> SwiftParser<PostfixUnaryOperation> {
    return
        { tok in PostfixUnaryOperation(operand: subj, operatorSymbol: tok.text) }
        <^> (tok(.oper_postfix) <|> tok(.exclaim_postfix) <|> tok(.question_postfix))
}
