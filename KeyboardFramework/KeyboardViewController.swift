//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit
import AudioToolbox

let metrics: [String:Double] = [
    "topBanner": 30
]
func metric(name: String) -> CGFloat { return CGFloat(metrics[name]!) }

// TODO: move this somewhere else and localize
let kAutoCapitalization = "kAutoCapitalization"
let kPeriodShortcut = "kPeriodShortcut"
let kKeyboardClicks = "kKeyboardClicks"
let kSmallLowercase = "kSmallLowercase"

public class KeyboardViewController: UIInputViewController {
    
    public let backspaceDelay: NSTimeInterval = 0.5
    public let backspaceRepeat: NSTimeInterval = 0.07
    
    public var keyboard: Keyboard!
    public var forwardingView: ForwardingView!
    public var layout: KeyboardLayout?
    public var heightConstraint: NSLayoutConstraint?
    
    public var bannerView: ExtraView?
    public var settingsView: ExtraView?
    
    public var currentMode: Int {
        didSet {
            if oldValue != currentMode {
                setMode(currentMode)
            }
        }
    }
    
    public var backspaceActive: Bool {
        get {
            return (backspaceDelayTimer != nil) || (backspaceRepeatTimer != nil)
        }
    }
    public var backspaceDelayTimer: NSTimer?
    public var backspaceRepeatTimer: NSTimer?
    
    public enum AutoPeriodState {
        case NoSpace
        case FirstSpace
    }
    
    public var autoPeriodState: AutoPeriodState = .NoSpace
    public var lastCharCountInBeforeContext: Int = 0
    
    public var shiftState: ShiftState {
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
    public var shiftWasMultitapped: Bool = false
    public var shiftStartingState: ShiftState?
    
    public var keyboardHeight: CGFloat {
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
    
    // TODO: why does the app crash if this isn't here?
    convenience public init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        NSUserDefaults.standardUserDefaults().registerDefaults([
            kAutoCapitalization: true,
            kPeriodShortcut: true,
            kKeyboardClicks: false,
            kSmallLowercase: false
        ])
        
        self.keyboard = defaultKeyboard()
        
        self.shiftState = .Disabled
        self.currentMode = 0
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.forwardingView = ForwardingView(frame: CGRectZero)
        self.view.addSubview(self.forwardingView)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("defaultsChanged:"), name: NSUserDefaultsDidChangeNotification, object: nil)
    }
    
    required public init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    deinit {
        backspaceDelayTimer?.invalidate()
        backspaceRepeatTimer?.invalidate()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public func defaultsChanged(notification: NSNotification) {
        let defaults = notification.object as? NSUserDefaults
        self.updateKeyCaps(self.shiftState.uppercase())
    }
    
    // without this here kludge, the height constraint for the keyboard does not work for some reason
    public var kludge: UIView?
    public func setupKludge() {
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
    
    public var constraintsAdded: Bool = false
    public func setupLayout() {
        if !constraintsAdded {
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
    public func darkMode() -> Bool {
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
    
    public func solidColorMode() -> Bool {
        return UIAccessibilityIsReduceTransparencyEnabled()
    }
    
    public var lastLayoutBounds: CGRect?
    override public func viewDidLayoutSubviews() {
        if view.bounds == CGRectZero {
            return
        }
        
        self.setupLayout()
        
         let orientationSavvyBounds = CGRectMake(0, 0, self.view.bounds.width, self.heightForOrientation(self.interfaceOrientation, withTopBanner: false))
        
        if (lastLayoutBounds != nil && lastLayoutBounds == orientationSavvyBounds) {
            // do nothing
        }
        else {
             let uppercase = self.shiftState.uppercase()
             let characterUppercase = (NSUserDefaults.standardUserDefaults().boolForKey(kSmallLowercase) ? uppercase : true)
            
            self.forwardingView.frame = orientationSavvyBounds
            self.layout?.layoutKeys(self.currentMode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
            self.lastLayoutBounds = orientationSavvyBounds
            self.setupKeys()
        }
        
        self.bannerView?.frame = CGRectMake(0, 0, self.view.bounds.width, metric("topBanner"))
        
        let newOrigin = CGPointMake(0, self.view.bounds.height - self.forwardingView.bounds.height)
        self.forwardingView.frame.origin = newOrigin
    }
    
    override public func loadView() {
        super.loadView()
        
        if var aBanner = self.createBanner() {
            aBanner.hidden = true
            self.view.insertSubview(aBanner, belowSubview: self.forwardingView)
            self.bannerView = aBanner
        }
    }
    
    override public func viewWillAppear(animated: Bool) {
        self.bannerView?.hidden = false
        self.keyboardHeight = self.heightForOrientation(self.interfaceOrientation, withTopBanner: true)
    }
    
    override public func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
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
    
    override public func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        // optimization: ensures quick mode and shift transitions
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = false
            }
        }
    }
    
    public func heightForOrientation(orientation: UIInterfaceOrientation, withTopBanner: Bool) -> CGFloat {
         let isPad = UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
        
        //TODO: hardcoded stuff
        let actualScreenWidth = (UIScreen.mainScreen().nativeBounds.size.width / UIScreen.mainScreen().nativeScale)
        let canonicalPortraitHeight = (isPad ? CGFloat(264) : CGFloat(orientation.isPortrait && actualScreenWidth >= 400 ? 226 : 216))
        let canonicalLandscapeHeight = (isPad ? CGFloat(352) : CGFloat(162))
        let topBannerHeight = (withTopBanner ? metric("topBanner") : 0)
        
        return CGFloat(orientation.isPortrait ? canonicalPortraitHeight + topBannerHeight : canonicalLandscapeHeight + topBannerHeight)
    }
    
    /*
    BUG NOTE

    None of the UIContentContainer methods are called for this controller.
    */
    
    //override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    //    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    //}
    
    public func setupKeys() {
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
    
    public var keyWithDelayedPopup: KeyboardKey?
    public var popupDelayTimer: NSTimer?
    
    public func showPopup(sender: KeyboardKey) {
        if sender == self.keyWithDelayedPopup {
            self.popupDelayTimer?.invalidate()
        }
        sender.showPopup()
    }
    
    public func hidePopupDelay(sender: KeyboardKey) {
        self.popupDelayTimer?.invalidate()
        
        if sender != self.keyWithDelayedPopup {
            self.keyWithDelayedPopup?.hidePopup()
            self.keyWithDelayedPopup = sender
        }
        
        if sender.popup != nil {
            self.popupDelayTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: Selector("hidePopupCallback"), userInfo: nil, repeats: false)
        }
    }
    
    public func hidePopupCallback() {
        self.keyWithDelayedPopup?.hidePopup()
        self.keyWithDelayedPopup = nil
        self.popupDelayTimer = nil
    }
    
    /////////////////////
    // POPUP DELAY END //
    /////////////////////
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    // TODO: this is currently not working as intended; only called when selection changed -- iOS bug
    override public func textDidChange(textInput: UITextInput) {
        self.contextChanged()
    }
    
    public func contextChanged() {
        self.setCapsIfNeeded()
        self.autoPeriodState = .NoSpace
    }
    
    public func setHeight(height: CGFloat) {
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
    
    public func updateAppearances(appearanceIsDark: Bool) {
        self.layout?.solidColorMode = self.solidColorMode()
        self.layout?.darkMode = appearanceIsDark
        self.layout?.updateKeyAppearance()
        
        self.bannerView?.darkMode = appearanceIsDark
        self.settingsView?.darkMode = appearanceIsDark
    }
    
    public func highlightKey(sender: KeyboardKey) {
        sender.highlighted = true
    }
    
    public func unHighlightKey(sender: KeyboardKey) {
        sender.highlighted = false
    }
    
    public func keyPressedHelper(sender: KeyboardKey) {
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
    
    public func handleAutoPeriod(key: Key) {
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
    
    public func cancelBackspaceTimers() {
        self.backspaceDelayTimer?.invalidate()
        self.backspaceRepeatTimer?.invalidate()
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = nil
    }
    
    public func backspaceDown(sender: KeyboardKey) {
        self.cancelBackspaceTimers()
        
        if let textDocumentProxy = self.textDocumentProxy as? UIKeyInput {
            textDocumentProxy.deleteBackward()
        }
        self.setCapsIfNeeded()
        
        // trigger for subsequent deletes
        self.backspaceDelayTimer = NSTimer.scheduledTimerWithTimeInterval(backspaceDelay - backspaceRepeat, target: self, selector: Selector("backspaceDelayCallback"), userInfo: nil, repeats: false)
    }
    
    public func backspaceUp(sender: KeyboardKey) {
        self.cancelBackspaceTimers()
    }
    
    public func backspaceDelayCallback() {
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = NSTimer.scheduledTimerWithTimeInterval(backspaceRepeat, target: self, selector: Selector("backspaceRepeatCallback"), userInfo: nil, repeats: true)
    }
    
    public func backspaceRepeatCallback() {
        self.playKeySound()
        
        if let textDocumentProxy = self.textDocumentProxy as? UIKeyInput {
            textDocumentProxy.deleteBackward()
        }
        self.setCapsIfNeeded()
    }
    
    public func shiftDown(sender: KeyboardKey) {
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
    
    public func shiftUp(sender: KeyboardKey) {
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
    
    public func shiftDoubleTapped(sender: KeyboardKey) {
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
    
    public func updateKeyCaps(uppercase: Bool) {
        let characterUppercase = (NSUserDefaults.standardUserDefaults().boolForKey(kSmallLowercase) ? uppercase : true)
        self.layout?.updateKeyCaps(false, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
    }
    
    public func modeChangeTapped(sender: KeyboardKey) {
        if let toMode = self.layout?.viewToModel[sender]?.toMode {
            self.currentMode = toMode
        }
    }
    
    public func setMode(mode: Int) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        let uppercase = self.shiftState.uppercase()
        let characterUppercase = (NSUserDefaults.standardUserDefaults().boolForKey(kSmallLowercase) ? uppercase : true)
        self.layout?.layoutKeys(mode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
        
        self.setupKeys()
    }
    
    public func advanceTapped(sender: KeyboardKey) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        self.advanceToNextInputMode()
    }
    
    @IBAction public func toggleSettings() {
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
    
    public func setCapsIfNeeded() -> Bool {
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
    
    public func characterIsPunctuation(character: Character) -> Bool {
        return (character == ".") || (character == "!") || (character == "?")
    }
    
    public func characterIsNewline(character: Character) -> Bool {
        return (character == "\n") || (character == "\r")
    }
    
    public func characterIsWhitespace(character: Character) -> Bool {
        // there are others, but who cares
        return (character == " ") || (character == "\n") || (character == "\r") || (character == "\t")
    }
    
    public func stringIsWhitespace(string: String?) -> Bool {
        if string != nil {
            for char in string! {
                if !characterIsWhitespace(char) {
                    return false
                }
            }
        }
        return true
    }
    
    public func shouldAutoCapitalize() -> Bool {
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
    public func playKeySound() {
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
    
    public class var layoutClass: KeyboardLayout.Type { get { return KeyboardLayout.self }}
    public class var layoutConstants: LayoutConstants.Type { get { return LayoutConstants.self }}
    public class var globalColors: GlobalColors.Type { get { return GlobalColors.self }}
    
    public func keyPressed(key: Key) {
        if let proxy = (self.textDocumentProxy as? UIKeyInput) {
            proxy.insertText(key.outputForCase(self.shiftState.uppercase()))
        }
    }
    
    // a banner that sits in the empty space on top of the keyboard
    public func createBanner() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        //return ExtraView(globalColors: self.dynamicType.globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        return nil
    }
    
    // a settings view that replaces the keyboard when the settings button is pressed
    public func createSettings() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        var settingsView = DefaultSettings(globalColors: self.dynamicType.globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        settingsView.backButton?.addTarget(self, action: Selector("toggleSettings"), forControlEvents: UIControlEvents.TouchUpInside)
        return settingsView
    }
}
