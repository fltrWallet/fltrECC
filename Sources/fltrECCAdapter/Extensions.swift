extension StringProtocol {
    @usableFromInline
    var hex: [UInt8] {
        let hexa = Array(self)
        return stride(from: 0, to: count, by: 2).compactMap {
            UInt8(String(hexa[$0...$0.advanced(by: 1)]), radix: 16)
        }
    }
}
