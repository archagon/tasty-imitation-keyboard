//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit
import AudioToolbox

enum TTDeviceType{
	case TTDeviceTypeIPhone4
	case TTDeviceTypeIPhone5
	case TTDeviceTypeIPhone6
	case TTDeviceTypeIPhone6p
	
}

var deviceType = TTDeviceType.TTDeviceTypeIPhone5

let metrics: [String:Double] = [
    "topBanner": 30
]
func metric(name: String) -> CGFloat { return CGFloat(metrics[name]!) }

// TODO: move this somewhere else and localize
let kAutoCapitalization = "kAutoCapitalization"
let kPeriodShortcut = "kPeriodShortcut"
let kKeyboardClicks = "kKeyboardClicks"
let kSmallLowercase = "kSmallLowercase"

class KeyboardViewController: UIInputViewController {
    
    let backspaceDelay: NSTimeInterval = 0.5
    let backspaceRepeat: NSTimeInterval = 0.07
    
    var keyboard: Keyboard!
    var forwardingView: ForwardingView!
    var layout: KeyboardLayout?
    var heightConstraint: NSLayoutConstraint?
    
    var bannerView: ExtraView?
    var settingsView: ExtraView?
    
    var currentMode: Int {
        didSet {
            if oldValue != currentMode {
                setMode(currentMode)
            }
			
			forwardingView.currentMode = currentMode
			forwardingView.keyboard_type = keyboard_type
        }
    }
	
    var backspaceActive: Bool {
        get {
            return (backspaceDelayTimer != nil) || (backspaceRepeatTimer != nil)
        }
    }
    var backspaceDelayTimer: NSTimer?
    var backspaceRepeatTimer: NSTimer?
    
    enum AutoPeriodState {
        case NoSpace
        case FirstSpace
    }
    
    var autoPeriodState: AutoPeriodState = .NoSpace
    var lastCharCountInBeforeContext: Int = 0
    
    var shiftState: ShiftState {
        didSet {
            switch shiftState {
            case .Disabled:
                self.updateKeyCaps(false)
            case .Enabled:
                self.updateKeyCaps(true)
            case .Locked:
                self.updateKeyCaps(true)
            }
        }
    }
    
    // state tracking during shift tap
    var shiftWasMultitapped: Bool = false
    var shiftStartingState: ShiftState?
    
    var keyboardHeight: CGFloat {
        get {
            if let constraint = self.heightConstraint {
                return constraint.constant
            }
            else {
                return 0
            }
        }
        set {
            self.setHeight(newValue)
        }
    }
	
	//MARK:- Extra variables for extra features
	var sug_word : String = ""
	
	var viewLongPopUp:CYRKeyboardButtonView = CYRKeyboardButtonView()
	var button = CYRKeyboardButton()
	
	var isAllowFullAccess : Bool = false
	
	var keyboard_type: UIKeyboardType!
	var preKeyboardType = UIKeyboardType.Default
	
	var key_type: Bool!
	
    // TODO: why does the app crash if this isn't here?
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        NSUserDefaults.standardUserDefaults().registerDefaults([
            kAutoCapitalization: true,
            kPeriodShortcut: true,
            kKeyboardClicks: false,
            kSmallLowercase: false
        ])
        
        //self.keyboard = defaultKeyboard()
		
		self.shiftState = .Disabled
		self.currentMode = 0
		
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		
		self.forwardingView = ForwardingView(frame: CGRectZero)
		self.view.addSubview(self.forwardingView)
		
		if var aBanner = self.createBanner()
		{
			
			aBanner.btn1.addTarget(self, action: "didTapSuggestionButton:", forControlEvents:UIControlEvents.TouchUpInside | UIControlEvents.TouchUpOutside | UIControlEvents.TouchDragOutside)
			aBanner.btn2.addTarget(self, action: "didTapSuggestionButton:", forControlEvents: UIControlEvents.TouchUpInside | UIControlEvents.TouchUpOutside | UIControlEvents.TouchDragOutside)
			aBanner.btn3.addTarget(self, action: "didTapSuggestionButton:", forControlEvents: UIControlEvents.TouchUpInside | UIControlEvents.TouchUpOutside | UIControlEvents.TouchDragOutside)
			
			
			aBanner.btn1.addTarget(self, action: "didTTouchDownSuggestionButton:", forControlEvents:.TouchDown | .TouchDragInside | .TouchDragEnter)
			aBanner.btn2.addTarget(self, action: "didTTouchDownSuggestionButton:", forControlEvents:.TouchDown | .TouchDragInside | .TouchDragEnter)
			aBanner.btn3.addTarget(self, action: "didTTouchDownSuggestionButton:", forControlEvents:.TouchDown | .TouchDragInside | .TouchDragEnter)
			
			aBanner.btn1.addTarget(self, action: "didTTouchExitDownSuggestionButton:", forControlEvents:.TouchDragExit | .TouchCancel)
			aBanner.btn2.addTarget(self, action: "didTTouchExitDownSuggestionButton:", forControlEvents:.TouchDragExit | .TouchCancel)
			aBanner.btn3.addTarget(self, action: "didTTouchExitDownSuggestionButton:", forControlEvents:.TouchDragExit | .TouchCancel)
			
			
			
			aBanner.hidden = true
			self.view.insertSubview(aBanner, aboveSubview: self.forwardingView)
			self.bannerView = aBanner
			
		}
		
		initializePopUp()
		
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("defaultsChanged:"), name: NSUserDefaultsDidChangeNotification, object: nil)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("hideExpandView:"), name: "hideExpandViewNotification", object: nil)
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    deinit {
        backspaceDelayTimer?.invalidate()
        backspaceRepeatTimer?.invalidate()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func defaultsChanged(notification: NSNotification) {
        let defaults = notification.object as? NSUserDefaults
        self.updateKeyCaps(self.shiftState.uppercase())
    }
    
    // without this here kludge, the height constraint for the keyboard does not work for some reason
    var kludge: UIView?
    func setupKludge() {
        if self.kludge == nil {
            var kludge = UIView()
            self.view.addSubview(kludge)
            kludge.setTranslatesAutoresizingMaskIntoConstraints(false)
            kludge.hidden = true
            
            let a = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0)
            let b = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0)
            let c = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
            let d = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
            self.view.addConstraints([a, b, c, d])
            
            self.kludge = kludge
        }
    }
    
    /*
    BUG NOTE

    For some strange reason, a layout pass of the entire keyboard is triggered 
    whenever a popup shows up, if one of the following is done:

    a) The forwarding view uses an autoresizing mask.
    b) The forwarding view has constraints set anywhere other than init.

    On the other hand, setting (non-autoresizing) constraints or just setting the
    frame in layoutSubviews works perfectly fine.

    I don't really know what to make of this. Am I doing Autolayout wrong, is it
    a bug, or is it expected behavior? Perhaps this has to do with the fact that
    the view's frame is only ever explicitly modified when set directly in layoutSubviews,
    and not implicitly modified by various Autolayout constraints
    (even though it should really not be changing).
    */
    
    var constraintsAdded: Bool = false
    func setupLayout() {
        if !constraintsAdded {
			
			var proxy = textDocumentProxy as! UITextDocumentProxy
			self.keyboard = defaultKeyboard(proxy.keyboardType!)
			
			preKeyboardType = proxy.keyboardType!
			
			
			
            self.layout = self.dynamicType.layoutClass(model: self.keyboard, superview: self.forwardingView, layoutConstants: self.dynamicType.layoutConstants, globalColors: self.dynamicType.globalColors, darkMode: self.darkMode(), solidColorMode: self.solidColorMode())
            
            self.layout?.initialize()
            self.setMode(0)
            
            self.setupKludge()
            
            self.updateKeyCaps(self.shiftState.uppercase())
            var capsWasSet = self.setCapsIfNeeded()
            
            self.updateAppearances(self.darkMode())
            self.addInputTraitsObservers()
            
            self.constraintsAdded = true
        }
    }
    
    // only available after frame becomes non-zero
    func darkMode() -> Bool {
        var darkMode = { () -> Bool in
            if let proxy = self.textDocumentProxy as? UITextDocumentProxy {
                return proxy.keyboardAppearance == UIKeyboardAppearance.Dark
            }
            else {
                return false
            }
        }()
        
        return darkMode
    }
    
    func solidColorMode() -> Bool {
        return UIAccessibilityIsReduceTransparencyEnabled()
    }
    
    var lastLayoutBounds: CGRect?
	override func viewDidLayoutSubviews() {
		if view.bounds == CGRectZero {
			return
		}
		
		self.setupLayout()
		
		let orientationSavvyBounds = CGRectMake(0, 0, self.view.bounds.width, self.heightForOrientation(self.interfaceOrientation, withTopBanner: false))
		
		if (lastLayoutBounds != nil && lastLayoutBounds == orientationSavvyBounds) {
			// do nothing
		}
		else {            let uppercase = self.shiftState.uppercase()
			let characterUppercase = (NSUserDefaults.standardUserDefaults().boolForKey(kSmallLowercase) ? uppercase : true)
			
			self.forwardingView.frame = orientationSavvyBounds
			self.layout?.layoutKeys(self.currentMode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
			self.lastLayoutBounds = orientationSavvyBounds
			self.setupKeys()
		}
		
		self.bannerView?.frame = CGRectMake(0, 0, self.view.bounds.width, metric("topBanner"))
		
		var proxy = textDocumentProxy as! UITextDocumentProxy
		
		if proxy.keyboardType == UIKeyboardType.NumberPad || proxy.keyboardType == UIKeyboardType.DecimalPad
		{
			self.bannerView!.hidden = true
		}
		else
		{
			self.bannerView!.hidden = false
		}
		
		let newOrigin = CGPointMake(0, self.view.bounds.height - self.forwardingView.bounds.height)
		self.forwardingView.frame.origin = newOrigin
		
	}
	
    override func loadView() {
        super.loadView()
		
        if var aBanner = self.createBanner() {
            aBanner.hidden = true
            self.view.insertSubview(aBanner, belowSubview: self.forwardingView)
            self.bannerView = aBanner
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.bannerView?.hidden = false
        self.keyboardHeight = self.heightForOrientation(self.interfaceOrientation, withTopBanner: true)
    }
	
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        // optimization: ensures smooth animation
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = true
            }
        }
        
        self.keyboardHeight = self.heightForOrientation(toInterfaceOrientation, withTopBanner: true)
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        // optimization: ensures quick mode and shift transitions
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = false
            }
        }
    }
	
	func isCapitalalize(string: String) -> Bool
	{
		if count(string) > 0
		{
			var firstChar = string[string.startIndex]
			return ("A"..."Z").contains(firstChar)
		}
		else
		{
			return false
		}
		
	}
	
	func hideExpandView(notification: NSNotification)
	{
		
		if notification.userInfo != nil
		{
			var title = notification.userInfo!["text"] as! String
			if let proxy = (self.textDocumentProxy as? UIKeyInput)
			{
				if self.shiftState == .Enabled
				{
					proxy.insertText(title.capitalizedString)
				}
				else if self.shiftState == .Locked
				{
					proxy.insertText(title.uppercaseString)
				}
				else
				{
					proxy.insertText(title)
				}
				
			}
			
			if (isAllowFullAccess == true)
			{
//				isSuggestionBlank = false
//				get_suggestion()
//				setPredictionAndSuggestion()
			}
			self.setCapsIfNeeded()
			
		}
		
		if self.forwardingView.isLongPressEnable == false
		{
			self.view.bringSubviewToFront(self.bannerView!)
		}
		viewLongPopUp.hidden = true
		//self.forwardingView.resetTrackedViews()
		
	}
	
	func heightForOrientation(orientation: UIInterfaceOrientation, withTopBanner: Bool) -> CGFloat {
		let isPad = UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
		
		//TODO: hardcoded stuff
		let actualScreenWidth = (UIScreen.mainScreen().nativeBounds.size.width /
			UIScreen.mainScreen().nativeScale)
		
		let canonicalPortraitHeight = (isPad ? CGFloat(264) : CGFloat(orientation.isPortrait && actualScreenWidth >= 400 ? 226 : 216))
		let canonicalLandscapeHeight = (isPad ? CGFloat(352) : CGFloat(162))
		
		var topBannerHeight = (withTopBanner ? metric("topBanner") : 0)
		var proxy = textDocumentProxy as! UITextDocumentProxy
		
		if proxy.keyboardType == UIKeyboardType.NumberPad || proxy.keyboardType == UIKeyboardType.DecimalPad
		{
			return CGFloat(orientation.isPortrait ? canonicalPortraitHeight + 0 : canonicalLandscapeHeight + 0)
		}
		else
		{
			return CGFloat(orientation.isPortrait ? canonicalPortraitHeight + topBannerHeight : canonicalLandscapeHeight + topBannerHeight)
		}
		
	}
    /*
    BUG NOTE

    None of the UIContentContainer methods are called for this controller.
    */
	
    //override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    //    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    //}
	
    func setupKeys() {
        if self.layout == nil {
            return
        }
		
        for page in keyboard.pages {
            for rowKeys in page.rows { // TODO: quick hack
                for key in rowKeys {
                    if let keyView = self.layout?.viewForKey(key) {
                        keyView.removeTarget(nil, action: nil, forControlEvents: UIControlEvents.AllEvents)
						
                        switch key.type {
                        case Key.KeyType.KeyboardChange:
                            keyView.addTarget(self, action: "advanceTapped:", forControlEvents: .TouchUpInside)
                        case Key.KeyType.Backspace:
                            let cancelEvents: UIControlEvents = UIControlEvents.TouchUpInside|UIControlEvents.TouchUpInside|UIControlEvents.TouchDragExit|UIControlEvents.TouchUpOutside|UIControlEvents.TouchCancel|UIControlEvents.TouchDragOutside
                            
                            keyView.addTarget(self, action: "backspaceDown:", forControlEvents: .TouchDown)
                            keyView.addTarget(self, action: "backspaceUp:", forControlEvents: cancelEvents)
                        case Key.KeyType.Shift:
                            keyView.addTarget(self, action: Selector("shiftDown:"), forControlEvents: .TouchDown)
                            keyView.addTarget(self, action: Selector("shiftUp:"), forControlEvents: .TouchUpInside)
                            keyView.addTarget(self, action: Selector("shiftDoubleTapped:"), forControlEvents: .TouchDownRepeat)
                        case Key.KeyType.ModeChange:
                            keyView.addTarget(self, action: Selector("modeChangeTapped:"), forControlEvents: .TouchDown)
                        case Key.KeyType.Settings:
                            keyView.addTarget(self, action: Selector("toggleSettings"), forControlEvents: .TouchUpInside)
                        default:
                            break
                        }
                        
                        if key.isCharacter {
                            if UIDevice.currentDevice().userInterfaceIdiom != UIUserInterfaceIdiom.Pad {
                                keyView.addTarget(self, action: Selector("showPopup:"), forControlEvents: .TouchDown | .TouchDragInside | .TouchDragEnter)
                                keyView.addTarget(keyView, action: Selector("hidePopup"), forControlEvents: .TouchDragExit | .TouchCancel)
                                keyView.addTarget(self, action: Selector("hidePopupDelay:"), forControlEvents: .TouchUpInside | .TouchUpOutside | .TouchDragOutside)
                            }
							
							keyView.addTarget(self, action: Selector("keyCharDoubleTapped:"), forControlEvents: .TouchDownRepeat)
                        }
                        
                        if key.hasOutput {
                            keyView.addTarget(self, action: "keyPressedHelper:", forControlEvents: .TouchUpInside)
                        }
                        
                        if key.type != Key.KeyType.Shift && key.type != Key.KeyType.ModeChange {
                            keyView.addTarget(self, action: Selector("highlightKey:"), forControlEvents: .TouchDown | .TouchDragInside | .TouchDragEnter)
                            keyView.addTarget(self, action: Selector("unHighlightKey:"), forControlEvents: .TouchUpInside | .TouchUpOutside | .TouchDragOutside | .TouchDragExit | .TouchCancel)
                        }
                        
                        keyView.addTarget(self, action: Selector("playKeySound"), forControlEvents: .TouchDown)
                    }
                }
            }
        }
    }
    
    /////////////////
    // POPUP DELAY //
    /////////////////
    
    var keyWithDelayedPopup: KeyboardKey?
    var popupDelayTimer: NSTimer?
    
    func showPopup(sender: KeyboardKey) {
        if sender == self.keyWithDelayedPopup {
            self.popupDelayTimer?.invalidate()
        }
		
		self.view.sendSubviewToBack(self.bannerView!)
		
		var proxy = textDocumentProxy as! UITextDocumentProxy
		if proxy.keyboardType == UIKeyboardType.NumberPad || proxy.keyboardType == UIKeyboardType.DecimalPad
		{
			
		}
		else
		{
			sender.showPopup()
		}
    }
	
    func hidePopupDelay(sender: KeyboardKey) {
        self.popupDelayTimer?.invalidate()
        
        if sender != self.keyWithDelayedPopup {
            self.keyWithDelayedPopup?.hidePopup()
            self.keyWithDelayedPopup = sender
        }
        
        if sender.popup != nil {
            self.popupDelayTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: Selector("hidePopupCallback"), userInfo: nil, repeats: false)
        }
    }
    
    func hidePopupCallback() {
        self.keyWithDelayedPopup?.hidePopup()
        self.keyWithDelayedPopup = nil
        self.popupDelayTimer = nil
    }
    
    /////////////////////
    // POPUP DELAY END //
    /////////////////////
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    // TODO: this is currently not working as intended; only called when selection changed -- iOS bug
	override func textDidChange(textInput: UITextInput?) {
		self.contextChanged()
		
		var proxy = textDocumentProxy as! UITextDocumentProxy
		
		keyboard_type = proxy.keyboardType!
		
		getKeyboardType()
		
		if let text = proxy.documentContextBeforeInput
		{
			if isAllowFullAccess == true
			{
				
			}
			
		}
		else
		{
			sug_word = " "
			
		}
		
		dispatch_async(dispatch_get_main_queue(), {
			if proxy.keyboardType! != self.preKeyboardType
			{
				self.forwardingView.resetTrackedViews()
				self.shiftStartingState = nil
				self.shiftWasMultitapped = false
				//
				// optimization: ensures smooth animation
				if let keyPool = self.layout?.keyPool {
					for view1 in keyPool {
						view1.shouldRasterize = true
					}
				}
				
				for (index, view1) in enumerate(self.forwardingView.subviews)
				{
					var v = view1 as! UIView
					v.removeFromSuperview()
					
				}
				
				self.keyboardHeight = self.heightForOrientation(self.interfaceOrientation, withTopBanner: true)
				
				self.constraintsAdded = false
				self.setupLayout()
				
			}
			
		})
	}
	
    func contextChanged() {
        self.setCapsIfNeeded()
        self.autoPeriodState = .NoSpace
    }
	
    func setHeight(height: CGFloat) {
        if self.heightConstraint == nil {
            self.heightConstraint = NSLayoutConstraint(
                item:self.view,
                attribute:NSLayoutAttribute.Height,
                relatedBy:NSLayoutRelation.Equal,
                toItem:nil,
                attribute:NSLayoutAttribute.NotAnAttribute,
                multiplier:0,
                constant:height)
            self.heightConstraint!.priority = 1000
			
            self.view.addConstraint(self.heightConstraint!) // TODO: what if view already has constraint added?
        }
        else {
            self.heightConstraint?.constant = height
        }
    }
    
    func updateAppearances(appearanceIsDark: Bool) {
        self.layout?.solidColorMode = self.solidColorMode()
        self.layout?.darkMode = appearanceIsDark
        self.layout?.updateKeyAppearance()
        
        self.bannerView?.darkMode = appearanceIsDark
        self.settingsView?.darkMode = appearanceIsDark
    }
    
    func highlightKey(sender: KeyboardKey) {
        sender.highlighted = true
    }
    
    func unHighlightKey(sender: KeyboardKey) {
        sender.highlighted = false
    }
    
    func keyPressedHelper(sender: KeyboardKey) {
        if let model = self.layout?.keyForView(sender) {
            self.keyPressed(model)

            // auto exit from special char subkeyboard
            if model.type == Key.KeyType.Space || model.type == Key.KeyType.Return {
                self.currentMode = 0
            }
            else if model.lowercaseOutput == "'" {
                self.currentMode = 0
            }
            else if model.type == Key.KeyType.Character {
                self.currentMode = 0
            }
            
            // auto period on double space
            // TODO: timeout
            
            var lastCharCountInBeforeContext: Int = 0
            var readyForDoubleSpacePeriod: Bool = true
            
            self.handleAutoPeriod(model)
            // TODO: reset context
        }
        
        self.setCapsIfNeeded()
    }
	
    func handleAutoPeriod(key: Key) {
        if !NSUserDefaults.standardUserDefaults().boolForKey(kPeriodShortcut) {
            return
        }
		
        if self.autoPeriodState == .FirstSpace {
            if key.type != Key.KeyType.Space {
                self.autoPeriodState = .NoSpace
                return
            }
			
            let charactersAreInCorrectState = { () -> Bool in
                let previousContext = (self.textDocumentProxy as? UITextDocumentProxy)?.documentContextBeforeInput
				
                if previousContext == nil || count(previousContext!) < 3 {
                    return false
                }
				
                var index = previousContext!.endIndex
				
                index = index.predecessor()
                if previousContext![index] != " " {
                    return false
                }
                
                index = index.predecessor()
                if previousContext![index] != " " {
                    return false
                }
                
                index = index.predecessor()
                let char = previousContext![index]
                if self.characterIsWhitespace(char) || self.characterIsPunctuation(char) || char == "," {
                    return false
                }
                
                return true
            }()
            
            if charactersAreInCorrectState {
                (self.textDocumentProxy as? UITextDocumentProxy)?.deleteBackward()
                (self.textDocumentProxy as? UITextDocumentProxy)?.deleteBackward()
                (self.textDocumentProxy as? UITextDocumentProxy)?.insertText(".")
                (self.textDocumentProxy as? UITextDocumentProxy)?.insertText(" ")
            }
            
            self.autoPeriodState = .NoSpace
        }
        else {
            if key.type == Key.KeyType.Space {
                self.autoPeriodState = .FirstSpace
            }
        }
    }
    
    func cancelBackspaceTimers() {
        self.backspaceDelayTimer?.invalidate()
        self.backspaceRepeatTimer?.invalidate()
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = nil
    }
    
    func backspaceDown(sender: KeyboardKey) {
        self.cancelBackspaceTimers()
        
        if let textDocumentProxy = self.textDocumentProxy as? UIKeyInput {
            textDocumentProxy.deleteBackward()
        }
        self.setCapsIfNeeded()
        
        // trigger for subsequent deletes
        self.backspaceDelayTimer = NSTimer.scheduledTimerWithTimeInterval(backspaceDelay - backspaceRepeat, target: self, selector: Selector("backspaceDelayCallback"), userInfo: nil, repeats: false)
    }
    
    func backspaceUp(sender: KeyboardKey) {
        self.cancelBackspaceTimers()
    }
    
    func backspaceDelayCallback() {
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = NSTimer.scheduledTimerWithTimeInterval(backspaceRepeat, target: self, selector: Selector("backspaceRepeatCallback"), userInfo: nil, repeats: true)
    }
    
    func backspaceRepeatCallback() {
        self.playKeySound()
        
        if let textDocumentProxy = self.textDocumentProxy as? UIKeyInput {
            textDocumentProxy.deleteBackward()
        }
        self.setCapsIfNeeded()
    }
    
    func shiftDown(sender: KeyboardKey) {
        self.shiftStartingState = self.shiftState
        
        if let shiftStartingState = self.shiftStartingState {
            if shiftStartingState.uppercase() {
                // handled by shiftUp
                return
            }
            else {
                switch self.shiftState {
                case .Disabled:
                    self.shiftState = .Enabled
                case .Enabled:
                    self.shiftState = .Disabled
                case .Locked:
                    self.shiftState = .Disabled
                }
                
                (sender.shape as? ShiftShape)?.withLock = false
            }
        }
    }
    
    func shiftUp(sender: KeyboardKey) {
        if self.shiftWasMultitapped {
            // do nothing
        }
        else {
            if let shiftStartingState = self.shiftStartingState {
                if !shiftStartingState.uppercase() {
                    // handled by shiftDown
                }
                else {
                    switch self.shiftState {
                    case .Disabled:
                        self.shiftState = .Enabled
                    case .Enabled:
                        self.shiftState = .Disabled
                    case .Locked:
                        self.shiftState = .Disabled
                    }
                    
                    (sender.shape as? ShiftShape)?.withLock = false
                }
            }
        }

        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
    }
    
    func shiftDoubleTapped(sender: KeyboardKey) {
        self.shiftWasMultitapped = true
        
        switch self.shiftState {
        case .Disabled:
            self.shiftState = .Locked
        case .Enabled:
            self.shiftState = .Locked
        case .Locked:
            self.shiftState = .Disabled
        }
    }
    
    func updateKeyCaps(uppercase: Bool) {
        let characterUppercase = (NSUserDefaults.standardUserDefaults().boolForKey(kSmallLowercase) ? uppercase : true)
        self.layout?.updateKeyCaps(false, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
    }
    
    func modeChangeTapped(sender: KeyboardKey) {
        if let toMode = self.layout?.viewToModel[sender]?.toMode {
            self.currentMode = toMode
        }
    }
    
    func setMode(mode: Int) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        let uppercase = self.shiftState.uppercase()
        let characterUppercase = (NSUserDefaults.standardUserDefaults().boolForKey(kSmallLowercase) ? uppercase : true)
        self.layout?.layoutKeys(mode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
        
        self.setupKeys()
    }
    
    func advanceTapped(sender: KeyboardKey) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        self.advanceToNextInputMode()
    }
    
    @IBAction func toggleSettings() {
        // lazy load settings
        if self.settingsView == nil {
            if var aSettings = self.createSettings() {
                aSettings.darkMode = self.darkMode()
                
                aSettings.hidden = true
                self.view.addSubview(aSettings)
                self.settingsView = aSettings
                
                aSettings.setTranslatesAutoresizingMaskIntoConstraints(false)
                
                let widthConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
                let heightConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
                let centerXConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
                let centerYConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
                
                self.view.addConstraint(widthConstraint)
                self.view.addConstraint(heightConstraint)
                self.view.addConstraint(centerXConstraint)
                self.view.addConstraint(centerYConstraint)
            }
        }
        
        if let settings = self.settingsView {
            let hidden = settings.hidden
            settings.hidden = !hidden
            self.forwardingView.hidden = hidden
            self.forwardingView.userInteractionEnabled = !hidden
            self.bannerView?.hidden = hidden
        }
    }
    
    func setCapsIfNeeded() -> Bool {
        if self.shouldAutoCapitalize() {
            switch self.shiftState {
            case .Disabled:
                self.shiftState = .Enabled
            case .Enabled:
                self.shiftState = .Enabled
            case .Locked:
                self.shiftState = .Locked
            }
            
            return true
        }
        else {
            switch self.shiftState {
            case .Disabled:
                self.shiftState = .Disabled
            case .Enabled:
                self.shiftState = .Disabled
            case .Locked:
                self.shiftState = .Locked
            }
            
            return false
        }
    }
    
    func characterIsPunctuation(character: Character) -> Bool {
        return (character == ".") || (character == "!") || (character == "?")
    }
    
    func characterIsNewline(character: Character) -> Bool {
        return (character == "\n") || (character == "\r")
    }
    
    func characterIsWhitespace(character: Character) -> Bool {
        // there are others, but who cares
        return (character == " ") || (character == "\n") || (character == "\r") || (character == "\t")
    }
    
    func stringIsWhitespace(string: String?) -> Bool {
        if string != nil {
            for char in string! {
                if !characterIsWhitespace(char) {
                    return false
                }
            }
        }
        return true
    }
    
    func shouldAutoCapitalize() -> Bool {
        if !NSUserDefaults.standardUserDefaults().boolForKey(kAutoCapitalization) {
            return false
        }
        
        if let traits = self.textDocumentProxy as? UITextInputTraits {
            if let autocapitalization = traits.autocapitalizationType {
                var documentProxy = self.textDocumentProxy as? UITextDocumentProxy
                var beforeContext = documentProxy?.documentContextBeforeInput
                
                switch autocapitalization {
                case .None:
                    return false
                case .Words:
                    if let beforeContext = documentProxy?.documentContextBeforeInput {
                        let previousCharacter = beforeContext[beforeContext.endIndex.predecessor()]
                        return self.characterIsWhitespace(previousCharacter)
                    }
                    else {
                        return true
                    }
                
                case .Sentences:
                    if let beforeContext = documentProxy?.documentContextBeforeInput {
                        let offset = min(3, count(beforeContext))
                        var index = beforeContext.endIndex
                        
                        for (var i = 0; i < offset; i += 1) {
                            index = index.predecessor()
                            let char = beforeContext[index]
                            
                            if characterIsPunctuation(char) {
                                if i == 0 {
                                    return false //not enough spaces after punctuation
                                }
                                else {
                                    return true //punctuation with at least one space after it
                                }
                            }
                            else {
                                if !characterIsWhitespace(char) {
                                    return false //hit a foreign character before getting to 3 spaces
                                }
                                else if characterIsNewline(char) {
                                    return true //hit start of line
                                }
                            }
                        }
                        
                        return true //either got 3 spaces or hit start of line
                    }
                    else {
                        return true
                    }
                case .AllCharacters:
                    return true
                }
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    // this only works if full access is enabled
    func playKeySound() {
        if !NSUserDefaults.standardUserDefaults().boolForKey(kKeyboardClicks) {
            return
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            AudioServicesPlaySystemSound(1104)
        })
    }
    
    //////////////////////////////////////
    // MOST COMMONLY EXTENDABLE METHODS //
    //////////////////////////////////////
    
    class var layoutClass: KeyboardLayout.Type { get { return KeyboardLayout.self }}
    class var layoutConstants: LayoutConstants.Type { get { return LayoutConstants.self }}
    class var globalColors: GlobalColors.Type { get { return GlobalColors.self }}
    
    func keyPressed(key: Key) {
        if let proxy = (self.textDocumentProxy as? UIKeyInput) {
            proxy.insertText(key.outputForCase(self.shiftState.uppercase()))
        }
    }
    
    // a banner that sits in the empty space on top of the keyboard
    func createBanner() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        //return ExtraView(globalColors: self.dynamicType.globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        return nil
    }
    
    // a settings view that replaces the keyboard when the settings button is pressed
    func createSettings() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        var settingsView = DefaultSettings(globalColors: self.dynamicType.globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        settingsView.backButton?.addTarget(self, action: Selector("toggleSettings"), forControlEvents: UIControlEvents.TouchUpInside)
        return settingsView
    }
	
	// MARK: Added methods for extra features
	func initializePopUp()
	{
		button.hidden = true
		button.forwordingView = forwardingView
		button.frame = CGRectMake(0, 0, 20, 20)
		button.tag = 111
		self.view.insertSubview(self.button, aboveSubview: self.forwardingView)
		button.setupInputOptionsConfigurationWithView(forwardingView)
		button.hidden = true
		viewLongPopUp.hidden = true
	}

	func didTTouchExitDownSuggestionButton(sender: AnyObject?)
	{
		let button = sender as! UIButton
		
		button.backgroundColor = UIColor(red:0.68, green:0.71, blue:0.74, alpha:1)
		
		button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
		
	}
	
	func didTTouchDownSuggestionButton(sender: AnyObject?)
	{
		let button = sender as! UIButton
		
		if let btn_title = button.titleForState(UIControlState.Normal)
		{
			var title = btn_title.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
			
			if(count(title) != 0)
			{
				button.backgroundColor = UIColor(red:0.92, green:0.93, blue:0.94, alpha:1)
				button.setTitleColor(UIColor.blackColor(), forState: .Normal)
			}
		}
	}
	
	
	func didTapSuggestionButton(sender: AnyObject?)
	{
		
		self.currentMode = 0
		
		let button = sender as! UIButton
		
		self.autoPeriodState = .FirstSpace
		
		var title1 = self.bannerView!.btn1.titleForState(.Normal)
		var title2 = self.bannerView!.btn2.titleForState(.Normal)
		var title3 = self.bannerView!.btn3.titleForState(.Normal)
		
		title1 = title1!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
		title2 = title2!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
		title3 = title3!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
		
		if let proxy = (self.textDocumentProxy as? UIKeyInput)
		{
			onSuggestionTap(sender)
		}
		
		self.bannerView!.btn1.backgroundColor = UIColor(red:0.68, green:0.71, blue:0.74, alpha:1)
		self.bannerView!.btn2.backgroundColor = UIColor(red:0.68, green:0.71, blue:0.74, alpha:1)
		self.bannerView!.btn3.backgroundColor = UIColor(red:0.68, green:0.71, blue:0.74, alpha:1)
		
		self.bannerView!.btn1.setTitleColor(UIColor.whiteColor(), forState: .Normal)
		self.bannerView!.btn2.setTitleColor(UIColor.whiteColor(), forState: .Normal)
		self.bannerView!.btn3.setTitleColor(UIColor.whiteColor(), forState: .Normal)
		
		
		self.setCapsIfNeeded()
		
	}
	
	func onSuggestionTap(sender: AnyObject?)
	{
		
		let button = sender as! UIButton
		
		if let proxy = (self.textDocumentProxy as? UIKeyInput)
		{
			if let titleBtn = button.titleForState(.Normal)
			{
				var title = titleBtn.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
				
				if count(title) == 0
				{
					return
				}
				var tokens = self.sug_word.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) as [String]
				
				if let lastWord = tokens.last
				{
					if count(lastWord) != 0
					{
						if count(title) == 0
						{
							
						}
						else
						{
							for character in lastWord
							{
								proxy.deleteBackward()
							}
							
						}
						
					}
				}
				
				if self.shiftState == .Enabled
				{
					proxy.insertText(title.capitalizedString+" ")
				}
				else if self.shiftState == .Locked
				{
					proxy.insertText(title.uppercaseString+" ")
				}
				else
				{
					if let lastWord = tokens.last
					{
						if count(lastWord) > 0
						{
							if self.isCapitalalize(tokens.last!)
							{
								proxy.insertText(title.capitalizedString+" ")
							}
							else
							{
								proxy.insertText(title+" ")
							}
						}
						else
						{
							proxy.insertText(title+" ")
						}
						
						
					}
					else
					{
						proxy.insertText(title+" ")
					}
					
				}
				
				if button == self.bannerView!.btn2
				{
					let titleBtn1 = self.bannerView!.btn1.titleForState(.Normal)
					let titleBtn3 = self.bannerView!.btn3.titleForState(.Normal)
					
					if count(titleBtn1!) == 0 && count(titleBtn3!) == 0
					{
					}
				}
				
			}
			
		}
	}
	

	
	func keyCharDoubleTapped(sender: KeyboardKey)
	{
		if sender.tag == 888
		{
			sender.hidePopup()
			
			var arrOptions = self.getInputOption(sender.text.uppercaseString) as [String]
			
			if arrOptions.count > 0
			{
				if count(arrOptions[0]) > 0
				{
					var offsetY : CGFloat = 9
					
					if KeyboardViewController.getDeviceType() == TTDeviceType.TTDeviceTypeIPhone4
					{
						offsetY = 9
						if self.interfaceOrientation == UIInterfaceOrientation.LandscapeLeft || self.interfaceOrientation == UIInterfaceOrientation.LandscapeRight
						{
							offsetY = 3
						}
					}
					else if KeyboardViewController.getDeviceType() == TTDeviceType.TTDeviceTypeIPhone5
					{
						offsetY = 9
						if self.interfaceOrientation == UIInterfaceOrientation.LandscapeLeft || self.interfaceOrientation == UIInterfaceOrientation.LandscapeRight
						{
							offsetY = 3
						}
						
					}
					else if KeyboardViewController.getDeviceType() == TTDeviceType.TTDeviceTypeIPhone6
					{
						offsetY = 13
						if self.interfaceOrientation == UIInterfaceOrientation.LandscapeLeft || self.interfaceOrientation == UIInterfaceOrientation.LandscapeRight
						{
							offsetY = 3
						}
						
					}
					else if KeyboardViewController.getDeviceType() == TTDeviceType.TTDeviceTypeIPhone6p
					{
						offsetY = 16
						if self.interfaceOrientation == UIInterfaceOrientation.LandscapeLeft || self.interfaceOrientation == UIInterfaceOrientation.LandscapeRight
						{
							offsetY = 3
						}
					}
					
					self.button.removeFromSuperview()
					
					self.button.frame = CGRectMake(sender.frame.origin.x, sender.frame.origin.y + sender.frame.size.height - offsetY, sender.frame.size.width, sender.frame.size.height)
					
					//					self.button.frame = CGRectMake(sender.frame.origin.x, sender.frame.origin.y , sender.frame.size.width, sender.frame.size.height)
					
					self.view.insertSubview(self.button, aboveSubview: self.forwardingView)
					
					self.viewLongPopUp = self.button.showLongPopUpOptions()
					self.button.input = sender.text
					self.button.hidden = true
					self.button.inputOptions = arrOptions
					self.viewLongPopUp.hidden = false
					
					for anyView in self.view.subviews
					{
						if anyView is CYRKeyboardButtonView
						{
							anyView.removeFromSuperview()
						}
					}
					
					self.viewLongPopUp.userInteractionEnabled = false;
					
					button.setupInputOptionsConfigurationWithView(forwardingView)
					self.view.insertSubview(self.viewLongPopUp, aboveSubview: self.forwardingView)
					self.forwardingView.isLongPressEnable = true
					self.view.bringSubviewToFront(self.viewLongPopUp)
					//self.forwardingView.resetTrackedViews()
					//sender.hidePopup()
					//self.view.addSubview(self.viewLongPopUp)
					
					sender.tag = 0
				}
			}
		}
	}
	
	class func getDeviceType()->TTDeviceType
	{
		var height = UIScreen.mainScreen().bounds.size.height
		
		if UIScreen.mainScreen().bounds.size.height < UIScreen.mainScreen().bounds.size.width
		{
			height = UIScreen.mainScreen().bounds.size.width
		}
		
		switch (height) {
		case 480:
			deviceType = TTDeviceType.TTDeviceTypeIPhone4 ;
			break;
			
		case 568:
			deviceType = TTDeviceType.TTDeviceTypeIPhone5 ;
			break;
		case 667:
			deviceType = TTDeviceType.TTDeviceTypeIPhone6 ;
			break;
		case 736:
			deviceType = TTDeviceType.TTDeviceTypeIPhone6p ;
			break;
			
		default:
			break;
		}
		
		return deviceType
		
	}
	
	func getInputOption(strChar : String) -> [String]
	{
		
		if strChar == "A"
		{
			if self.shiftState == .Enabled || self.shiftState == .Locked
			{
				return ["A","Á","À","Ä","Â","Ã","Å","Æ","Ā"] //"ª", "Ą"
			}
			else
			{
				return ["a","á", "à", "ä", "â", "ã", "å", "æ","ā"] //"ą"
			}
			
		}
		else if strChar == "."
		{
			
			return [".com",".edu",".net",".org"] //"ą
			
		}
		else if strChar == "E"
		{
			if self.shiftState == .Enabled || self.shiftState == .Locked
			{
				return ["E","É","È","Ë","Ê","Ę","Ė","Ē"]
			}
			else
			{
				return ["e", "é", "è", "ë", "ê", "ę", "ė", "ē"]
			}
			
		}
		else if strChar == "U"
		{
			if self.shiftState == .Enabled || self.shiftState == .Locked
			{
				return ["U","Ú","Ü","Ù","Û"]
			}
			else
			{
				return ["u", "ú", "ü", "ù", "û", "ū"]
			}
			
		}
		else if strChar == "I"
		{
			if self.shiftState == .Enabled || self.shiftState == .Locked
			{
				return ["I","Í","Ï","Ì","Î","Į","Ī"]
			}
			else
			{
				return ["i", "í", "ï", "ì", "î", "į", "ī"]
			}
			
		}
		else if strChar == "O"
		{
			if self.shiftState == .Enabled || self.shiftState == .Locked
			{
				return ["O","Ó","Ò","Ö","Ô","Õ","Ø","Œ","Ō"] //"º"
			}
			else
			{
				return ["o", "ó", "ò", "ö", "ô", "õ", "ø", "œ", "ō"]
			}
			
		}
		else if strChar == "S"
		{
			if self.shiftState == .Enabled || self.shiftState == .Locked
			{
				return ["S","Š"]
			}
			else
			{
				return ["s","š"]
			}
			
		}
		else if strChar == "D"
		{
			if self.shiftState == .Enabled || self.shiftState == .Locked
			{
				return ["D","Đ"]
			}
			else
			{
				return ["d", "đ"]
			}
			
		}
		else if strChar == "C"
		{
			if self.shiftState == .Enabled || self.shiftState == .Locked
			{
				return ["C","Ç","Ć","Č"]
			}
			else
			{
				return ["c", "ç", "ć", "č"]
			}
			
		}
		else if strChar == "N"
		{
			if self.shiftState == .Enabled || self.shiftState == .Locked
			{
				return ["N","Ñ","Ń"]
			}
			else
			{
				return ["n","ñ", "ń"]
			}
			
		}
		return [""]
	}

	func getKeyboardType()
	{
		var proxy = textDocumentProxy as! UITextDocumentProxy
		
		if proxy.keyboardType == UIKeyboardType.EmailAddress
		{
			//add code here to display number/decimal input keyboard
			key_type = true
			
		}
		else if(proxy.keyboardType == UIKeyboardType.WebSearch)
		{
			key_type = true
		}
		else if(proxy.keyboardType == UIKeyboardType.ASCIICapable)
		{
			key_type = true
		}
		else if(proxy.keyboardType == UIKeyboardType.NumbersAndPunctuation)
		{
			key_type = true
		}
		else if(proxy.keyboardType == UIKeyboardType.URL)
		{
			key_type = true
		}
		else if(proxy.keyboardType == UIKeyboardType.NumberPad)
		{
			key_type = true
		}
		else if(proxy.keyboardType == UIKeyboardType.DecimalPad)
		{
			key_type = true
		}
		else if(proxy.keyboardType == UIKeyboardType.NamePhonePad)
		{
			key_type = true
		}
		else if(proxy.keyboardType == UIKeyboardType.Twitter)
		{
			key_type = true
		}
		else if(proxy.keyboardType == UIKeyboardType.Default)
		{
			
			if(proxy.autocorrectionType == UITextAutocorrectionType.No)
			{
				key_type = true
			}
			else
			{
				key_type = false
			}
			
		}
		else
		{
			key_type = false
		}
		
	}

	
}
