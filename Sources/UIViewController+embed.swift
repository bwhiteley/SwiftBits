//
//  UIViewController+embed.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 4/29/17.
//  Copyright © 2017 SwiftBit. All rights reserved.
//

#if !os(macOS) && !os(watchOS)
import UIKit

public extension UIViewController {
    func embed(_ childVC: UIViewController) {
        addChild(childVC)
        self.view.embed(childVC.view)
        childVC.didMove(toParent: self)
    }
}
#endif
