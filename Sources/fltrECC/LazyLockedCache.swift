import Darwin

@usableFromInline
internal final class LazyLockedCache<T> {
    @usableFromInline
    var lock = os_unfair_lock()
    @usableFromInline
    var value: Optional<T> = .none
    
    init() {}
    
    @usableFromInline
    func cache(_ fn: () throws -> T) rethrows -> T {
        let exists: T? = {
            os_unfair_lock_lock(&self.lock)
            defer { os_unfair_lock_unlock(&self.lock) }
            return self.value
        }()
        
        if let value = exists {
            return value
        } else {
            let newValue = try fn()
            
            os_unfair_lock_lock(&self.lock)
            self.value = newValue
            os_unfair_lock_unlock(&self.lock)
            return newValue
        }
    }
}
