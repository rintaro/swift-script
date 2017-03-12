import Runes
import TryParsec

func tok(_ kind: Token.Kind) -> SwiftParser<Token> {
    return Parser { input in
        var input = input
        
        if input.token.is(kind) {
            let tok = input.token
            input.consume()
            return .done(input, tok)
        } else {
            return .fail(input, [], "")
        }
    }
}

func tok(_ predicate: @escaping (Token) -> Bool) -> SwiftParser<Token> {
    return Parser { input in
        var input = input
        
        if predicate(input.token) {
            let tok = input.token
            input.consume()
            return .done(input, tok)
        } else {
            return .fail(input, [], "")
        }
    }
}

func peek(_ predicate: @escaping (Token) -> Bool) -> SwiftParser<()> {
    return Parser { input in
        if predicate(input.token) {
            return .done(input, ())
        } else {
            return .fail(input, [], "")
        }
    }
}


// ------------------------------------------------------------------------
// Panctuators

let l_paren = tok(.l_paren)
let r_paren = tok(.r_paren)
let l_brace = tok(.l_brace)
let r_brace = tok(.r_brace)
let l_square = tok(.l_square)
let r_square = tok(.r_square)
let colon = tok(.colon)
let semi = tok(.semi)
let period = tok(.period)
let comma = tok(.comma)
let arrow = tok(.arrow)
let ellipsis = tok({ $0.isEllipsis })
let equal = tok(.equal)

let l_angle = _l_angle()
func _l_angle() -> SwiftParser<Token> {
    return SwiftParser<Token> { input in
        var input = input
        var tok = input.token
        if tok.startWithLess {
            tok.kind = .l_angle
            if tok.length != 1 {
                tok.length = 1
                input.reset(ptr: tok.start + 1)
            } else {
                input.consume()
            }
            return .done(input, tok)
        } else {
            return .fail(input, [], "l_angle")
        }
    }
}

let r_angle = _r_angle()
func _r_angle() -> SwiftParser<Token> {
    return SwiftParser<Token> { input in
        var input = input
        var tok = input.token
        if tok.startWithGreater {
            tok.kind = .r_angle
            if tok.length != 1 {
                tok.length = 1
                input.reset(ptr: tok.start + 1)
            } else {
                input.consume()
            }
            return .done(input, tok)
        } else {
            return .fail(input, [], "r_angle")
        }
    }
}

func oper_infix(_ str: StaticString) -> SwiftParser<Token> {
    return Parser { input in
        var input = input
        let tok = input.token
        if tok.isBinaryOperator(str) {
            input.consume()
            return .done(input, tok)
        } else {
            return .fail(input, [], "oper_infix")
        }
    }
}

// ----------------------------------------------------------------------------------
// Identifiers

let identifier = _identifier()
func _identifier() -> SwiftParser<String> {
    return Parser { input in
        var input = input
        let tok = input.token
        
        switch tok.kind {
        case .identifier, .kw_Self:
            input.consume()
            return .done(input, tok.text)
        default:
            return .fail(input, [], "")
        }
    }
}

let dollarIdentifier = _dollarIdentifier()
func _dollarIdentifier() -> SwiftParser<String> {
    return Parser { input in
        var input = input
        let tok = input.token
        switch tok.kind {
        case .dollarident:
            input.consume()
            return .done(input, tok.text)
        default:
            return .fail(input, [], "")
        }
    }
}

let anyIdentifier = _anyIdentifier()
func _anyIdentifier() -> SwiftParser<String> {
    return Parser { input in
        var input = input
        
        let tok = input.token
        if tok.is(.identifier) || tok.isAnyOperator {
            input.consume()
            return .done(input, tok.text)
        } else {
            return .fail(input, [], "")
        }
    }
}

func contextualKeyword(str: StaticString) -> SwiftParser<String> {
    return Parser { input in
        var input = input
        let tok = input.token
        if tok.isContextualKeyword(str) {
            input.consume()
            return .done(input, tok.text)
        } else {
            return .fail(input, [], "")
        }
    }
}

let keywordOrIdentifier = _keywordOrIdentifier()
func _keywordOrIdentifier() -> SwiftParser<String> {
    return Parser { input in
        var input = input
        let tok = input.token
        if tok.is(.identifier) || tok.isKeyword {
            input.consume()
            return .done(input, tok.text)
        } else {
            return .fail(input, [], "")
        }
    }
}

// ----------------------------------------------------------------------------------
// Keywords


let kw_associatedtype = tok(.kw_associatedtype)
let kw_class = tok(.kw_class)
let kw_deinit = tok(.kw_deinit)
let kw_enum = tok(.kw_enum)
let kw_extension = tok(.kw_extension)
let kw_func = tok(.kw_func)
let kw_import = tok(.kw_import)
let kw_init = tok(.kw_init)
let kw_inout = tok(.kw_inout)
let kw_let = tok(.kw_let)
let kw_operator = tok(.kw_operator)
let kw_precedencegroup = tok(.kw_precedencegroup)
let kw_protocol = tok(.kw_protocol)
let kw_struct = tok(.kw_struct)
let kw_subscript = tok(.kw_subscript)
let kw_typealias = tok(.kw_typealias)
let kw_var = tok(.kw_var)

let kw_fileprivate = tok(.kw_fileprivate)
let kw_internal = tok(.kw_internal)
let kw_private = tok(.kw_private)
let kw_public = tok(.kw_public)
let kw_static = tok(.kw_static)

let kw_defer = tok(.kw_defer)
let kw_if = tok(.kw_if)
let kw_guard = tok(.kw_guard)
let kw_do = tok(.kw_do)
let kw_repeat = tok(.kw_repeat)
let kw_else = tok(.kw_else)
let kw_for = tok(.kw_for)
let kw_in = tok(.kw_in)
let kw_while = tok(.kw_while)
let kw_return = tok(.kw_return)
let kw_break = tok(.kw_break)
let kw_continue = tok(.kw_continue)
let kw_fallthrough = tok(.kw_fallthrough)
let kw_switch = tok(.kw_switch)
let kw_case = tok(.kw_case)
let kw_default = tok(.kw_default)
let kw_where = tok(.kw_where)
let kw_catch = tok(.kw_catch)

let kw_as = tok(.kw_as)
let kw_Any = tok(.kw_Any)
let kw_false = tok(.kw_false)
let kw_is = tok(.kw_is)
let kw_nil = tok(.kw_nil)
let kw_rethrows = tok(.kw_rethrows)
let kw_super = tok(.kw_super)
let kw_self = tok(.kw_self)
let kw_Self = tok(.kw_Self)
let kw_throw = tok(.kw_throw)
let kw_true = tok(.kw_true)
let kw_try = tok(.kw_try)
let kw_throws = tok(.kw_throws)

let kw__ = tok(.kw__)

// ------------------------------------------------------------------------
// Misc

func not<In, Out>(_ p: Parser<In, Out>) -> Parser<In, Void> {
    return Parser { input in
        let reply = parse(p, input)
        switch reply {
        case .fail:
            return .done(input, ())
        case .done:
            return .fail(input, [], "notFollowedBy")
        }
    }
}

func list<T>(_ tokL: Token.Kind, _ element: SwiftParser<T>, _ tokSep: Token.Kind, _ tokR: Token.Kind) -> SwiftParser<[T]> {
    return tok(tokL) *> sepBy(element, tok(tokSep)) <* tok(tokR)
}

func list<P, T, S>(_ tokL: SwiftParser<P>, _ elem: SwiftParser<T>, _ tokS: SwiftParser<S>, _ tokR: SwiftParser<P>) -> SwiftParser<[T]> {
    return tokL *> sepBy(elem, tokS) <* tokR
}
