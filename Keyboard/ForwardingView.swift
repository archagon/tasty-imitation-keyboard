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
		
		gesture = UILongPressGestureRecognizer(target: self, action: #selector(ForwardingView.handleLongGesture(_:)))
		
		gesture.minimumPressDuration = 0.5
		gesture.delegate = self
		gesture.cancelsTouchesInView = false
		self.addGestureRecognizer(gesture)
		
    }
    
    required init?(coder: NSCoder) {
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
                if let actions = control.actionsForTarget(target, forControlEvent: controlEvent) {
                    for action in actions {
                            let selector = Selector(action)
                            control.sendAction(selector, to: target, forEvent: nil)
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
			let view = findNearestView(position)
			
			if view is KeyboardKey
			{
				NSNotificationCenter.defaultCenter().postNotificationName("hideExpandViewNotification", object: nil)
			}
			
			isLongPressEnable = false
			
			isLongPressKeyPress = true
			
			if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
			{
				let keyboardKey = view as! KeyboardKey
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
				let view = findNearestView(position)
				
				let viewChangedOwnership = false
				
				if !viewChangedOwnership {
					
					if view is KeyboardKey
					{
						let v = view as! KeyboardKey
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
				let view = findNearestView(position)
				
				let viewChangedOwnership = false
				
				if !viewChangedOwnership {
					
					if view is KeyboardKey
					{
						let v = view as! KeyboardKey
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
				let view = findNearestView(position)
				
				let viewChangedOwnership = false
				
				if !viewChangedOwnership {
					
					if view is KeyboardKey
					{
						let v = view as! KeyboardKey
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
        
        for view in self.subviews {
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
    
    // reset tracked views without cancelling current touch
    func resetTrackedViews() {
        for view in self.touchToView.values {
            self.handleControl(view, controlEvent: .TouchCancel)
        }
        self.touchToView.removeAll(keepCapacity: true)
    }
	
	func resetPopUpViews() {
		for view in self.touchToView.values {
			
			let v = view as! KeyboardKey
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
    
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		// println("touchesBegan")
		for obj in touches {
			let touch = obj 
			let position = touch.locationInView(self)
			let view = findNearestView(position)
			
			let viewChangedOwnership = self.ownView(touch, viewToOwn: view)
			
			if(isLongPressEnable == true)
			{
				if view != nil
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
					let keyboardKey = view as! KeyboardKey
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
	
	override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		//println("touchesMoved")
		for obj in touches
		{
			let touch = obj 
			let position = touch.locationInView(self)
			
			if(isLongPressEnable)
			{
				let expandedButtonView : CYRKeyboardButtonView! = self.getCYRView()
				
				if expandedButtonView != nil
				{
					expandedButtonView.updateSelectedInputIndexForPoint(position)
				}
			}
			else
			{
				let oldView = self.touchToView[touch]
				let newView = findNearestView(position)
				
				if oldView != newView
				{
					self.handleControl(oldView, controlEvent: .TouchDragExit)
					
					let viewChangedOwnership = self.ownView(touch, viewToOwn: newView)
					
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
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		for obj in touches {
			
			let touch = obj 
			
			let view = self.touchToView[touch]
			
			let touchPosition = touch.locationInView(self)
			
			if(isLongPressKeyPress == true)
			{
				let expandedButtonView : CYRKeyboardButtonView! = self.getCYRView()
				if (expandedButtonView.selectedInputIndex != NSNotFound)
				{
					let inputOption = self.getCYRButton().inputOptions[expandedButtonView.selectedInputIndex] as! String
					
					self.resetPopUpViews()
					
					NSNotificationCenter.defaultCenter().postNotificationName("hideExpandViewNotification", object: nil, userInfo: ["text":inputOption])
				 
				}
				
				isLongPressKeyPress = false
				
				if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
				{
					let keyboardKey = view as! KeyboardKey
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

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        for obj in touches! {
                let view = self.touchToView[obj]
                
                self.handleControl(view, controlEvent: .TouchCancel)
                
                self.touchToView[obj] = nil
        }
    }
	
	func isLongPressEnableKey(text:NSString) -> Bool
	{
		let alphabet_lengh = text.length
		
		if(alphabet_lengh > 1)
		{
			return false
		}
		
		let alphaBets = NSCharacterSet(charactersInString: "AEUIOSDCNaeuiosdcn.")
		
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
