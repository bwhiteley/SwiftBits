//
//  AtomicProperty
//  SwiftBits
//
//  Created by Bart Whiteley on 11/2/16.
//

// https://talk.objc.io/episodes/S01E42-thread-safety-reactive-programming-5
final class AtomicProperty<A> {
    private var queue = DispatchQueue(label: "com.swift-bit.AtomicProperty")
    private var _value: A
    init(_ value: A) {
        self._value = value
    }
    
    var value: A {
        return queue.sync { self._value }
    }
    
    func mutate<Value>(_ transform: (inout A) -> Value) -> Value {
        return queue.sync {
            transform(&self._value)
        }
    }
}
