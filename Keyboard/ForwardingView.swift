//
//  ForwardingView.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class ForwardingView: UIView {
    
    var activeTouches: [Int]
    var multiTapTimers: [Int: NSTimer]
    var touchToView: [UITouch:UIView]
    
    override init(frame: CGRect) {
        self.activeTouches = []
        self.multiTapTimers = [:]
        self.touchToView = [:]
        
        super.init(frame: frame)
        
        self.contentMode = UIViewContentMode.Redraw
        self.multipleTouchEnabled = true
        self.userInteractionEnabled = true
        self.opaque = false
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    // Why have this useless drawRect? Well, if we just set the backgroundColor to clearColor,
    // then some weird optimization happens on UIKit's side where tapping down on a transparent pixel will
    // not actually recognize the touch. Having a manual drawRect fixes this behavior, even though it doesn't
    // actually do anything.
    override func drawRect(rect: CGRect) {}
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent!) -> UIView? {
        return (CGRectContainsPoint(self.bounds, point) ? self : nil)
    }
    
    func handleControl(view: UIView?, controlEvent: UIControlEvents) {
        if let control = view as? UIControl {
            let targets = control.allTargets()
            for target in targets.allObjects { // TODO: Xcode crashes
                var actions = control.actionsForTarget(target, forControlEvent: controlEvent)
                if (actions != nil) {
                    for action in actions! {
                        let selector = Selector(action as String)
                        control.sendAction(selector, to: target, forEvent: nil)
                    }
                }
            }
        }
    }
    
    // TODO: there's a bit of "stickiness" to Apple's implementation
    func findNearestView(position: CGPoint) -> UIView? {
        var closest: (UIView, CGFloat)? = nil
        
        for anyView in self.subviews {
            let view = anyView as UIView
            
            if view.hidden {
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
    func distanceBetween(rect: CGRect, point: CGPoint) -> CGFloat {
        if CGRectContainsPoint(rect, point) {
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
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for obj in touches {
            let touch = obj as UITouch
            let position = touch.locationInView(self)
            var view = findNearestView(position)
            
            self.touchToView[touch] = view
            
            self.handleControl(view, controlEvent: .TouchDown)
            
            if touch.tapCount > 1 {
                // two events, I think this is the correct behavior but I have not tested with an actual UIControl
                self.handleControl(view, controlEvent: .TouchDownRepeat)
            }
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        for obj in touches {
            let touch = obj as UITouch
            let position = touch.locationInView(self)
            
            var view = self.touchToView[touch]
            var newView = findNearestView(position)
            
            if view != newView {
                self.handleControl(view, controlEvent: .TouchUpOutside)
                self.touchToView[touch] = newView
                self.handleControl(newView, controlEvent: .TouchDown)
            }
            else {
                self.handleControl(view, controlEvent: .TouchDragInside)
            }
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        for obj in touches {
            let touch = obj as UITouch
            
            var view = self.touchToView[touch]
            
            self.handleControl(view, controlEvent: .TouchUpInside)
        }
    }

    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        for obj in touches {
            let touch = obj as UITouch
            
            var view = self.touchToView[touch]
            
            self.handleControl(view, controlEvent: .TouchCancel)
        }
    }
}
