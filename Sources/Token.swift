#if os(macOS)
    import Darwin
#else
    import Glibc
#endif

struct Token {
    enum Kind {
        // Punctuator.
        case l_brace // '{'
        case r_brace // '}'
        case l_square // '['
        case r_square // ']'
        case l_paren // '('
        case r_paren // ')'
        case l_angle // '<'
        case r_angle // '>'
        case period // '.'
        case comma // ','
        case colon // ':'
        case semi // ';'
        case equal // '='
        case at_sign // '@'
        case amp_prefix // '&'
        case arrow // '->'
        case question_postfix // '?'
        case question_infix // '?'
        case exclaim_postfix // '!'
        
        // Operator.
        case oper_prefix
        case oper_postfix
        case oper_binary_spaced
        case oper_binary_unspaced
        
        // Literal.
        case integer_literal
        case string_literal
        case float_literal
        
        // Identifier.
        case dollarident
        case identifier
        
        // Keyword.
        case kw_associatedtype
        case kw_class
        case kw_deinit
        case kw_enum
        case kw_extension
        case kw_func
        case kw_import
        case kw_init
        case kw_inout
        case kw_let
        case kw_operator
        case kw_precedencegroup
        case kw_protocol
        case kw_struct
        case kw_subscript
        case kw_typealias
        case kw_var
        case kw_fileprivate
        case kw_internal
        case kw_private
        case kw_public
        case kw_static
        case kw_defer
        case kw_if
        case kw_guard
        case kw_do
        case kw_repeat
        case kw_else
        case kw_for
        case kw_in
        case kw_while
        case kw_return
        case kw_break
        case kw_continue
        case kw_fallthrough
        case kw_switch
        case kw_case
        case kw_default
        case kw_where
        case kw_catch
        case kw_as
        case kw_Any
        case kw_false
        case kw_is
        case kw_nil
        case kw_rethrows
        case kw_super
        case kw_self
        case kw_Self
        case kw_throw
        case kw_true
        case kw_try
        case kw_throws
        case kw__

        // Special.
        case eof
        case unknown
        case NOT_A_TOKEN
    }
    
    var start: SrcPointer
    var length: Int
    var kind: Kind
    var isAtStartOfLine: Bool
    var isEscapedIdentifier: Bool
    
    init(init start: SrcPointer) {
        self.start = start
        self.length = 0
        self.kind = .NOT_A_TOKEN
        self.isAtStartOfLine = false
        self.isEscapedIdentifier = false
    }
}

extension Token {
    var rawText: String {
        return UTF8ChunkRef(start: start, length: length).text
    }
    
    var text: String {
        if isEscapedIdentifier {
            return UTF8ChunkRef(start: start + 1, length: length - 2).text
        } else {
            return UTF8ChunkRef(start: start, length: length).text
        }
    }

    func `is`(_ kind: Kind) -> Bool {
        return self.kind == kind
    }

    func `is`(_ kinds: Kind...) -> Bool {
        return kinds.contains(kind)
    }

    var isFollowingLParen: Bool {
        return !isAtStartOfLine && kind == .l_paren
    }

    var isFollowingLSquare: Bool {
        return !isAtStartOfLine && kind == .l_square
    }

    var isLiteral: Bool {
        switch kind {
        case .string_literal, .float_literal, .integer_literal:
            return true
        default:
            return false
        }
    }

    var isBinaryOperator: Bool {
        return kind == .oper_binary_spaced || kind == .oper_binary_unspaced
    }

    var isAnyOperator: Bool {
        return isBinaryOperator || kind == .oper_prefix || kind == .oper_postfix
    }
    
    var isEllipsis: Bool {
        return isAnyOperator && textEquals("...")
    }
    
    func textEquals(_ str: StaticString) -> Bool {
        return str.utf8CodeUnitCount == length
            && 0 == memcmp(start, str.utf8Start, length)
    }
    
    func isBinaryOperator(_ str: StaticString) -> Bool {
        return isBinaryOperator && textEquals(str)
    }
    
    func isContextualKeyword(_ str: StaticString) -> Bool {
        return kind == .identifier && !isEscapedIdentifier && textEquals(str)
    }
    
    var startWithLess: Bool {
        return isAnyOperator && start.pointee == ascii8("<")
    }
    
    var startWithGreater: Bool {
        return isAnyOperator && start.pointee == ascii8(">")
    }
    
    var isKeyword: Bool {
        switch kind {
        case .kw_associatedtype,
             .kw_class,
             .kw_deinit,
             .kw_enum,
             .kw_extension,
             .kw_func,
             .kw_import,
             .kw_init,
             .kw_inout,
             .kw_let,
             .kw_operator,
             .kw_precedencegroup,
             .kw_protocol,
             .kw_struct,
             .kw_subscript,
             .kw_typealias,
             .kw_var,
             .kw_fileprivate,
             .kw_internal,
             .kw_private,
             .kw_public,
             .kw_static,
             .kw_defer,
             .kw_if,
             .kw_guard,
             .kw_do,
             .kw_repeat,
             .kw_else,
             .kw_for,
             .kw_in,
             .kw_while,
             .kw_return,
             .kw_break,
             .kw_continue,
             .kw_fallthrough,
             .kw_switch,
             .kw_case,
             .kw_default,
             .kw_where,
             .kw_catch,
             .kw_as,
             .kw_Any,
             .kw_false,
             .kw_is,
             .kw_nil,
             .kw_rethrows,
             .kw_super,
             .kw_self,
             .kw_Self,
             .kw_throw,
             .kw_true,
             .kw_try,
             .kw_throws,
             .kw__:
            return true
        default:
            return false
        }
    }
}
