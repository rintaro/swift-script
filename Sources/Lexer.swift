#if os(macOS)
    import Darwin
#else
    import Glibc
#endif

func ascii8(_ s: UnicodeScalar) -> UInt8 {
    return UInt8(truncatingBitPattern: s.value)
}

struct UTF8ChunkRef : Sequence {
    var start: SrcPointer
    var length: Int
    init(start: SrcPointer, length: Int) {
        self.start = start
        self.length = length
    }
    
    func makeIterator() -> UTF8Iterator {
        return UTF8Iterator(position: start, end: start + length)
    }
    
    var text: String {
        let tokText = UTF8Iterator(position: start, end: start + length)
        var str = String()
        str.reserveCapacity(length)
        let hasError = transcode(
            tokText,
            from: UTF8.self, to: UTF32.self,
            stoppingOnError: true
        ) {
            str.unicodeScalars.append(UnicodeScalar($0)!)
        }
        assert(!hasError, "invalid UTF8 in UTF8Chunk")
        return str
    }
}

struct UTF8Iterator : IteratorProtocol {
    var position: SrcPointer
    let end: SrcPointer
    
    mutating func next() -> UInt8? {
        if position == end { return nil }
        let result = position.pointee
        position += 1
        return result
    }
}

func stringRemovingUnderscore(ptr: SrcPointer, length: Int) -> String {
    let chunk = UTF8ChunkRef(start: ptr, length: length)
    var str = String()
    str.reserveCapacity(length)
    for c in chunk where c != ascii8("_") {
        str.unicodeScalars.append(UnicodeScalar(c))
    }
    return str
}

private func ~= (pat: StaticString, val: UnsafeBufferPointer<UInt8>) -> Bool {
    return pat.utf8CodeUnitCount == val.count
        && memcmp(pat.utf8Start, val.baseAddress!, val.count) == 0
}

private func getIdentifierTokenKind(_ ptr: SrcPointer, _ length: Int) -> Token.Kind {
    switch UnsafeBufferPointer(start: ptr, count: length) {
    case "associatedtype": return .kw_associatedtype
    case "class": return .kw_class
    case "deinit": return .kw_deinit
    case "enum": return .kw_enum
    case "extension": return .kw_extension
    case "func": return .kw_func
    case "import": return .kw_import
    case "init": return .kw_init
    case "inout": return .kw_inout
    case "let": return .kw_let
    case "operator": return .kw_operator
    case "precedencegroup": return .kw_precedencegroup
    case "protocol": return .kw_protocol
    case "struct": return .kw_struct
    case "subscript": return .kw_subscript
    case "typealias": return .kw_typealias
    case "var": return .kw_var
    case "fileprivate": return .kw_fileprivate
    case "internal": return .kw_internal
    case "private": return .kw_private
    case "public": return .kw_public
    case "static": return .kw_static
    case "defer": return .kw_defer
    case "if": return .kw_if
    case "guard": return .kw_guard
    case "do": return .kw_do
    case "repeat": return .kw_repeat
    case "else": return .kw_else
    case "for": return .kw_for
    case "in": return .kw_in
    case "while": return .kw_while
    case "return": return .kw_return
    case "break": return .kw_break
    case "continue": return .kw_continue
    case "fallthrough": return .kw_fallthrough
    case "switch": return .kw_switch
    case "case": return .kw_case
    case "default": return .kw_default
    case "where": return .kw_where
    case "catch": return .kw_catch
    case "as": return .kw_as
    case "Any": return .kw_Any
    case "false": return .kw_false
    case "is": return .kw_is
    case "nil": return .kw_nil
    case "rethrows": return .kw_rethrows
    case "super": return .kw_super
    case "self": return .kw_self
    case "Self": return .kw_Self
    case "throw": return .kw_throw
    case "true": return .kw_true
    case "try": return .kw_try
    case "throws": return .kw_throws
    case "_": return .kw__
    default: return .identifier
    }
}

private func isDigit(_ c: UInt8) -> Bool {
    return (c >= 0x30 && c <= 0x39) // '0' ... '9'
}

private func isHexDigit(_ c: UInt8) -> Bool {
    return isDigit(c)
        || (c >= 0x41 && c <= 0x46) // 'A' ... 'F'
        || (c >= 0x61 && c <= 0x66) // 'a' ... 'f'
}

private func isValidIdentifierContinuationCodePoint(_ scalar: UnicodeScalar) -> Bool {
    let c = scalar.value
    return (c == 0x5F) // '_'
        || (c >= 0x30 && c <= 0x39) // '0' ... '9'
        || (c >= 0x41 && c <= 0x5A) // 'A' ... 'Z'
        || (c >= 0x61 && c <= 0x7a) // 'a' ... 'z'
        
        || c == 0x00A8 || c == 0x00AA
        || c == 0x00AD || c == 0x00AF
        || (c >= 0x00B2 && c <= 0x00B5)
        || (c >= 0x00B7 && c <= 0x00BA)
        || (c >= 0x00BC && c <= 0x00BE)
        || (c >= 0x00C0 && c <= 0x00D6)
        || (c >= 0x00D8 && c <= 0x00F6)
        || (c >= 0x00F8 && c <= 0x00FF)
        
        || (c >= 0x0100 && c <= 0x167F)
        || (c >= 0x1681 && c <= 0x180D)
        || (c >= 0x180F && c <= 0x1FFF)
        
        || (c >= 0x200B && c <= 0x200D)
        || (c >= 0x202A && c <= 0x202E)
        || (c >= 0x203F && c <= 0x2040)
        || c == 0x2054
        || (c >= 0x2060 && c <= 0x206F)
        
        || (c >= 0x2070 && c <= 0x218F)
        || (c >= 0x2460 && c <= 0x24FF)
        || (c >= 0x2776 && c <= 0x2793)
        || (c >= 0x2C00 && c <= 0x2DFF)
        || (c >= 0x2E80 && c <= 0x2FFF)
        
        || (c >= 0x3004 && c <= 0x3007)
        || (c >= 0x3021 && c <= 0x302F)
        || (c >= 0x3031 && c <= 0x303F)
        
        || (c >= 0x3040 && c <= 0xD7FF)
        
        || (c >= 0xF900 && c <= 0xFD3D)
        || (c >= 0xFD40 && c <= 0xFDCF)
        || (c >= 0xFDF0 && c <= 0xFE44)
        || (c >= 0xFE47 && c <= 0xFFF8)
        
        || (c >= 0x10000 && c <= 0x1FFFD)
        || (c >= 0x20000 && c <= 0x2FFFD)
        || (c >= 0x30000 && c <= 0x3FFFD)
        || (c >= 0x40000 && c <= 0x4FFFD)
        || (c >= 0x50000 && c <= 0x5FFFD)
        || (c >= 0x60000 && c <= 0x6FFFD)
        || (c >= 0x70000 && c <= 0x7FFFD)
        || (c >= 0x80000 && c <= 0x8FFFD)
        || (c >= 0x90000 && c <= 0x9FFFD)
        || (c >= 0xA0000 && c <= 0xAFFFD)
        || (c >= 0xB0000 && c <= 0xBFFFD)
        || (c >= 0xC0000 && c <= 0xCFFFD)
        || (c >= 0xD0000 && c <= 0xDFFFD)
        || (c >= 0xE0000 && c <= 0xEFFFD)

}

private func isValidIdentifierStartCodePoint(_ scalar: UnicodeScalar) -> Bool {
    if !isValidIdentifierContinuationCodePoint(scalar) {
        return false
    }
    let c = scalar.value
    if (c >= 0x30 && c <= 0x39) // '0' ... '9'
        || (c >= 0x0300 && c <= 0x036F)
        || (c >= 0x1DC0 && c <= 0x1DFF)
        || (c >= 0x20D0 && c <= 0x20FF)
        || (c >= 0xFE20 && c <= 0xFE2F) {
        return false
    }
    return true
}

private let knownOperatorChars = Set("/=-+*%<>!&|^~.?".unicodeScalars)
private func isValidOperatorStartCodePoint(_ scalar: UnicodeScalar) -> Bool {
    // ASCII operator chars.
    if knownOperatorChars.contains(scalar) {
        return true
    }
    // Unicode math, symbol, arrow, dingbat, and line/box drawing chars.
    let c = scalar.value
    return (c >= 0x00A1 && c <= 0x00A7)
        || c == 0x00A9 || c == 0x00AB
        || c == 0x00AC || c == 0x00AE
        || c == 0x00B0 || c == 0x00B1
        || c == 0x00B6 || c == 0x00BB
        || c == 0x00BF || c == 0x00D7
        || c == 0x00F7 || c == 0x2016
        || c == 0x2017
        || (c >= 0x2020 && c <= 0x2027)
        || (c >= 0x2030 && c <= 0x203E)
        || (c >= 0x2041 && c <= 0x2053)
        || (c >= 0x2055 && c <= 0x205E)
        || (c >= 0x2190 && c <= 0x23FF)
        || (c >= 0x2500 && c <= 0x2775)
        || (c >= 0x2794 && c <= 0x2BFF)
        || (c >= 0x2E00 && c <= 0x2E7F)
        || (c >= 0x3001 && c <= 0x3003)
        || (c >= 0x3008 && c <= 0x3030)
}

private func isValidOperatorContinuationCodePoint(_ scalar: UnicodeScalar) -> Bool {
    if isValidOperatorStartCodePoint(scalar) {
        return true
    }
    // Unicode combining characters and variation selectors.
    let c = scalar.value
    return (c >= 0x0300 && c <= 0x036F)
        || (c >= 0x1DC0 && c <= 0x1DFF)
        || (c >= 0x20D0 && c <= 0x20FF)
        || (c >= 0xFE00 && c <= 0xFE0F)
        || (c >= 0xFE20 && c <= 0xFE2F)
        || (c >= 0xE0100 && c <= 0xE01EF)
}

private func isLeftBound(_ begin: SrcPointer, _ bufBegin: SrcPointer) -> Bool {
    if begin == bufBegin {
        return false
    }
    
    switch UnicodeScalar(begin[-1]) {
    case " ", "\r", "\n", "\t", "(", "[", "{", ",", ";", ":", "\u{0}":
        return false
    case "/":
        if begin - 1 != bufBegin && begin[-2] == ascii8("*") {
            // /* ... */{operator}
            return false
        } else {
            return true
        }
    default:
        return true
    }
}

private func isRightBound(_ end: SrcPointer, isLeftBound: Bool) -> Bool {
    switch UnicodeScalar(end[0]) {
    case " ", "\r", "\n", "\t", ")", "]", "}", ",", ";", ":":
        return false
    case ".":
        return !isLeftBound
    case "/":
        if end[1] == ascii8("/") || end[1] == ascii8("*") {
            return false
        } else {
            return true
        }
    default:
        return true
    }
}

private func skipToEndOfInterpolatedExpression(_ ptr: SrcPointer, _ bufEnd: SrcPointer) -> SrcPointer {
    var ptr = ptr + 1
    var stack: [UnicodeScalar] = []
    
    var isInStringLiteral: Bool {
        return stack.last == "\""
    }
    while ptr != bufEnd {
        let c = ptr.pointee
        switch UnicodeScalar(c) {
        case "(":
            if !isInStringLiteral {
                stack.append("(")
            }
        case ")":
            if stack.isEmpty {
                return ptr
            } else if stack.last! == "(" {
                stack.removeLast()
            } else {
                assert(isInStringLiteral)
            }
        case "\"":
            if !isInStringLiteral {
                stack.append("\"")
            } else {
                stack.removeLast()
            }
        case "\\":
            if !isInStringLiteral {
                ptr += 1
                if ptr == bufEnd { return ptr }
                let escapedChar = ptr.pointee
                switch UnicodeScalar(escapedChar) {
                case "(":
                    stack.append("(")
                case "\r", "\n":
                    return ptr
                default:
                    break
                }
            }
        default:
            break
        }
        ptr += 1
    }
    return ptr
}

struct Lexer {
    private let bufStart: SrcPointer
    private let bufEnd: SrcPointer
    var ptr: SrcPointer
    var token: Token
    
    init(ptr: SrcPointer, length: Int) {
        bufStart = ptr
        bufEnd = ptr + length
        self.ptr = ptr
        token = Token(init: ptr)
        lexImpl()
    }
    
    mutating func reset(ptr: SrcPointer) {
        assert(ptr >= bufStart && ptr <= bufEnd)
        self.ptr = ptr
        lexImpl()
    }
    
    private func validateUTF8CharacterAndAdvance(_ ptr: inout SrcPointer) -> UnicodeScalar? {
        var iter = UTF8Iterator(position: ptr, end: bufEnd)
        defer { ptr = iter.position }
        
        var dec = UTF8()
        switch dec.decode(&iter) {
        case .scalarValue(let scalar):
            return scalar
        case .emptyInput, .error:
            return nil
        }
    }
    
    private func advanceIf(_ ptr: inout SrcPointer, _ predicate: (UnicodeScalar) -> Bool) -> Bool {
        if ptr == bufEnd {
            return false
        }
        var next = ptr;
        if let scalar = validateUTF8CharacterAndAdvance(&next), predicate(scalar) {
            ptr = next;
            return true
        }
        return false
    }
    
    private func advanceIf(_ ptr: inout SrcPointer, _ s: UnicodeScalar) -> Bool {
        if ptr != bufEnd && ascii8(s) == ptr.pointee {
            ptr += 1
            return true
        }
        return false
    }
    
    private mutating func formToken(_ kind: Token.Kind, _ start: SrcPointer) {
        token.start = start
        token.length = ptr - start
        token.kind = kind
        token.isEscapedIdentifier = false
    }
    
    private mutating func noIdentifierContinuation(_ kind: Token.Kind, _ start: SrcPointer) {
        if advanceIf(&ptr, isValidIdentifierContinuationCodePoint) {
            while advanceIf(&ptr, isValidIdentifierContinuationCodePoint) {}
            return formToken(.unknown, start)
        }
        return formToken(kind, start)
    }
    
    private mutating func lexIdentifier(_ start: SrcPointer) {
        while advanceIf(&ptr, isValidIdentifierContinuationCodePoint) {}
        let kind = getIdentifierTokenKind(start, ptr - start)
        return formToken(kind, start)
    }
    
    private mutating func lexEscapedIdentifier() {
        let start = ptr - 1
        if advanceIf(&ptr, isValidIdentifierStartCodePoint) {
            while advanceIf(&ptr, isValidIdentifierContinuationCodePoint) {}
            if advanceIf(&ptr, "`") {
                formToken(.identifier, start)
                token.isEscapedIdentifier = true
                return
            }
        }
        formToken(.unknown, start)
    }
    
    private mutating func lexOperatorIdentifier(_ start: SrcPointer) {
        while advanceIf(&ptr, isValidOperatorContinuationCodePoint) {}
        if start.pointee != ascii8(".") {
            // '.' in operator is not allowed if the operator starts with '.'
            for p in (start + 1) ..< ptr {
                if p.pointee == ascii8(".") {
                    ptr = p
                    break
                }
            }
        }
        if (ptr - start) > 2 {
            // Trim out comment '/*' in the middle of the operator.
            for p in (start + 1) ..< (ptr - 1) {
                if p[0] == ascii8("/")
                    && (p[1] == ascii8("/") || p[1] == ascii8("*")) {
                    ptr = p
                    break
                }
            }
        }
        
        let leftBound = isLeftBound(start, bufStart)
        let rightBound = isRightBound(ptr, isLeftBound: leftBound)
        
        let length = (ptr - start)
        if length == 1 {
            if start.pointee == ascii8("=") {
                return formToken(.equal, start)
            } else if start.pointee == ascii8("&") {
                if rightBound && !leftBound {
                    return formToken(.amp_prefix, start)
                }
            } else if start.pointee == ascii8(".") {
                if rightBound {
                    return formToken(.period, start)
                } else {
                    return formToken(.unknown, start)
                }
            } else if start.pointee == ascii8("?") {
                if leftBound {
                    return formToken(.question_postfix, start)
                } else {
                    return formToken(.question_infix, start)
                }
            } else if start.pointee == ascii8("!") {
                if leftBound {
                    return formToken(.exclaim_postfix, start)
                }
            }
        } else if length == 2 {
            if start[0] == ascii8("-") && start[1] == ascii8(">") {
                return formToken(.arrow, start)
            } else if start[0] == ascii8("*") && start[1] == ascii8("/") {
                return formToken(.unknown, start)
            }
        } else {
            for p in start + 1 ..< ptr - 2 {
                if p[0] == ascii8("*") && p[1] == ascii8("/") {
                    // We don't allow '*/' in the middle of the identfier token.
                    return formToken(.unknown, start)
                }
            }
        }
        
        let kind: Token.Kind
        if leftBound == rightBound {
            kind = leftBound ? .oper_binary_unspaced : .oper_binary_unspaced
        } else {
            kind = leftBound ? .oper_postfix : .oper_prefix
        }
        return formToken(kind, start)
    }
    
    private mutating func lexStringLiteral() {
        let start = ptr - 1
        while let scalar = validateUTF8CharacterAndAdvance(&ptr) {
            switch scalar {
            case "\"":
                return formToken(.string_literal, start)
            case "\n", "\r":
                ptr -= 1
                return formToken(.unknown, start)
            case "\\":
                switch UnicodeScalar(ptr.pointee) {
                case "0", "m", "r", "t", "\"", "'", "\\":
                    ptr += 1
                case "(":
                    ptr = skipToEndOfInterpolatedExpression(ptr, bufEnd)
                    if ptr.pointee == ascii8(")") {
                        ptr += 1
                    } else {
                        return formToken(.unknown, start)
                    }
                case "u":
                    ptr += 1
                default:
                    break
                }
            default:
                break
            }
        }
        return formToken(.unknown, start)
    }
    
    private mutating func lexHexNumber() {
        let start = ptr - 1
        
        assert(start[0] == ascii8("0") && ptr[0] == ascii8("x"))
        ptr += 1
        if !isHexDigit(ptr.pointee) {
            noIdentifierContinuation(.unknown, start)
        }
        while isHexDigit(ptr.pointee) { ptr += 1 }
        
        if ptr.pointee != ascii8(".") &&
            ptr.pointee != ascii8("p") &&
            ptr.pointee != ascii8("P") {
            return formToken(.integer_literal, start)
        }
        
        var ptrOnDot: SrcPointer? = nil
        if ptr.pointee == ascii8(".") {
            if !isHexDigit(ptr[1]) {
                return formToken(.integer_literal, start)
            }
            
            ptrOnDot = ptr
            ptr += 1
            
            while isHexDigit(ptr.pointee) || ptr.pointee == ascii8("_") {
                ptr += 1
            }
            if ptr.pointee != ascii8("p") && ptr.pointee != ascii8("P") {
                if !isDigit(ptrOnDot!.pointee) {
                    ptr = ptrOnDot!
                    return formToken(.integer_literal, start)
                }
                return noIdentifierContinuation(.unknown, start)
            }
        }
        
        assert(ptr.pointee == ascii8("p") || ptr.pointee == ascii8("P"))
        ptr += 1
        var signedExponent = false
        if ptr.pointee == ascii8("+") || ptr.pointee == ascii8("-") {
            signedExponent = true
            ptr += 1
        }
        if !isDigit(ptr.pointee) {
            if let ptrOnDot = ptrOnDot,
                !isDigit(ptrOnDot.pointee),
                !signedExponent {
                // e.g.: 0xff.fpValue
                ptr = ptrOnDot
                return formToken(.integer_literal, start)
            }
            return formToken(.unknown, start)
        }
        while isDigit(ptr.pointee) || ptr.pointee == ascii8("_") {
            ptr += 1
        }
        return formToken(.float_literal, start)
    }

    private mutating func lexOctalNumber() {
        let start = ptr - 1
        ptr += 1
        while (ascii8("0") ... ascii8("7") ~= ptr.pointee) || ptr.pointee == ascii8("_") {
            ptr += 1
        }
        if (ptr - start) <= 2 {
            return noIdentifierContinuation(.unknown, start)
        }
        return noIdentifierContinuation(.integer_literal, start)
    }
    
    private mutating func lexBinNumber() {
        let start = ptr - 1
        ptr += 1
        while ptr.pointee == ascii8("0")
            || ptr.pointee == ascii8("1")
            || ptr.pointee == ascii8("_") {
            ptr += 1
        }
        if (ptr - start) <= 2 {
            return noIdentifierContinuation(.unknown, start)
        }
        return noIdentifierContinuation(.integer_literal, start)
    }

    private mutating func lexDecimalNumber() {
        let start = ptr - 1
        // Real part
        while isDigit(ptr.pointee) || ptr.pointee == ascii8("_") {
            ptr += 1
        }
        
        if ptr.pointee == ascii8(".") {
            // 0000.foo
            if (!isDigit(ptr[1])) {
                return formToken(.integer_literal, start)
            }
            ptr += 1
            
            // Fraction part
            while isDigit(ptr.pointee) || ptr.pointee == ascii8("_") {
                ptr += 1
            }
        } else if ptr.pointee != ascii8("e") && ptr.pointee != ascii8("E") {
            // Digits only; integer literal
            return noIdentifierContinuation(.integer_literal, start)
        }
        
        // Float exponent
        if ptr.pointee == ascii8("e") || ptr.pointee == ascii8("E") {
            ptr += 1
            if ptr.pointee == ascii8("+") || ptr.pointee == ascii8("-") {
                ptr += 1
            }
            if !isDigit(ptr.pointee) {
                return noIdentifierContinuation(.unknown, start)
            }
            while isDigit(ptr.pointee) || ptr.pointee == ascii8("_") {
                ptr += 1
            }
        }

        noIdentifierContinuation(.float_literal, start)
    }
    
    private mutating func lexDollarIdent() {
        let start = ptr - 1
        while isDigit(ptr.pointee) {
            ptr += 1
        }
        noIdentifierContinuation(.dollarident, start)
    }
    
    mutating func lexImpl() {
        while true {
            if ptr >= bufEnd {
                return formToken(.eof, ptr)
            }
            let startPtr = ptr
            let c = startPtr.pointee
            ptr += 1
            
            switch UnicodeScalar(c) {

            // Whitespaces
            case "\n",
                 "\r":
                token.isAtStartOfLine = true
                continue
            case " ",
                 "\t",
                 "\u{12}",
                 "\u{11}":
                continue
            case "\u{0}":
                ptr -= 1
                return formToken(.eof, startPtr)

            // Punctuators
            case "{":
                return formToken(.l_brace, startPtr)
            case "}":
                return formToken(.r_brace, startPtr)
            case "[":
                return formToken(.l_square, startPtr)
            case "]":
                return formToken(.r_square, startPtr)
            case "(":
                return formToken(.l_paren, startPtr)
            case ")":
                return formToken(.r_paren, startPtr)
            case ",":
                return formToken(.comma, startPtr)
            case ":":
                return formToken(.colon, startPtr)
            case ";":
                return formToken(.semi, startPtr)
            case "@":
                return formToken(.at_sign, startPtr)
            case "?":
                if isLeftBound(startPtr, bufStart) {
                    return formToken(.question_postfix, startPtr)
                }
                return lexOperatorIdentifier(startPtr)
            case "!":
                if isLeftBound(startPtr, bufStart) {
                    return formToken(.exclaim_postfix, startPtr)
                }
                return lexOperatorIdentifier(startPtr)
            
            // Literal
            case "\"":
                return lexStringLiteral()
            case "0":
                if ptr.pointee == ascii8("x") {
                    return lexHexNumber()
                } else if ptr.pointee == ascii8("o") {
                    return lexOctalNumber()
                } else if ptr.pointee == ascii8("b") {
                    return lexBinNumber()
                } else {
                    return lexDecimalNumber()
                }
            case "1"..."9":
                return lexDecimalNumber()

            // Identifiers
            case "$":
                return lexDollarIdent()
            case "`":
                return lexEscapedIdentifier()
            default:
                var tmp = ptr - 1
                if advanceIf(&tmp, isValidIdentifierStartCodePoint) {
                    return lexIdentifier(startPtr)
                }
                if advanceIf(&tmp, isValidOperatorStartCodePoint) {
                    return lexOperatorIdentifier(startPtr)
                }
                _ = validateUTF8CharacterAndAdvance(&ptr)
                return formToken(.unknown, startPtr)
            }
        }
    }
    
    mutating func consume() {
        lexImpl()
    }
}

extension Lexer : IteratorProtocol {
    mutating func next() -> Token? {
        if token.kind == .eof { return nil }
        let tok = token
        lexImpl()
        return tok
    }
}

extension Lexer : Sequence {
    func makeIterator() -> Lexer {
        return self
    }
}
