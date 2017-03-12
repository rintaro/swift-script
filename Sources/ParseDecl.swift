import Runes
import TryParsec


fileprivate func asDecl(_ decl: Declaration) -> Declaration {
    return decl
}


let decl = _decl()
func _decl() -> SwiftParser<Declaration> {
    return (declFunction <&> asDecl)
        <|> (declConstant <&> asDecl)
        <|> (declVariable <&> asDecl)
        <|> (declClass <&> asDecl)
        <|> (declInitializer <&> asDecl)
}

func _declImport() -> SwiftParser<ImportDeclaration> {
    return fail("not implemented")
}

let declConstant = _declConstant()
func _declConstant() -> SwiftParser<ConstantDeclaration> {
    return { isStatic in {  name in { ty in { initializer in
        ConstantDeclaration(isStatic: isStatic != nil, name: name, type: ty, expression: initializer) }}}}
        <^> zeroOrOne(kw_static)
        <*> (kw_let *> identifier)
        <*> zeroOrOne(colon *> type)
        <*> zeroOrOne(equal *> expr)
}


let declVariable = _declVariable()
func _declVariable() -> SwiftParser<VariableDeclaration> {
    return { isStatic in {  name in { ty in { initializer in
        VariableDeclaration(isStatic: isStatic != nil, name: name, type: ty, expression: initializer) }}}}
        <^> zeroOrOne(kw_static)
        <*> (kw_var *> identifier)
        <*> zeroOrOne(colon *> type)
        <*> zeroOrOne(equal *> expr)
}

func _declTypeAlias() -> SwiftParser<TypeAliasDeclaration> {
    return fail("not implemented")
}

let declParam = _declParam()
func _declParam() -> SwiftParser<Parameter> {
    let label = (identifier <|> (kw__ <&> { _ in  "" }))
    return { apiName in { paramName in { ty in { isVariadic in { defaultValue in
        Parameter(externalParameterName: apiName, localParameterName: paramName, type: ty, defaultArgument: defaultValue) }}}}}
        <^> zeroOrOne(label <* lookAhead(label))
        <*> label
        <*> (colon *> type)
        <*> zeroOrOne(ellipsis)
        <*> zeroOrOne(equal *> expr)
}


fileprivate struct GenericParam {
    var param: String
    var requirement: Type_?
}

fileprivate struct GenericRequirement {
    enum Kind {
        case inherit
        case equals
    }
    var param: String
    var kind: Kind
    var requirement: Type_
}

fileprivate let declGenericParams = _declGenericParams()
fileprivate func _declGenericParams() -> SwiftParser<[GenericParam]> {
    let param: SwiftParser<GenericParam> = { ident in { ty in GenericParam(param: ident, requirement: ty) }}
        <^> identifier <*> zeroOrOne(colon *> type)
    return list(l_angle, param, comma, r_angle)
}


fileprivate let declGenericWhere = _declGenericWhere()
fileprivate func _declGenericWhere() -> SwiftParser<[GenericRequirement]> {
    let inheritR: SwiftParser<(GenericRequirement.Kind, Type_)> = (colon *> type) <&> { ty in (.inherit, ty) }
    let equalR: SwiftParser<(GenericRequirement.Kind, Type_)> = (oper_infix("==") *> type) <&> { ty in (.equals, ty) }
    let requirement: SwiftParser<GenericRequirement> = { ident in { req in GenericRequirement(param: ident, kind: req.0, requirement: req.1) }}
        <^> identifier <*> (inheritR <|> equalR)
    return (kw_where *> sepBy1(requirement, comma))
}

let declFunction = _declFunction()
func _declFunction() -> SwiftParser<FunctionDeclaration> {
    
    struct FuncSignature {
        let params: [Parameter]
        let hasThrows: Bool
        let retType: Type_?
    }
    let signature: SwiftParser<FuncSignature> = { params in { hasThrows in { retType in
        FuncSignature(params: params, hasThrows: hasThrows != nil, retType: retType) }}}
        <^> list(l_paren, declParam, comma, r_paren)
        <*> zeroOrOne(kw_throws)
        <*> zeroOrOne(arrow *> type)
    
    return  { isStatic in { name in { generics in { signature in { whereClause in { body in
        FunctionDeclaration(
            isStatic: isStatic != nil,
            name: name,
            arguments: signature.params,
            result: signature.retType,
            hasThrows: signature.hasThrows,
            body: body) }}}}}}
        <^> zeroOrOne(kw_static)
        <*> (kw_func *> identifier)
        <*> zeroOrOne(declGenericParams)
        <*> signature
        <*> zeroOrOne(declGenericWhere)
        <*> stmtBrace
}

fileprivate let declMembers = _declMembers();
fileprivate func _declMembers() -> SwiftParser<[Declaration]> {
    return l_brace *> sepEndBy(decl, stmtSep) <* r_brace
}

func _declEnum() -> SwiftParser<EnumDeclaration­> {
    return fail("not implemented")
}

func _declStruct() -> SwiftParser<StructDeclaration­> {
    return fail("not implemented")
}

let declClass = _declClass()
func _declClass() -> SwiftParser<ClassDeclaration­> {
    return { name in { generics in { inherits in { whereClause in { members in
        ClassDeclaration­(name: name, superTypes: inherits ?? [], members: members) }}}}}
        <^> (kw_class *> identifier)
        <*> zeroOrOne(declGenericParams)
        <*> zeroOrOne(colon *> sepBy1(type, comma))
        <*> zeroOrOne(declGenericWhere)
        <*> declMembers
}

func _declProtocol() -> SwiftParser<ProtocolDeclaration­> {
    return fail("not implemented")
}

let declInitializer = _declInitializer()
func _declInitializer() -> SwiftParser<InitializerDeclaration­> {
    struct Signature {
        let generics: [GenericParam]?
        let params: [Parameter]
        let hasThrows: Bool
        let whereClause: [GenericRequirement]?
    }
    
    let signature = { generics in { params in { hasThrows in { whereClause in
        Signature(generics: generics, params: params, hasThrows: hasThrows != nil, whereClause: whereClause) }}}}
        <^> zeroOrOne(declGenericParams)
        <*> list(l_paren, declParam, comma, r_paren)
        <*> zeroOrOne(kw_throws)
        <*> zeroOrOne(declGenericWhere)
    
    return  { isFailable in { signature in { body in
        InitializerDeclaration­(arguments: signature.params, isFailable: isFailable != nil, hasThrows: signature.hasThrows, body: body) }}}
        <^> (kw_init *> zeroOrOne(tok(.question_postfix)))
        <*> signature
        <*> stmtBrace
}

func _declDeinitializer() -> SwiftParser<DeinitializerDeclaration­> {
    return fail("not implemented")
}

func _declExtension() -> SwiftParser<ExtensionDeclaration­> {
    return fail("not implemented")
}
