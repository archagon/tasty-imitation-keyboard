//
//  ForwardingView.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

class ForwardingView: UIView {
    
    var touchToView: [UITouch:UIView] = [:]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentMode = UIViewContentMode.redraw
        self.isMultipleTouchEnabled = true
        self.isUserInteractionEnabled = true
        self.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    // Why have this useless drawRect? Well, if we just set the backgroundColor to clearColor,
    // then some weird optimization happens on UIKit's side where tapping down on a transparent pixel will
    // not actually recognize the touch. Having a manual drawRect fixes this behavior, even though it doesn't
    // actually do anything.
    override func draw(_ rect: CGRect) {}
    
    override func hitTest(_ point: CGPoint, with event: UIEvent!) -> UIView? {
        if self.isHidden || self.alpha == 0 || !self.isUserInteractionEnabled {
            return nil
        }
        else {
            return (self.bounds.contains(point) ? self : nil)
        }
    }
    
    func handleControl(_ view: UIView?, controlEvent: UIControlEvents) {
        if let control = view as? UIControl {
            let targets = control.allTargets
            for target in targets {
                if let actions = control.actions(forTarget: target, forControlEvent: controlEvent) {
                    for action in actions {
                        let selectorString = action
                        let selector = Selector(selectorString)
                        control.sendAction(selector, to: target, for: nil)
                    }
                    
                }
            }
        }
    }
    
    // TODO: there's a bit of "stickiness" to Apple's implementation
    func findNearestView(_ position: CGPoint) -> UIView? {
        if !self.bounds.contains(position) {
            return nil
        }
        
        var closest: (UIView, CGFloat)? = nil
        
        for anyView in self.subviews {
            let view = anyView
            if view.isHidden {
                continue
            }
            
            view.alpha = 1
            
            let distance = distanceBetween(view.frame, point: position)
            
            if closest != nil {
                if distance < closest!.1 {
                    closest = (view, distance)
                }
            }
            else {
                closest = (view, distance)
            }
        }
        
        if closest != nil {
            return closest!.0
        }
        else {
            return nil
        }
    }
    
    // http://stackoverflow.com/questions/3552108/finding-closest-object-to-cgpoint b/c I'm lazy
    func distanceBetween(_ rect: CGRect, point: CGPoint) -> CGFloat {
        if rect.contains(point) {
            return 0
        }

        var closest = rect.origin
        
        if (rect.origin.x + rect.size.width < point.x) {
            closest.x += rect.size.width
        }
        else if (point.x > rect.origin.x) {
            closest.x = point.x
        }
        if (rect.origin.y + rect.size.height < point.y) {
            closest.y += rect.size.height
        }
        else if (point.y > rect.origin.y) {
            closest.y = point.y
        }
        
        let a = pow(Double(closest.y - point.y), 2)
        let b = pow(Double(closest.x - point.x), 2)
        return CGFloat(sqrt(a + b));
    }
    
    // reset tracked views without cancelling current touch
    func resetTrackedViews() {
        for view in self.touchToView.values {
            self.handleControl(view, controlEvent: .touchCancel)
        }
        self.touchToView.removeAll(keepingCapacity: true)
    }
    
    func ownView(_ newTouch: UITouch, viewToOwn: UIView?) -> Bool {
        var foundView = false
        
        if viewToOwn != nil {
            for (touch, view) in self.touchToView {
                if viewToOwn == view {
                    if touch == newTouch {
                        break
                    }
                    else {
                        self.touchToView[touch] = nil
                        foundView = true
                    }
                    break
                }
            }
        }
        
        self.touchToView[newTouch] = viewToOwn
        return foundView
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let position = touch.location(in: self)
            let view = findNearestView(position)
            
            let viewChangedOwnership = self.ownView(touch, viewToOwn: view)
            
            if !viewChangedOwnership {
                self.handleControl(view, controlEvent: .touchDown)
                
                if touch.tapCount > 1 {
                    // two events, I think this is the correct behavior but I have not tested with an actual UIControl
                    self.handleControl(view, controlEvent: .touchDownRepeat)
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let position = touch.location(in: self)
            
            let oldView = self.touchToView[touch]
            let newView = findNearestView(position)
            
            if oldView != newView {
                self.handleControl(oldView, controlEvent: .touchDragExit)
                
                let viewChangedOwnership = self.ownView(touch, viewToOwn: newView)
                
                if !viewChangedOwnership {
                    self.handleControl(newView, controlEvent: .touchDragEnter)
                }
                else {
                    self.handleControl(newView, controlEvent: .touchDragInside)
                }
            }
            else {
                self.handleControl(oldView, controlEvent: .touchDragInside)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let view = self.touchToView[touch]
            
            let touchPosition = touch.location(in: self)
            
            if self.bounds.contains(touchPosition) {
                self.handleControl(view, controlEvent: .touchUpInside)
            }
            else {
                self.handleControl(view, controlEvent: .touchCancel)
            }
            
            self.touchToView[touch] = nil
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let view = self.touchToView[touch]
            
            self.handleControl(view, controlEvent: .touchCancel)
            
            self.touchToView[touch] = nil
        }
    }
}
