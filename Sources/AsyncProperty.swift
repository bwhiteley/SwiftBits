//
//  File.swift
//  
//
//  Created by Bart Whiteley on 10/12/19.
//

import Foundation

public class AsyncProperty<Value, ErrorType: Error> {
    public func get(_ completion:@escaping (Result<Value, ErrorType>) -> Void) {
        switch state.value {
        case .storedValue(let result):
            completion(result)
        case .initial:
            self.resultClosures.mutate() { closures in
                closures.append(completion)
            }
            load()
        case .loading:
            self.resultClosures.mutate() { closures in
                closures.append(completion)
            }
        }
    }
    
    public func load() {
        state.mutate() { state in
            switch state {
            case .loading, .storedValue(_): return
            case .initial: break
            }
            
            self.loadValue() { result in
                self.state.mutate() { state in
                    self.resultClosures.mutate { closures in
                        for closure in closures {
                            closure(result)
                        }
                        closures = []
                    }
                    state = .storedValue(result)
                }
            }
            state = .loading
        }
    }
    
    public init(loader: @escaping ( @escaping (Result<Value, ErrorType>) -> Void) -> Void) {
        self.loadValue = loader
    }
    
    private var state: AtomicProperty<State> = AtomicProperty(.initial)
        
    private var resultClosures: AtomicProperty<[(Result<Value, ErrorType>) -> Void]> = AtomicProperty([])
        
    private var loadValue: (@escaping (Result<Value, ErrorType>) -> Void) -> Void
    
    private enum State {
        case initial
        case loading
        case storedValue(Result<Value, ErrorType>)
    }
    
}


