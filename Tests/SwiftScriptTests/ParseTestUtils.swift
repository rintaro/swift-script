import XCTest
import Runes
import TryParsec
@testable import SwiftScript

func parseIt<Out>(_ parser: SwiftParser<Out>, _ src: String) throws -> Out {
    let dat = src.data(using: .utf8)!
    return try dat.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Out in
        let input = Lexer(ptr: ptr, length: dat.count)
        let result = parseOnly(parser <* tok(.eof), input)
        switch result {
        case .success(let stmts): return stmts
        case .failure(let err): throw err
        }
    }
}

func parseSuccess<Out>(_ parser: SwiftParser<Out>, _ str: String) -> Bool {
    do {
        _ = try parseIt(parser, str)
        return true
    } catch {
        return false
    }
}
