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

class KeyboardViewController: UIInputViewController {
    
    let backspaceDelay: NSTimeInterval = 0.5
    let backspaceRepeat: NSTimeInterval = 0.05
    
    var keyboard: Keyboard!
    var forwardingView: ForwardingView!
    var layout: KeyboardLayout?
    var heightConstraint: NSLayoutConstraint?
    
    var bannerView: ExtraView?
    var settingsView: ExtraView?
    
    var currentMode: Int {
        didSet {
            setMode(currentMode)
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
    
    enum ShiftState {
        case Disabled
        case Enabled
        case Locked
        
        func uppercase() -> Bool {
            switch self {
            case Disabled:
                return false
            case Enabled:
                return true
            case Locked:
                return true
            }
        }
    }
    var shiftState: ShiftState {
        didSet {
            switch shiftState {
            case .Disabled:
                self.updateKeyCaps(true)
            case .Enabled:
                self.updateKeyCaps(false)
            case .Locked:
                self.updateKeyCaps(false)
            }
        }
    }
    
    var shiftWasMultitapped: Bool = false
    
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
    
    // TODO: why does the app crash if this isn't here?
    convenience override init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        NSUserDefaults.standardUserDefaults().registerDefaults([
            kAutoCapitalization: true,
            kPeriodShortcut: true,
            kKeyboardClicks: true
        ])
        
        self.keyboard = defaultKeyboard()
        
        self.shiftState = .Disabled
        self.currentMode = 0
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.forwardingView = ForwardingView(frame: CGRectZero)
        self.view.addSubview(self.forwardingView)
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    deinit {
        backspaceDelayTimer?.invalidate()
        backspaceRepeatTimer?.invalidate()
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
            self.layout = self.dynamicType.layoutClass(model: self.keyboard, superview: self.forwardingView, layoutConstants: self.dynamicType.layoutConstants, globalColors: self.dynamicType.globalColors, darkMode: self.darkMode(), solidColorMode: self.solidColorMode())
            
            self.layout?.initialize()
            self.setupKeys()
            self.setMode(0)
            
            self.setupKludge()
            
            self.updateKeyCaps(!self.shiftState.uppercase())
            self.setCapsIfNeeded()
            
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
        return true //TODO: temporary, until vibrancy performance is fixed
        //return UIAccessibilityIsReduceTransparencyEnabled()
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
        else {
            self.forwardingView.frame = orientationSavvyBounds
            self.layout?.layoutTemp()
            self.lastLayoutBounds = orientationSavvyBounds
        }
        
        self.bannerView?.frame = CGRectMake(0, 0, self.view.bounds.width, metric("topBanner"))
        
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
        
        if var aSettings = self.createSettings() {
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
    
    override func viewDidAppear(animated: Bool) {
        self.bannerView?.hidden = false
        self.keyboardHeight = self.heightForOrientation(self.interfaceOrientation, withTopBanner: true)
    }
    
    // TODO: the new size "snaps" into place on rotation, which I believe is related to performance
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        self.keyboardHeight = self.heightForOrientation(toInterfaceOrientation, withTopBanner: true)
    }
    
    func heightForOrientation(orientation: UIInterfaceOrientation, withTopBanner: Bool) -> CGFloat {
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
    
    func setupKeys() {
        if self.layout == nil {
            return
        }
        
        for page in keyboard.pages {
            for rowKeys in page.rows { // TODO: quick hack
                for key in rowKeys {
                    var keyView = self.layout!.viewForKey(key)! // TODO: check
                    
                    let showOptions: UIControlEvents = .TouchDown | .TouchDragInside | .TouchDragEnter
                    let hideOptions: UIControlEvents = .TouchUpInside | .TouchUpOutside | .TouchDragOutside
                    
                    switch key.type {
                    case Key.KeyType.KeyboardChange:
                        keyView.addTarget(self, action: "advanceToNextInputMode", forControlEvents: .TouchUpInside)
                    case Key.KeyType.Backspace:
                        let cancelEvents: UIControlEvents = UIControlEvents.TouchUpInside|UIControlEvents.TouchUpInside|UIControlEvents.TouchDragExit|UIControlEvents.TouchUpOutside|UIControlEvents.TouchCancel|UIControlEvents.TouchDragOutside
                        
                        keyView.addTarget(self, action: "backspaceDown:", forControlEvents: .TouchDown)
                        keyView.addTarget(self, action: "backspaceUp:", forControlEvents: cancelEvents)
                    case Key.KeyType.Shift:
                        keyView.addTarget(self, action: Selector("shiftDown:"), forControlEvents: .TouchUpInside)
                        keyView.addTarget(self, action: Selector("shiftDoubleTapped:"), forControlEvents: .TouchDownRepeat)
                    case Key.KeyType.ModeChange:
                        keyView.addTarget(self, action: Selector("modeChangeTapped:"), forControlEvents: .TouchUpInside)
                    case Key.KeyType.Settings:
                        keyView.addTarget(self, action: Selector("toggleSettings"), forControlEvents: .TouchUpInside)
                    default:
                        break
                    }
                    
                    if key.hasOutput {
                        keyView.addTarget(self, action: "keyPressedHelper:", forControlEvents: .TouchUpInside)
//                    keyView.addTarget(self, action: "takeScreenshotDelay", forControlEvents: .TouchDown)
                    }
                    
                    if key.isCharacter {
                        if UIDevice.currentDevice().userInterfaceIdiom != UIUserInterfaceIdiom.Pad {
                            keyView.addTarget(keyView, action: Selector("showPopup"), forControlEvents: showOptions)
                            keyView.addTarget(keyView, action: Selector("hidePopup"), forControlEvents: hideOptions)
                        }
                    }
                    
                    if key.type != Key.KeyType.Shift {
                        keyView.addTarget(self, action: Selector("highlightKey:"), forControlEvents: showOptions)
                        keyView.addTarget(self, action: Selector("unHighlightKey:"), forControlEvents: hideOptions)
                    }
                }
            }
        }
    }
    
    func takeScreenshotDelay() {
        var timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("takeScreenshot"), userInfo: nil, repeats: false)
    }
    
    func takeScreenshot() {
        if !CGRectIsEmpty(self.view.bounds) {
            UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
            
            let oldViewColor = self.view.backgroundColor
            self.view.backgroundColor = UIColor(hue: (216/360.0), saturation: 0.05, brightness: 0.86, alpha: 1)
            
            var rect = self.view.bounds
            UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
            var context = UIGraphicsGetCurrentContext()
            self.view.drawViewHierarchyInRect(self.view.bounds, afterScreenUpdates: true)
            var capturedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let name = (self.interfaceOrientation.isPortrait ? "Screenshot-Portrait" : "Screenshot-Landscape")
            var imagePath = "/Users/archagon/Documents/Programming/OSX/tasty-imitation-keyboard/\(name).png"
            UIImagePNGRepresentation(capturedImage).writeToFile(imagePath, atomically: true)
            
            self.view.backgroundColor = oldViewColor
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    // TODO: this is currently not working as intended; only called when selection changed -- iOS bug
    override func textDidChange(textInput: UITextInput) {
        self.contextChanged()
    }
    
    func contextChanged() {
        self.setCapsIfNeeded()
        self.autoPeriodState = .NoSpace
    }
    
    func setHeight(height: CGFloat) {
        if self.heightConstraint == nil {
            assert(self.view.bounds.height != 0, "attempted to set height when view hasn't appeared yet")
            
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
        self.layout?.updateKeyAppearanceTemp()
        
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
        self.playKeySound()
        
        if let model = self.layout?.keyForView(sender) {
            self.keyPressed(model)
            
            // auto exit from special char subkeyboard
            if model.type == Key.KeyType.Space || model.type == Key.KeyType.Return {
                self.setMode(0)
            }
            else if model.lowercaseOutput == "'" {
                self.setMode(0)
            }
            else if model.type == Key.KeyType.Character {
                self.setMode(0)
            }
            
            // auto period on double space
            // TODO: timeout
            
            var lastCharCountInBeforeContext: Int = 0
            var readyForDoubleSpacePeriod: Bool = true
            
            self.handleAutoPeriod(model)
            // TODO: reset context
        }
        
        if self.shiftState == ShiftState.Enabled {
            self.shiftState = ShiftState.Disabled
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
                
                if previousContext == nil || countElements(previousContext!) < 3 {
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
        
        self.playKeySound()
        
        if let textDocumentProxy = self.textDocumentProxy as? UIKeyInput {
            textDocumentProxy.deleteBackward()
        }
        
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
        if let textDocumentProxy = self.textDocumentProxy as? UIKeyInput {
            textDocumentProxy.deleteBackward()
        }
    }
    
    func shiftDown(sender: KeyboardKey) {
        self.playKeySound()
        
        if self.shiftWasMultitapped {
            self.shiftWasMultitapped = false
            return
        }
        
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
    
    func updateKeyCaps(lowercase: Bool) {
        if self.layout != nil {
            for (model, key) in self.layout!.modelToView {
                key.text = model.keyCapForCase(!lowercase)
                
                if model.type == Key.KeyType.Shift {
                    switch self.shiftState {
                    case .Disabled:
                        key.highlighted = false
                    case .Enabled:
                        key.highlighted = true
                    case .Locked:
                        key.highlighted = true
                    }
                    
                    (key.shape as? ShiftShape)?.withLock = (self.shiftState == .Locked)
                }
            }
        }
    }
    
    func modeChangeTapped(sender: KeyboardKey) {
        self.playKeySound()
        
        if let toMode = self.layout?.viewToModel[sender]?.toMode {
            self.currentMode = toMode
        }
    }
    
    func setMode(mode: Int) {
        for (pageIndex, page) in enumerate(self.keyboard.pages) {
            for (rowIndex, row) in enumerate(page.rows) {
                for (keyIndex, key) in enumerate(row) {
                    if self.layout?.modelToView[key] != nil {
                        var keyView = self.layout?.modelToView[key]
                        keyView?.hidden = (pageIndex != mode)
                    }
                }
            }
        }
    }
    
    @IBAction func toggleSettings() {
        self.playKeySound()
        
        if let settings = self.settingsView {
            let hidden = settings.hidden
            settings.hidden = !hidden
            self.forwardingView.hidden = hidden
            self.forwardingView.userInteractionEnabled = !hidden
            self.bannerView?.hidden = hidden
        }
    }
    
    // TODO: make this work if cursor position is shifted
    func setCapsIfNeeded() {
        if self.shouldAutoCapitalize() {
            switch self.shiftState {
            case .Disabled:
                self.shiftState = .Enabled
            case .Enabled:
                self.shiftState = .Enabled
            case .Locked:
                self.shiftState = .Locked
            }
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
                        let offset = min(3, countElements(beforeContext))
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
        
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            AudioServicesPlaySystemSound(1104)
        //})
    }
    
    //////////////////////////////////////
    // MOST COMMONLY EXTENDABLE METHODS //
    //////////////////////////////////////
    
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
        let assets = NSBundle(forClass: self.dynamicType).loadNibNamed("DefaultSettings", owner: self, options: nil)
        
        if assets.count > 0 && assets.first is ExtraView {
            if let settingsView = assets.first as? ExtraView {
                settingsView.globalColors = self.dynamicType.globalColors
                settingsView.darkMode = false
                settingsView.solidColorMode = self.solidColorMode()
                
                return settingsView
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
}

//// does not work; drops CPU to 0% when run on device
//extension UIInputView: UIInputViewAudioFeedback {
//    public var enableInputClicksWhenVisible: Bool {
//        return true
//    }
//}
