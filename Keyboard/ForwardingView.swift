//
//  ForwardingView.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class ForwardingView: UIView,UIGestureRecognizerDelegate {
    
    var touchToView: [UITouch:UIView]
	
	var gesture = UILongPressGestureRecognizer()
	
	var isLongPressEnable = false
	var isLongPressKeyPress = false
	
	var currentMode: Int = 0
	var keyboard_type: UIKeyboardType?
	
    override init(frame: CGRect) {
        self.touchToView = [:]
        
        super.init(frame: frame)
        
        self.contentMode = UIViewContentMode.Redraw
        self.multipleTouchEnabled = true
        self.userInteractionEnabled = true
        self.opaque = false
		
		gesture = UILongPressGestureRecognizer(target: self, action: "handleLongGesture:")
		
		gesture.minimumPressDuration = 0.5
		gesture.delegate = self
		gesture.cancelsTouchesInView = false
		self.addGestureRecognizer(gesture)
		
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
        if self.hidden || self.alpha == 0 || !self.userInteractionEnabled {
            return nil
        }
        else {
            return (CGRectContainsPoint(self.bounds, point) ? self : nil)
        }
    }
    
    func handleControl(view: UIView?, controlEvent: UIControlEvents) {
        if let control = view as? UIControl {
            let targets = control.allTargets()
            for target in targets {
                if var actions = control.actionsForTarget(target, forControlEvent: controlEvent) {
                    for action in actions {
                        if let selectorString = action as? String {
                            let selector = Selector(selectorString)
                            control.sendAction(selector, to: target, forEvent: nil)
                        }
                    }
                }
            }
        }
    }
	
	@IBAction func handleLongGesture(longPress: UIGestureRecognizer)
	{
		if (longPress.state == UIGestureRecognizerState.Ended)
		{
			//println("Ended")
			
			let position = longPress.locationInView(self)
			var view = findNearestView(position)
			
			if view is KeyboardKey
			{
				NSNotificationCenter.defaultCenter().postNotificationName("hideExpandViewNotification", object: nil)
			}
			
			isLongPressEnable = false
			
			isLongPressKeyPress = true
			
			if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
			{
				var keyboardKey = view as! KeyboardKey
				keyboardKey.highlighted = false
			}
			
			
		}
		else if (longPress.state == UIGestureRecognizerState.Began)
		{
			if (longPress.state == UIGestureRecognizerState.Began)
			{
				//println("Began")
				
				isLongPressEnable = true
				
				let position = longPress.locationInView(self)
				var view = findNearestView(position)
				
				var viewChangedOwnership = false
				
				if !viewChangedOwnership {
					
					if view is KeyboardKey
					{
						var v = view as! KeyboardKey
						if self.isLongPressEnableKey(v.text)
						{
							view!.tag = 888
							
							self.handleControl(view, controlEvent: .TouchDownRepeat)
						}
						
					}
				}
			}
		}
	}

	
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool
	{
		if gestureRecognizer is UILongPressGestureRecognizer
		{
			if (gestureRecognizer.state == UIGestureRecognizerState.Possible)
			{
				let position = touch.locationInView(self)
				var view = findNearestView(position)
				
				var viewChangedOwnership = false
				
				if !viewChangedOwnership {
					
					if view is KeyboardKey
					{
						var v = view as! KeyboardKey
						if self.isLongPressEnableKey(v.text)
						{
							return true
						}
					}
				}
				return false
			}
			else if (gestureRecognizer.state == UIGestureRecognizerState.Ended)
			{
				let position = gestureRecognizer.locationInView(self)
				var view = findNearestView(position)
				
				var viewChangedOwnership = false
				
				if !viewChangedOwnership {
					
					if view is KeyboardKey
					{
						var v = view as! KeyboardKey
						if self.isLongPressEnableKey(v.text)
						{
							return true
						}
					}
				}
				return false
			}
		}
		else
		{
			return true
		}
		return false
	}
	
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
	{
		return true
	}
	
    // TODO: there's a bit of "stickiness" to Apple's implementation
    func findNearestView(position: CGPoint) -> UIView? {
        if !self.bounds.contains(position) {
            return nil
        }
        
        var closest: (UIView, CGFloat)? = nil
        
        for anyView in self.subviews {
            if let view = anyView as? UIView {
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
    
    // reset tracked views without cancelling current touch
    func resetTrackedViews() {
        for view in self.touchToView.values {
            self.handleControl(view, controlEvent: .TouchCancel)
        }
        self.touchToView.removeAll(keepCapacity: true)
    }
	
	func resetPopUpViews() {
		for view in self.touchToView.values {
			
			var v = view as! KeyboardKey
			v.hidePopup()
		}
	}
	
    func ownView(newTouch: UITouch, viewToOwn: UIView?) -> Bool {
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
    
	override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
		// println("touchesBegan")
		for obj in touches {
			let touch = obj as! UITouch
			let position = touch.locationInView(self)
			var view = findNearestView(position)
			
			var viewChangedOwnership = self.ownView(touch, viewToOwn: view)
			
			if(isLongPressEnable == true)
			{
				if let v = view
				{
					if !viewChangedOwnership
					{
						self.handleControl(view, controlEvent: .TouchDown)
						//self.touchToView[touch] = nil
					}
				}
				
				NSNotificationCenter.defaultCenter().postNotificationName("hideExpandViewNotification", object: nil)
				isLongPressEnable = false
				
				if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
				{
					var keyboardKey = view as! KeyboardKey
					keyboardKey.highlighted = false
				}
				
			}
			else
			{
				if !viewChangedOwnership {
					self.handleControl(view, controlEvent: .TouchDown)
					
					if touch.tapCount > 1 {
						// two events, I think this is the correct behavior but I have not tested with an actual UIControl
						self.handleControl(view, controlEvent: .TouchDownRepeat)
					}
				}
			}
			
		}
	}
	
	override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
		//println("touchesMoved")
		for obj in touches
		{
			let touch = obj as! UITouch
			let position = touch.locationInView(self)
			
			if(isLongPressEnable)
			{
				var expandedButtonView : CYRKeyboardButtonView! = self.getCYRView()
				
				if expandedButtonView != nil
				{
					expandedButtonView.updateSelectedInputIndexForPoint(position)
				}
			}
			else
			{
				var oldView = self.touchToView[touch]
				var newView = findNearestView(position)
				
				if oldView != newView
				{
					self.handleControl(oldView, controlEvent: .TouchDragExit)
					
					var viewChangedOwnership = self.ownView(touch, viewToOwn: newView)
					
					if !viewChangedOwnership
					{
						self.handleControl(newView, controlEvent: .TouchDragEnter)
					}
					else
					{
						self.handleControl(newView, controlEvent: .TouchDragInside)
					}
				}
				else
				{
					self.handleControl(oldView, controlEvent: .TouchDragInside)
				}
			}
		}
	}
	
	override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
		for obj in touches {
			
			let touch = obj as! UITouch
			
			var view = self.touchToView[touch]
			
			let touchPosition = touch.locationInView(self)
			
			if(isLongPressKeyPress == true)
			{
				var expandedButtonView : CYRKeyboardButtonView! = self.getCYRView()
				if (expandedButtonView.selectedInputIndex != NSNotFound)
				{
					var inputOption = self.getCYRButton().inputOptions[expandedButtonView.selectedInputIndex] as! String
					
					self.resetPopUpViews()
					
					NSNotificationCenter.defaultCenter().postNotificationName("hideExpandViewNotification", object: nil, userInfo: ["text":inputOption])
				 
				}
				
				isLongPressKeyPress = false
				
				if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
				{
					var keyboardKey = view as! KeyboardKey
					keyboardKey.highlighted = false
				}
				
			}
			else
			{
				if self.bounds.contains(touchPosition)
				{
					self.handleControl(view, controlEvent: .TouchUpInside)
				}
				else
				{
					self.handleControl(view, controlEvent: .TouchCancel)
				}
				
				//self.touchToView[touch] = nil
			}
			
			self.touchToView[touch] = nil
		}
	}

    override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent!) {
        for obj in touches {
            if let touch = obj as? UITouch {
                var view = self.touchToView[touch]
                
                self.handleControl(view, controlEvent: .TouchCancel)
                
                self.touchToView[touch] = nil
            }
        }
    }
	
	func isLongPressEnableKey(text:NSString) -> Bool
	{
		var alphabet_lengh = text.length
		
		if(alphabet_lengh > 1)
		{
			return false
		}
		
		var alphaBets = NSCharacterSet(charactersInString: "AEUIOSDCNaeuiosdcn.")
		
		if text.rangeOfCharacterFromSet(alphaBets).location != NSNotFound
		{
			if self.currentMode == 0
			{
				if(keyboard_type == UIKeyboardType.DecimalPad || keyboard_type == UIKeyboardType.NumberPad)
				{
					return false
				}
				
				return true
			}
			
		}
		
		return false
	}
	
	func isSubViewContainsCYRView() -> Bool
	{
		for anyView in self.superview!.subviews
		{
			if anyView is CYRKeyboardButtonView
			{
				return true
			}
		}
		return false
	}
	
	func getCYRView() -> CYRKeyboardButtonView!
	{
		if isSubViewContainsCYRView()
		{
			for anyView in self.superview!.subviews
			{
				if anyView is CYRKeyboardButtonView
				{
					return anyView as! CYRKeyboardButtonView
				}
			}
		}
		
		return nil
	}
	
	func isSubViewContainsCYRButton() -> Bool
	{
		for anyView in self.superview!.subviews
		{
			if anyView is CYRKeyboardButton
			{
				return true
			}
		}
		return false
	}
	
	func getCYRButton() -> CYRKeyboardButton!
	{
		if isSubViewContainsCYRButton()
		{
			for anyView in self.superview!.subviews
			{
				if anyView is CYRKeyboardButton
				{
					return anyView as! CYRKeyboardButton
				}
			}
		}
		
		return nil
	}
	
}
