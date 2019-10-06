//
//  HostingView.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 10/5/19.
//  Copyright © 2019 SwiftBit. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

@available(iOS 13.0, *)
open class HostingView<Content> : UIView where Content : View {
    
    private let hostingVC: UIHostingController<Content>
    
    public var rootView: Content {
        get { return hostingVC.rootView }
        set { hostingVC.rootView = newValue }
    }

    public init(rootView: Content) {
        self.hostingVC = UIHostingController(rootView: rootView)
        super.init(frame: .zero)
        addSubview(hostingVC.view)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
                   hostingVC.view.topAnchor.constraint(equalTo: self.topAnchor),
                   hostingVC.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                   hostingVC.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                   hostingVC.view.trailingAnchor.constraint(equalTo: self.trailingAnchor)
                   ])
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
