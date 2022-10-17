public extension C {
    enum Comparison: String, Equatable, Hashable, Codable {
        case lessThan
        case greaterThan
        case equals
        
        @inlinable
        public var equals: Bool {
            switch self {
            case .equals: return true
            case .lessThan, .greaterThan: return false
            }
        }
        
        @inlinable
        public static func ==(lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.lessThan, .lessThan): return true
            case (.greaterThan, .greaterThan): return true
            case (.equals, .equals): return true
            case (.lessThan, .greaterThan),
                (.lessThan, .equals),
                (.greaterThan, .lessThan),
                (.greaterThan, .equals),
                (.equals, .lessThan),
                (.equals, .greaterThan): return false
            }
        }
    }
}
