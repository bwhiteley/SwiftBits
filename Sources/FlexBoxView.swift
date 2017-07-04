//
//  FlexBoxView.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 7/1/17.
//  Copyright © 2017 SwiftBit. All rights reserved.
//

import UIKit

@IBDesignable
public class FlexBoxView: UIView {
    
    
    
    public enum Axis {
        case horizontal
        case vertical
    }
    
    struct ManagedView {
        let view: UIView
        var relativeSize: CGFloat
    }
    
    @IBInspectable public var horizontal: Bool {
        get {
            return self.axis == .horizontal
        }
        set {
            self.axis = newValue ? .horizontal : .vertical
        }
    }
    
    var axis: Axis = .horizontal {
        willSet {
            guard views.count == 0 else {
                fatalError("Cannot change axis after adding views")
            }
        }
    }
    
    public init(axis: Axis) {
        self.axis = axis
        super.init(frame: .zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var views: [ManagedView] = []
    
    var managedConstraints: [NSLayoutConstraint] = []
    
    public func add(view: UIView, relativeSize: CGFloat) {
        let managed: ManagedView = ManagedView(view: view, relativeSize: relativeSize)
        views.append(managed)
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        switch axis {
        case .horizontal:
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: self.topAnchor),
                view.bottomAnchor.constraint(equalTo: self.bottomAnchor)
                ])
        case .vertical:
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: self.trailingAnchor)
                ])
        }
    }
    
    public func render() {
        managedConstraints.forEach { $0.isActive = false }
        managedConstraints = []
        buildConstraints()
        setNeedsUpdateConstraints()
    }
    
    func buildConstraints() {
        let activeViews: [ManagedView] = views.filter { $0.view.isHidden == false }
        
        if let first = activeViews.first {
            let c: NSLayoutConstraint
            if axis == .horizontal {
                c = self.leadingAnchor.constraint(equalTo: first.view.leadingAnchor)
            }
            else {
                c = self.topAnchor.constraint(equalTo: first.view.topAnchor)
            }
            managedConstraints.append(c)
        }
        
        if let last = activeViews.last {
            let c: NSLayoutConstraint
            if axis == .horizontal {
                c = self.trailingAnchor.constraint(equalTo: last.view.trailingAnchor)
            }
            else {
                c = self.bottomAnchor.constraint(equalTo: last.view.bottomAnchor)
            }
            managedConstraints.append(c)
        }
        
        for (index, current) in activeViews.enumerated() {
            let nextIndex = index + 1
            guard nextIndex < activeViews.count else { break }
            let curView = current.view
            let nextView = activeViews[nextIndex].view
            let c: NSLayoutConstraint
            if axis == .horizontal {
                c = curView.trailingAnchor.constraint(equalTo: nextView.leadingAnchor)
            }
            else {
                c = curView.bottomAnchor.constraint(equalTo: nextView.topAnchor)
            }
            managedConstraints.append(c)
        }

        let totalSize: CGFloat = activeViews.reduce(CGFloat(0), { $0 + $1.relativeSize })
        if activeViews.count > 1 {
            activeViews.forEach { let (managed) = $0
                let multiplier: CGFloat = managed.relativeSize / totalSize
                let c: NSLayoutConstraint
                if axis == .horizontal {
                    c = NSLayoutConstraint(item: managed.view, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: multiplier, constant: 0)
                }
                else {
                    c = NSLayoutConstraint(item: managed.view, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: multiplier, constant: 0)
                }
                managedConstraints.append(c)
            }
        }
        
        NSLayoutConstraint.activate(managedConstraints)
        
    }
    
    
}

