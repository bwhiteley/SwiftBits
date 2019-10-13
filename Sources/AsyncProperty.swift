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
                self.resultClosures.append(completion)
            }
        }
    }
    
    public func load() {
        queue.sync {
            self.doLoad()
        }
    }
    
    private func doLoad() {
        switch self.state {
        case .loading, .storedValue(_): return
        case .initial: break
        }
        
        self.loadValue() { result in
            self.queue.sync {
                for closure in self.resultClosures {
                    closure(result)
                }
                self.resultClosures = []
            }
            self.state = .storedValue(result)
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


