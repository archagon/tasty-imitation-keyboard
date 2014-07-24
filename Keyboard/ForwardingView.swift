//
//  ForwardingView.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class ForwardingView: UIView {
    
    init(frame: CGRect) {
        super.init(frame: frame)
        self.multipleTouchEnabled = false
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1) // QQQ: temp fix for missed touches
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent!) -> UIView! {
        return self
    }
    
    var myView: UIView?
    
    // TODO: drag up control centre from bottom == stuck
    func handleControl(view: UIView?, controlEvent: UIControlEvents) {
        if !view {
            return
        }
        
        if !(view is UIControl) {
            return
        }
        
        let control = view! as UIControl
        
        switch controlEvent {
        case
        UIControlEvents.TouchDown,
        UIControlEvents.TouchDragEnter:
            control.highlighted = true
        case
        UIControlEvents.TouchDragExit,
        UIControlEvents.TouchUpInside,
        UIControlEvents.TouchUpOutside,
        UIControlEvents.TouchCancel:
            control.highlighted = false
        default:
            break
        }
        
        let targets = control.allTargets()
        if targets {
            for target in targets.allObjects { // TODO: Xcode crashes
                var actions = control.actionsForTarget(target, forControlEvent: controlEvent)
                if actions {
                    for action in actions {
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
            
            if closest {
                if distance < closest!.1 {
                    closest = (view, distance)
                }
            }
            else {
                closest = (view, distance)
            }
        }
        
        if closest {
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
    
    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        let touch = touches.anyObject() as UITouch
        let position = touch.locationInView(self)
        var view = findNearestView(position)
        
        self.myView = view
        
        self.handleControl(self.myView, controlEvent: .TouchDown)
    }
    
    override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
        let touch = touches.anyObject() as UITouch
        let position = touch.locationInView(self)
        var view = findNearestView(position)
        
        if view != self.myView {
            self.handleControl(self.myView, controlEvent: .TouchUpOutside)
            
            self.myView = view
            
            self.handleControl(self.myView, controlEvent: .TouchDown)
        }
        else {
            self.handleControl(self.myView, controlEvent: .TouchDragInside)
        }
    }
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!)  {
        let touch = touches.anyObject() as UITouch
        let position = touch.locationInView(self)
        var view = findNearestView(position)
        
        self.handleControl(view, controlEvent: .TouchUpInside)
    }
}
