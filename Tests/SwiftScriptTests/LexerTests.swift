import XCTest
@testable import SwiftScript


private struct TokInfo {
    let kind: Token.Kind
    let text: String
    
}
extension TokInfo : CustomStringConvertible {
    var description: String {
        let x = "(\(kind) '\(text)')"
        return x
    }
}
extension TokInfo : Equatable {
    static func == (lhs: TokInfo, rhs: TokInfo) -> Bool {
        return lhs.kind == rhs.kind && lhs.text == rhs.text
    }
}

private func tokenize(_ str: String) -> Array<TokInfo> {
    let dat = str.data(using: .utf8)!
    return withExtendedLifetime(dat) {
        dat.withUnsafeBytes { (ptr: UnsafePointer<UInt8>)  in
            print(UTF8ChunkRef(start: ptr, length: dat.count).text)
            let lexer = Lexer(ptr: ptr, length: dat.count)
            return lexer.map { tok in
                TokInfo(kind: tok.kind, text: tok.text)
            }
        }
    }
}

class LexerTests: XCTestCase {
    func testTokenize() {
        XCTAssertEqual(tokenize("let ab?<Foo?>=12"), [
            TokInfo(kind: .kw_let, text: "let"),
            TokInfo(kind: .identifier, text: "ab"),
            TokInfo(kind: .question_postfix, text: "?"),
            TokInfo(kind: .oper_binary_unspaced, text: "<"),
            TokInfo(kind: .identifier, text: "Foo"),
            TokInfo(kind: .question_postfix, text: "?"),
            TokInfo(kind: .oper_binary_unspaced, text: ">="),
            TokInfo(kind: .integer_literal, text: "12"),
            ])
    }
    func testIntegerLiteral() {
        XCTAssertEqual(tokenize("12 0x12 0o73 0b00111100"), [
            TokInfo(kind: .integer_literal, text: "12"),
            TokInfo(kind: .integer_literal, text: "0x12"),
            TokInfo(kind: .integer_literal, text: "0o73"),
            TokInfo(kind: .integer_literal, text: "0b00111100"),
            ])
    }
    func testFloatLiteral() {
        XCTAssertEqual(tokenize("12.0"), [
            TokInfo(kind: .float_literal, text: "12.0"),
            ])
    }
}
