
import TryParsec

typealias SrcPointer = UnsafePointer<UInt8>

// Just for onvenience
typealias SwiftParser<Out> = TryParsec.Parser<Lexer, Out>

