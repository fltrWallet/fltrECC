import Csecp256k1

public struct KeyPair: SecretBytes, SecretMutableBytes, Equatable {
    public let buffer: Buffer

    @usableFromInline
    internal init(_buffer: Buffer) {
        self.buffer = _buffer
    }

    @inlinable
    public init?(_ buffer: Buffer) {
        guard buffer.count == C.KEYPAIR_SIZE
        else { return nil }
        
        let keyPair = Self.init(_buffer: buffer)
        guard let _ = C.scalar(from: keyPair)
        else { return nil }
        
        self = keyPair
    }
}
