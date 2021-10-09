//
//  Storyboarded.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 10/29/16.
//  Copyright © 2016 SwiftBit. All rights reserved.
//

#if !os(macOS) && !os(watchOS)
import UIKit

public protocol Storyboarded: AnyObject {
    static func storyboardInfo() -> (storyboardName:String, storyboardId:String?)
}

extension Storyboarded {
    public static func createFromStoryboard() -> Self {
        let info = self.storyboardInfo()
        let storyboard = UIStoryboard(name: info.storyboardName, bundle: Bundle(for: self))
        if let storyboardId = info.storyboardId {
            return storyboard.instantiateViewController(withIdentifier: storyboardId) as! Self
        }
        else {
            return storyboard.instantiateInitialViewController() as! Self
        }
    }
}
#endif
