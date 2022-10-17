import Csecp256k1

public enum C {}

internal extension C {
    @usableFromInline
    final class Context {
        @usableFromInline
        var pointer: OpaquePointer
        
        init() {
            let context = C.createContext()
            C.randomize(context: context)
            self.pointer = context
        }
        
        deinit {
            C.destroy(context: self.pointer)
        }
    }
}

extension C {
    @usableFromInline
    static let context: Context = .init()
}
