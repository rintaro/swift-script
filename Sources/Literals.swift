public protocol Literal: Expression {
    
}

public struct ArrayLiteral: Literal {
    public var value: [Expression]
}

public struct DictionaryLiteral: Literal {
    public var value: [(Expression, Expression)]
}

public struct IntegerLiteral: Literal {
    public var digits: String
    public init(digits: String) { self.digits = digits }
    public init(value: Int) { self.digits = "\(value)" }
}

public struct FloatingPointLiteral: Literal {
    public var digits: String
    public init(digits: String) { self.digits = digits }
    public init(value: Double) { self.digits = "\(value)" }
}

public struct StringLiteral: Literal {
    public var value: String
}

public struct BooleanLiteral: Literal {
    public var value: Bool
}

public struct NilLiteral: Literal {
    
}
