//https://gist.github.com/khanlou/2dc012e356fd372ecba845752d9a938a

import Foundation

final class SafeSyncQueue {
    
    struct QueueIdentity {
        let label: String
    }
    
    let queue: DispatchQueue
    
    fileprivate let queueKey: DispatchSpecificKey<QueueIdentity>
    
    init(label: String) {
        self.queue = DispatchQueue(label: "com.swift-bit.\(label).SafeSyncQueue")
        self.queueKey = DispatchSpecificKey<QueueIdentity>()
        self.queue.setSpecific(key: queueKey, value: QueueIdentity(label: queue.label))
    }
    
    fileprivate var currentQueueIdentity: QueueIdentity? {
        return DispatchQueue.getSpecific(key: queueKey)
    }
    
    func sync<A>(execute: () throws -> A) rethrows -> A {
        if currentQueueIdentity?.label == queue.label {
            return try execute()
        } else {
            return try queue.sync(execute: execute)
        }
    }
}
