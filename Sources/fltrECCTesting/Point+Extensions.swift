import fltrECCAdapter

extension Point: ExpressibleByIntegerLiteral {
    @inlinable
    public init(_ value: Int) {
        self.init(Scalar(value))
    }
    
    @inlinable
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}
