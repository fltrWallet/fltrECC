import fltrECCAdapter

public protocol SecretKeyProtocol {
    associatedtype Signature
    init(_ scalar: Scalar)
    var scalar: Scalar { get }
    static func random() -> Self
    func sign(message: [UInt8], nonce: Entropy) -> Signature
}

public extension SecretKeyProtocol {
    static func random() -> Self {
        let random = Scalar.random()
        return self.init(random)
    }
}

public extension SecretKeyProtocol where Self: Equatable {
    @inlinable
    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.scalar == rhs.scalar
    }
}

public extension SecretKeyProtocol where Self: Hashable {
    @inlinable
    func hash(into hasher: inout Hasher) {
        self.scalar.withUnsafeBytes {
            hasher.combine(bytes: $0)
        }
    }
}
