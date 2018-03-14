//
//  UIResponder+FirstResponder.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 12/22/16.
//  Copyright © 2016 SwiftBit. All rights reserved.
//

import Foundation
import UIKit

weak private var _firstResponder:AnyObject?

extension UIResponder {
    
    public class func currentFirstResponder() -> AnyObject? {
        _firstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _firstResponder
    }
    
    @objc private func findFirstResponder(_ sender:AnyObject) {
        _firstResponder = self
    }
}
