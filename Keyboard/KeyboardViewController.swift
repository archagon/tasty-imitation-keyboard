//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

let metrics: [String:Double] = [
    "topBanner": 30
]
func metric(name: String) -> CGFloat { return CGFloat(metrics[name]!) }

class KeyboardViewController: UIInputViewController {
    
    let backspaceDelay: NSTimeInterval = 0.5
    let backspaceRepeat: NSTimeInterval = 0.05
    
    var keyboard: Keyboard
    var forwardingView: ForwardingView
    var layout: KeyboardLayout!
    var heightConstraint: NSLayoutConstraint?
    
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
        self.keyboard = defaultKeyboard()
        self.forwardingView = ForwardingView(frame: CGRectZero)
        self.shiftState = .Disabled
        self.currentMode = 0
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.layout = KeyboardLayout(model: self.keyboard, superview: self.forwardingView, topBanner: 0, banner: self.banner())
        self.view.addSubview(self.forwardingView)

        self.view.setNeedsUpdateConstraints()
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
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
    func setupConstraints() {
        if !constraintsAdded {
            self.layout.initialize()
            self.setupKeys()
            self.constraintsAdded = true
            
            self.setMode(0)
        }
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
//        // suppresses constraint unsatisfiability on initial zero rect; mostly an issue of log spam
//        // TODO: there's probably a more sensible/correct way to do this
//        if CGRectIsEmpty(self.view.bounds) {
//            NSLayoutConstraint.deactivateConstraints(self.layout.allConstraintObjects)
//        }
//        else {
//            NSLayoutConstraint.activateConstraints(self.layout.allConstraintObjects)
//        }
        
        self.setupConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        self.forwardingView.frame = self.view.bounds
    }
    
    override func viewDidAppear(animated: Bool) {
        self.keyboardHeight = self.heightForOrientation(self.interfaceOrientation)
        self.layout.topBanner = metric("topBanner")
    }
    
    // TODO: the new size "snaps" into place on rotation, which I believe is related to performance
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        self.keyboardHeight = self.heightForOrientation(toInterfaceOrientation)
    }
    
    func heightForOrientation(orientation: UIInterfaceOrientation) -> CGFloat {
        let canonicalPortraitHeight = CGFloat(216) //TODO: different size for 6+
        let canonicalLandscapeHeight = CGFloat(162)
        return CGFloat(orientation.isPortrait ? canonicalPortraitHeight + metric("topBanner") : canonicalLandscapeHeight + metric("topBanner"))
    }
    
    /*
    BUG NOTE

    None of the UIContentContainer methods are called for this controller.
    */
    
    //override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    //    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    //}
    
    func setupKeys() {
        for page in keyboard.pages {
            for rowKeys in page.rows { // TODO: quick hack
                for key in rowKeys {
                    var keyView = self.layout.viewForKey(key)! // TODO: check
                    
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
                        keyView.addTarget(self, action: Selector("modeChangeTapped"), forControlEvents: .TouchUpInside)
                    default:
                        break
                    }
                    
                    if key.hasOutput {
                        keyView.addTarget(self, action: "keyPressedHelper:", forControlEvents: .TouchUpInside)
//                    keyView.addTarget(self, action: "takeScreenshotDelay", forControlEvents: .TouchDown)
                    }
                    
                    if key.type == Key.KeyType.Character || key.type == Key.KeyType.Period {
                        keyView.addTarget(keyView, action: Selector("showPopup"), forControlEvents: showOptions)
                        keyView.addTarget(keyView, action: Selector("hidePopup"), forControlEvents: hideOptions)
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
            var imagePath = "/Users/archagon/Documents/Programming/OSX/TransliteratingKeyboard/\(name).png"
            UIImagePNGRepresentation(capturedImage).writeToFile(imagePath, atomically: true)
            
            self.view.backgroundColor = oldViewColor
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }
    
//    override func textWillChange(textInput: UITextInput) {
//        // The app is about to change the document's contents. Perform any preparation here.
//    }
//    
//    override func textDidChange(textInput: UITextInput) {
//        // The app has just changed the document's contents, the document context has been updated.
//    }
    
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
            NSLog("constraint added")
        }
        else {
            self.heightConstraint?.constant = height
        }
    }
    
    func highlightKey(sender: KeyboardKey) {
        sender.highlighted = true
    }
    
    func unHighlightKey(sender: KeyboardKey) {
        sender.highlighted = false
    }
    
    func keyPressedHelper(sender: KeyboardKey) {
        // alas, this doesn't seem to work yet
        UIDevice.currentDevice().playInputClick()
        
        if let model = self.layout.keyForView(sender) {
            self.keyPressed(model)
        }
        
        if self.shiftState == ShiftState.Enabled {
            self.shiftState = ShiftState.Disabled
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
        
        // first delete
        UIDevice.currentDevice().playInputClick()
        
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
        if self.shiftWasMultitapped {
            self.shiftWasMultitapped = false
            return
        }
        
        switch self.shiftState {
        case .Disabled:
            self.shiftState = .Enabled
            sender.highlighted = true
        case .Enabled:
            self.shiftState = .Disabled
            sender.highlighted = false
        case .Locked:
            self.shiftState = .Disabled
            sender.highlighted = false
        }
        
        sender.text = "⇪"
    }
    
    func shiftDoubleTapped(sender: KeyboardKey) {
        self.shiftWasMultitapped = true
        
        switch self.shiftState {
        case .Disabled:
            self.shiftState = .Locked
            sender.text = "L"
            sender.highlighted = true
        case .Enabled:
            self.shiftState = .Locked
            sender.text = "L"
            sender.highlighted = true
        case .Locked:
            self.shiftState = .Disabled
            sender.text = "⇪"
            sender.highlighted = false
        }
    }
    
    func updateKeyCaps(lowercase: Bool) {
        for (model, key) in self.layout.modelToView {
            key.text = model.keyCapForCase(!lowercase)
        }
    }
    
    func modeChangeTapped() {
        self.currentMode = ((self.currentMode + 1) % 3)
    }
    
    func setMode(mode: Int) {
        for (pageIndex, page) in enumerate(self.keyboard.pages) {
            for (rowIndex, row) in enumerate(page.rows) {
                for (keyIndex, key) in enumerate(row) {
                    if self.layout.modelToView[key] != nil {
                        var keyView = self.layout.modelToView[key]
                        keyView?.hidden = (pageIndex != mode)
                    }
                }
            }
        }
    }
    
    func keyPressed(key: Key) {}
}

//// does not work; drops CPU to 0% when run on device
//extension UIInputView: UIInputViewAudioFeedback {
//    public var enableInputClicksWhenVisible: Bool {
//        return true
//    }
//}
