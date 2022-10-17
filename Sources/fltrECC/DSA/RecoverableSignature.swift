import fltrECCAdapter

public extension DSA {
    struct RecoverableSignature {
        @usableFromInline
        let _data: [UInt8]
        
        @usableFromInline
        internal init(_data: [UInt8]) {
            self._data = _data
        }
        
        @inlinable
        public init?(from serialized: [UInt8], id: Int) {
            guard let signature = try? C.deSerialize(recoverable: serialized,
                                                     id: id)
            else { return nil }
            self.init(_data: signature)
        }
        
        @inlinable
        public func serialize() -> (data: [UInt8], id: Int) {
            C.serialize(recoverable: self._data)
        }
        
        @inlinable
        public func dsaSignature() -> DSA.Signature {
            let data = C.convert(recoverable: self._data)
            return .init(_data: data)
        }
        
        @inlinable
        public func recover(from message: [UInt8]) -> DSA.PublicKey? {
            guard message.count == 32
            else { return nil }
            
            do {
                let data = try C.recoverPoint(from: self._data, message: message)
                return .init(_data: data)
            } catch {
                return nil
            }
        }
    }
}

extension DSA.RecoverableSignature: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs._data.elementsEqual(rhs._data)
    }
}
