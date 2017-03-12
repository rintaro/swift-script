import Runes
import TryParsec
import Result
import Foundation

let topLevel: SwiftParser<[Statement]> = stmtBraceItems <* tok(.eof)

public func parseTopLevel(_ src: String) throws -> [Statement] {
    let dat = src.data(using: .utf8)!
    return try parseTopLevel(dat)
}

public func parseTopLevel(_ dat: Data) throws -> [Statement] {
    let result = dat.withUnsafeBytes { ptr in
        parseOnly(topLevel, Lexer(ptr: ptr, length: dat.count))
    }
    switch result {
    case .success(let stmts): return stmts
    case .failure(let err): throw err
    }
}
