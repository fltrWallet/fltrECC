public struct EcdhSecret: SecretBytes, Equatable {
    public let buffer: Buffer
    
    @inlinable
    public init?(_ buffer: Buffer) {
        guard buffer.count == C.ECDH_SECRET_SIZE
        else { return nil }
        
        self.buffer = buffer
    }
}
