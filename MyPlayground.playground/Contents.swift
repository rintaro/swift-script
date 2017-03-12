//: Playground - noun: a place where people can play

@testable import SwiftScript

let dat = "func foo(x: A)".data(using: .utf8)!
dat.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) in
    var lexer = Lexer(ptr: ptr, length: dat.count)
    for t in lexer {
        stringRemovingUnderscore(ptr: t.start, length: t.length)
        print(t.kind, "'\(t.text)'")
    }
}
