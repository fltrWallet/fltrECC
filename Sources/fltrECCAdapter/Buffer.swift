public protocol ReadableBufferProtocol {
    var count: Int { get  }
    static func create(capacity: Int, initializingWith: (inout UnsafeMutableRawBufferPointer, inout Int) throws -> Void) rethrows -> Self
    func withUnsafeBytes<T>(_: (UnsafeRawBufferPointer) throws -> T) rethrows -> T
}

internal protocol WritableBufferProtocol {
    func withUnsafeMutableBytes<T>(_: (UnsafeMutableRawBufferPointer) throws -> T) rethrows -> T
}

public struct ManagedHeader {
    @usableFromInline
    var count: Int
    @usableFromInline
    let capacity: Int
}

public final class Buffer: ManagedBuffer<ManagedHeader, UInt8> {
    @usableFromInline
    class func nextPower2(_ x: UInt) -> UInt {
        guard x > 0 else { return 1 }
        
        let lessOne = x - 1
        
        let shift = x.bitWidth - lessOne.leadingZeroBitCount
        return 1 << shift
    }
    
    @usableFromInline
    class func _create(capacity: Int) -> Buffer {
        let minimumCapacity = Int(self.nextPower2(UInt(capacity)))
        let buffer = self.create(minimumCapacity: minimumCapacity) { _ in
            ManagedHeader(count: 0, capacity: capacity)
        }
        return buffer as! Buffer
    }
    
    @usableFromInline
    class func copy(buffer: Buffer) {
        let new = self._create(capacity: buffer.header.count)
        new.withUnsafeMutablePointerToElements { new in
            buffer.withUnsafeMutablePointerToElements { data in
                for i in 0..<buffer.header.count {
                    new[i] = data[i]
                }
            }
        }
    }
    
    @usableFromInline
    class func copy<C: Collection>(bytes: C) -> Buffer where C.Element == UInt8 {
        let buffer = self._create(capacity: bytes.count)
        buffer.withUnsafeMutablePointerToElements { buffer in
            bytes.enumerated().forEach { i, byte in
                buffer[i] = byte
            }
        }
        buffer.header.count = bytes.count
        return buffer
    }
    
    @usableFromInline
    class func create(random count: Int) -> Buffer {
        let buffer = self._create(capacity: count)
        buffer.withUnsafeMutablePointerToElements { buffer in
            for i in 0..<count {
                buffer[i] = .random(in: .min ... .max)
            }
        }
        buffer.header.count = count
        return buffer
    }

    @inlinable
    deinit {
        self.withUnsafeMutablePointerToElements { buffer in
            let buffer = UnsafeMutableRawBufferPointer(start: buffer, count: self.header.capacity)
            for i in 0..<self.header.capacity {
                buffer[i] = 0
            }
        }
    }
}

extension Buffer: ReadableBufferProtocol, WritableBufferProtocol {
    @inlinable
    public var count: Int { self.header.count }
    
//    public static func create(capacity: Int) -> Self {
//        let buffer = self._create(capacity: capacity)
//
//    }
    @inlinable
    public static func create(capacity: Int, initializingWith callback: (inout UnsafeMutableRawBufferPointer, inout Int) throws -> Void) rethrows -> Self {
        let buffer = Buffer._create(capacity: capacity)
        try buffer.withUnsafeMutablePointerToElements { bytes in
            var mutable = UnsafeMutableRawBufferPointer(start: bytes, count: capacity)
            var initializedCount = 0
            try callback(&mutable, &initializedCount)
            buffer.header.count = initializedCount
        }
        return buffer as! Self
    }

    @inlinable
    public func withUnsafeBytes<T>(_ body: (UnsafeRawBufferPointer) throws -> T) rethrows -> T {
        try self.withUnsafeMutablePointerToElements { buffer in
            let pointer = UnsafeRawBufferPointer(start: buffer, count: self.header.count)
            return try body(pointer)
        }
    }

    @inlinable
    public func withUnsafeMutableBytes<T>(_ body: (UnsafeMutableRawBufferPointer) throws -> T) rethrows -> T {
        try self.withUnsafeMutablePointerToElements { buffer in
            let pointer = UnsafeMutableRawBufferPointer(start: buffer, count: self.header.count)
            return try body(pointer)
        }
    }
}

extension Buffer: Equatable {
    // Constant time equals
    @inlinable
    public static func ==(lhs: Buffer, rhs: Buffer) -> Bool {
        guard lhs.header.count == rhs.header.count
        else { return false }
        
        return lhs.withUnsafeMutablePointerToElements { lPointer in
            let lhs = UnsafeRawBufferPointer(start: lPointer, count: lhs.header.count)
            return rhs.withUnsafeMutablePointerToElements { rPointer in
                let rhs = UnsafeRawBufferPointer(start: rPointer, count: rhs.header.count)
                return lhs.enumerated().reduce(true) { partialResult, iter in
                    partialResult && iter.element == rhs[iter.offset]
                }
            }
        }
    }
}


