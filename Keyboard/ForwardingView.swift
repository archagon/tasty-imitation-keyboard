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
        
        let controlEvents = [
            UIControlEvents.TouchDownRepeat,
            UIControlEvents.TouchDragInside,
            UIControlEvents.TouchDragOutside,
            UIControlEvents.TouchDragEnter,
            UIControlEvents.TouchDragExit,
            UIControlEvents.TouchUpInside,
            UIControlEvents.TouchUpOutside,
            UIControlEvents.TouchCancel]
        
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
    
    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        let touch = touches.anyObject() as UITouch
        let position = touch.locationInView(self)
        var view = super.hitTest(position, withEvent: event)
        
        self.myView = view
        
        self.handleControl(self.myView, controlEvent: .TouchDown)
    }
    
    override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
        let touch = touches.anyObject() as UITouch
        let position = touch.locationInView(self)
        var view = super.hitTest(position, withEvent: event)
        
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
        var view = super.hitTest(position, withEvent: event)
        
        self.handleControl(view, controlEvent: .TouchUpInside)
    }
}
