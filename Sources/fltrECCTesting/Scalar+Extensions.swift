import fltrECCAdapter

extension Scalar: ExpressibleByIntegerLiteral {
    public static let ScalarSize = { Scalar.random().count }()
    
    @inlinable
    public init<Fixed: FixedWidthInteger>(_ number: Fixed) where Fixed: SignedNumeric {
        precondition(number != 0)
        guard number > 0
        else { self = .init(abs(number)).negated(); return }
        
        
        var bigEndian = number.bigEndian
        self = Scalar(unsafeUninitializedCapacity: Scalar.ScalarSize) { buffer, setSizeTo in
            let size = MemoryLayout<Fixed>.size
            precondition(size < Scalar.ScalarSize)
            let start = Scalar.ScalarSize - size
            
            (0..<start).forEach {
                buffer[$0] = 0
            }
            Swift.withUnsafeBytes(of: &bigEndian) { bytes in
                assert((start..<Scalar.ScalarSize).count == size)
                zip((start..<Scalar.ScalarSize), bytes).forEach { bpOffset, byte in
                    buffer[bpOffset] = byte
                }
            }
            
            setSizeTo = Scalar.ScalarSize
        }
    }
    
    @inlinable
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension Scalar {
    @usableFromInline
    init(_ value: [UInt8]) {
        precondition(value.count == 32)
        self.init(unsafeUninitializedCapacity: 32) { byte, size in
            (0..<32).forEach {
                byte[$0] = value[$0]
            }
            size = 32
        }
    }
}

extension Scalar: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral elements: UInt8...) {
        self.init(elements)
    }
}

extension Scalar: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral value: String) {
        func bytes(from hex: String) -> [UInt8] {
            let characters = Array(hex)
            return stride(from: 0, to: hex.count, by: 2).compactMap {
                UInt8(String(characters[$0...$0.advanced(by: 1)]), radix: 16)
            }
        }
        
        let bytes = bytes(from: value)
        self.init(bytes)
    }
    
}

extension Scalar: Comparable {
    @inlinable
    public static func < (lhs: Scalar, rhs: Scalar) -> Bool {
        lhs.withUnsafeBytes { lhs in
            rhs.withUnsafeBytes { rhs in
                var revLhs = lhs.makeIterator()
                var revRhs = rhs.makeIterator()
                for _ in 0..<4 {
                    let intLhs = UInt64(littleEndianBytes: &revLhs)
                    let intRhs = UInt64(littleEndianBytes: &revRhs)
                    switch intLhs {
                    case _ where intLhs < intRhs: return true
                    case _ where intLhs > intRhs: return false
                    default: break
                    }
                }
                // equal
                return false
            }
        }
    }
}
