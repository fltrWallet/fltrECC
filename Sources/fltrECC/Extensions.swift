import fltrECCAdapter

public extension Scalar {
    @inlinable
    static prefix func -(value: Self) -> Self {
        value.negated()
    }
    
    @inlinable
    static func +(lhs: Self, rhs: Self) -> Self? {
        lhs.add(rhs)
    }
    
    @inlinable
    static func -(lhs: Self, rhs: Self) -> Self? {
        lhs.add(rhs.negated())
    }

    @inlinable
    static func *(lhs: Self, rhs: Self) -> Self {
        lhs.mul(rhs)
    }
}

public extension Point {
    @inlinable
    static prefix func -(value: Self) -> Self {
        value.negated()
    }

    @inlinable
    static func +(lhs: Self, rhs: Self) -> Self? {
        lhs.add(rhs)
    }

    @inlinable
    static func -(lhs: Self, rhs: Self) -> Self? {
        lhs.add(rhs.negated())
    }

    @inlinable
    static func *(lhs: Self, rhs: Scalar) -> Self {
        lhs.mul(rhs)
    }
    
    @inlinable
    static func *(lhs: Scalar, rhs: Self) -> Self {
        rhs.mul(lhs)
    }
}
