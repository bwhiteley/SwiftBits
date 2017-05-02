//
//  UIViewController+embed.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 4/29/17.
//  Copyright © 2017 SwiftBit. All rights reserved.
//

import UIKit

public extension UIViewController {
    public func embed(_ childVC: UIViewController) {
        addChildViewController(childVC)
        self.view.embed(childVC.view)
        childVC.didMove(toParentViewController: self)
    }
}
