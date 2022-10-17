import fltrECCAdapter

public extension X {
    struct Signature {
        @usableFromInline
        internal let _data: [UInt8]
        
        @usableFromInline
        internal init(_data: [UInt8]) {
            self._data = _data
        }
        
        @inlinable
        public init?(from serialized: [UInt8]) {
            guard serialized.count == C.SCHNORR_SIGNATURE_SIZE
            else { return nil }
            self.init(_data: serialized)
        }
        
        @inlinable
        public func serialize() -> [UInt8] {
            self._data
        }
    }
}
