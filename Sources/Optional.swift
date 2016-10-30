//
//  Optional.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 10/29/16.
//  Copyright © 2016 SwiftBit. All rights reserved.
//

extension Optional {
    public func apply(f: (Wrapped) throws -> Void) rethrows {
        if let v = self {
            try f(v)
        }
    }
}
