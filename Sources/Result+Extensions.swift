


// Compatibility stuff for antitypical/Result

extension Result {
    public func tryMap<U>(_ transform: (Success) throws -> U) -> Result<U, Error> {
        switch self {
        case .failure(let error):
            return .failure(error)
        case .success(let value):
            do {
                return .success(try transform(value))
            }
            catch {
                return .failure(error)
            }
        }
    }
}

extension Result {
    public init(value: Success) {
        self = .success(value)
    }
    
    public init(error: Failure) {
        self = .failure(error)
    }
    
    public init(_ value: Success) {
        self = .success(value)
    }
    
    @available(*, deprecated, renamed: "get")
    public func dematerialize() throws -> Success {
        return try get()
    }
    
    public var value: Success? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }
    
    public var error: Failure? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
    
    
    public func analysis<Result>(ifSuccess: (Success) -> Result, ifFailure: (Failure) -> Result) -> Result {
        switch self {
        case .success(let value):
            return ifSuccess(value)
        case .failure(let error):
            return ifFailure(error)
        }
    }
    
}

