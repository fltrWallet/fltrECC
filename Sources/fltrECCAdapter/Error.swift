public extension C {
    enum Error: Swift.Error {
        case illegalKeyPairValue
        case illegalScalarValue
        case illegalPointSerialization
        case illegalPointSerializationByteCount
        case illegalPointValue
        case illegalSignature
//        case infinity
//        case undefinedResult(lhs: String, rhs: String, operation: StaticString)
        
    }
}
