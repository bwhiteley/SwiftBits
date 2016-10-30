//
//  UITableView.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 10/29/16.
//  Copyright © 2016 SwiftBit. All rights reserved.
//

import UIKit

extension UITableView {
    public func indexPathForRow(containing view:UIView) -> IndexPath? {
        if view.superview == nil {
            return nil
        }
        let point = self.convert(view.center, from: view.superview)
        return self.indexPathForRow(at: point)
    }
}
