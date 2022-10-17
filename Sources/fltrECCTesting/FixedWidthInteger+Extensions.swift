extension FixedWidthInteger {
    @usableFromInline
    init<I>(littleEndianBytes iterator: inout I)
    where I: IteratorProtocol, I.Element == UInt8 {
        self = stride(from: 0, to: Self.bitWidth, by: 8).reduce(into: 0) {
            $0 |= Self(truncatingIfNeeded: iterator.next()!) &<< $1
        }
    }
    
    @usableFromInline
    init<C>(littleEndianBytes bytes: C) where C: Collection, C.Element == UInt8 {
        precondition(bytes.count == (Self.bitWidth+7)/8)
        var iter = bytes.makeIterator()
        self.init(littleEndianBytes: &iter)
    }
}
