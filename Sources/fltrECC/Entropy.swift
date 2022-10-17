import fltrECCAdapter

public enum Entropy {
    case some([UInt8])
    case none
    
    @inlinable
    public static func random() -> Self {
        .some((0..<32).map { _ in .random(in: .min ... .max)})
    }
    
    @inlinable
    public var value: [UInt8]? {
        switch self {
        case .some(let value): return value
        case .none: return nil
        }
    }
}
