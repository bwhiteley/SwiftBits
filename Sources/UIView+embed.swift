//
//  UIView+embed.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 3/18/17.
//  Copyright © 2017 SwiftBit. All rights reserved.
//

import UIKit

public extension UIView {
    private func pinToEdges(of other: UIView) {
        NSLayoutConstraint.activate([
            other.topAnchor.constraint(equalTo: self.topAnchor),
            other.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            other.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            other.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
    }
    
    public func embed(_ view: UIView) {
        self.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.pinToEdges(of: self)
    }
}
