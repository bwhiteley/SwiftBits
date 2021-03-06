//
//  File.swift
//  
//
//  Created by Bart Whiteley on 10/12/19.
//

import Foundation

public class AsyncProperty<Value, ErrorType: Error> {
    public func get(_ completion:@escaping (Result<Value, ErrorType>) -> Void) {
        queue.sync {
            switch state {
            case .storedValue(let result):
                completion(result)
            case .initial:
                resultClosures.append(completion)
                doLoad()
            case .loading:
                resultClosures.append(completion)
            }
        }
    }
    
    public func load() {
        queue.sync {
            self.doLoad()
        }
    }
    
    public func reset() {
        queue.sync {
            switch state {
            case .loading, .initial: return
            case .storedValue:
                state = .initial
            }
        }
    }
    
    public func reload() {
        queue.sync {
            switch state {
            case .loading: return
            case .storedValue:
                state = .initial
                fallthrough
            case .initial: doLoad()
            }
        }
    }
    
    // This should always be called within queue.sync {}
    private func doLoad() {
        switch state {
        case .loading, .storedValue(_): return
        case .initial: break
        }
        
        // Force the loading function to be async.
        // Otherwise we'll deadlock if the user provides
        // a synchronous function.
        DispatchQueue.global(qos: .userInteractive).async {
            self.loadValue() { result in
                self.queue.sync {
                    for closure in self.resultClosures {
                        closure(result)
                    }
                    self.resultClosures = []
                }
                self.state = .storedValue(result)
            }
        }
        state = .loading
    }

    public init(loader: @escaping ( @escaping (Result<Value, ErrorType>) -> Void) -> Void) {
        self.loadValue = loader
    }
    
    private var queue = DispatchQueue(label: "AsyncProperty")
    
    private var state: State = .initial
        
    private var resultClosures: [(Result<Value, ErrorType>) -> Void] = []
        
    private var loadValue: (@escaping (Result<Value, ErrorType>) -> Void) -> Void
    
    private enum State {
        case initial
        case loading
        case storedValue(Result<Value, ErrorType>)
    }
    
}


