//
//  NibView.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 10/29/16.
//  Copyright © 2016 SwiftBit. All rights reserved.
//

import UIKit
// https://gist.github.com/bwhiteley/049e4bede49e71a6d2e2

public protocol NibView: class {
    var contentView:UIView! { get set }
    
    var bounds:CGRect { get }
    func addSubview(_ view:UIView)
}

extension NibView {
    public func loadContentView(nibName: String? = nil) {
        guard let nibName = nibName ?? NSStringFromClass(type(of:self)).components(separatedBy: ".").last else {
            fatalError("Unable to determine nib name")
        }
        Bundle(for: type(of:self)).loadNibNamed(nibName, owner: self, options: nil)
        guard let contentView = self.contentView else {
            fatalError("contentView is nil after loading nib")
        }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(contentView)
    }
}
