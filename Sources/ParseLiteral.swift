import Runes
import TryParsec


// Literal expressions

let exprNilLiteral = _exprNilLiteral()
func _exprNilLiteral() -> SwiftParser<NilLiteral> {
    return { _ in NilLiteral() } <^> kw_nil
}

let exprBooleanLiteral = _exprBooleanLiteral()
func _exprBooleanLiteral() -> SwiftParser<BooleanLiteral> {
    return ({ _ in BooleanLiteral(value: false) } <^> kw_false)
        <|> ({ _ in BooleanLiteral(value: true) } <^> kw_true)
}

let exprStringLiteral = _exprStringLiteral()
func _exprStringLiteral() -> SwiftParser<StringLiteral> {
    return { tok in
        let str = String(tok.text.unicodeScalars.dropFirst().dropLast())
        return StringLiteral(value: str) }
        <^> tok(.string_literal)
}

let exprIntegerLiteral = _exprIntegerLiteral()
func _exprIntegerLiteral() -> SwiftParser<IntegerLiteral> {
    return { tok in
        let digits = stringRemovingUnderscore(ptr: tok.start, length: tok.length)
        return IntegerLiteral(digits: digits) }
        <^> tok(.integer_literal)
}

let exprFloatLiteral = _exprFloatLiteral()
func _exprFloatLiteral() -> SwiftParser<FloatingPointLiteral> {
    return { tok in
        let digits = stringRemovingUnderscore(ptr: tok.start, length: tok.length)
        return FloatingPointLiteral(digits: digits) }
        <^> tok(.float_literal)
}

let exprArrayLiteral = _exprArrayLiteral()
func _exprArrayLiteral() -> SwiftParser<ArrayLiteral> {
    return { elements in ArrayLiteral(value: elements) }
        <^> list(l_square, expr, comma, r_square)
}

let exprDictionaryLiteral = _exprDictionaryLiteral()
func _exprDictionaryLiteral() -> SwiftParser<DictionaryLiteral> {
    let item = { key in { val in (key, val) }}
        <^> expr <* colon <*> expr
    let items = sepBy1(item, comma)
        <|> (colon <&> { _ in [/* empty */] })
    return { items in DictionaryLiteral(value: items) }
        <^> l_square *> items <* r_square
}
