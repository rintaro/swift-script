import XCTest
@testable import SwiftScript

class ParsePrimitiveTests: XCTestCase {
    func testPunctuators() {
        XCTAssertEqual(try parseIt(l_paren, "(").text, "(")
        XCTAssertEqual(try parseIt(r_paren, ")").text, ")")
        XCTAssertEqual(try parseIt(l_brace, "{").text, "{")
        XCTAssertEqual(try parseIt(r_brace, "}").text, "}")
        XCTAssertEqual(try parseIt(l_square, "[").text, "[")
        XCTAssertEqual(try parseIt(r_square, "]").text, "]")
        XCTAssertEqual(try parseIt(l_angle, "<").text, "<")
        XCTAssertEqual(try parseIt(r_angle, ">").text, ">")
    }
    
    func testKeywords() {
        XCTAssertEqual(try parseIt(kw_is, "is").text, "is")
        XCTAssertThrowsError(try parseIt(kw_is, "isa"))
    }
    func testIdentifiers() {
        XCTAssertEqual(try parseIt(identifier, "foo"), "foo")
        XCTAssertEqual(try parseIt(identifier, "`is`"), "is")
        XCTAssertThrowsError(try parseIt(identifier, "is"))
        XCTAssertThrowsError(try parseIt(identifier, "$f12"))
        XCTAssertThrowsError(try parseIt(identifier, "$12"))
    }
    func testKeywordOrIdentifier() {
        XCTAssertEqual(try parseIt(keywordOrIdentifier, "is"), "is")
        XCTAssertEqual(try parseIt(keywordOrIdentifier, "`is`"), "is")
        XCTAssertThrowsError(try parseIt(keywordOrIdentifier, "$0"))
        XCTAssertThrowsError(try parseIt(keywordOrIdentifier, "`$0`"))
    }
    func testDollerIdentifier() {
        XCTAssertEqual(try parseIt(dollarIdentifier, "$12"), "$12")
        XCTAssertThrowsError(try parseIt(dollarIdentifier, "`$0`"))
    }
}
