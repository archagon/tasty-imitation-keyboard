//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

extension UIInputView: UIInputViewAudioFeedback {
    public var enableInputClicksWhenVisible: Bool {
        return true
    }
}

class KeyboardViewController: UIInputViewController {
    
    let backspaceDelay: NSTimeInterval = 0.5
    let backspaceRepeat: NSTimeInterval = 0.05
    
    var keyboard: Keyboard
    var forwardingView: ForwardingView
    var layout: KeyboardLayout
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
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        NSLog("will rotate starting to \(toInterfaceOrientation)")
    }
    
    // TODO: why does the app crash if this isn't here?
    convenience override init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.keyboard = defaultKeyboard()
        self.forwardingView = ForwardingView(frame: CGRectZero)
        self.layout = KeyboardLayout(model: self.keyboard, superview: self.forwardingView)
        self.shiftState = .Disabled
        self.currentMode = 0
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
            
        self.view.addSubview(self.forwardingView)
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
//    override func updateViewConstraints() {
//        // suppresses constraint unsatisfiability on initial zero rect; mostly an issue of log spam
//        // TODO: there's probably a more sensible/correct way to do this
//        if CGRectIsEmpty(self.view.bounds) {
//            NSLayoutConstraint.deactivateConstraints(self.layout.allConstraintObjects)
//        }
//        else {
//            NSLayoutConstraint.activateConstraints(self.layout.allConstraintObjects)
//        }
//
//        super.updateViewConstraints()
//    }
    
    var constraintsAdded: Bool = false
    func setupConstraints() {
        if !constraintsAdded {
            self.forwardingView.setTranslatesAutoresizingMaskIntoConstraints(false)
            
            self.view.addConstraint(
                NSLayoutConstraint(
                    item: self.forwardingView,
                    attribute: NSLayoutAttribute.Left,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.view,
                    attribute: NSLayoutAttribute.Left,
                    multiplier: 1,
                    constant: 0))
            self.view.addConstraint(
                NSLayoutConstraint(
                    item: self.forwardingView,
                    attribute: NSLayoutAttribute.Right,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.view,
                    attribute: NSLayoutAttribute.Right,
                    multiplier: 1,
                    constant: 0))
            self.view.addConstraint(
                NSLayoutConstraint(
                    item: self.forwardingView,
                    attribute: NSLayoutAttribute.Top,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.view,
                    attribute: NSLayoutAttribute.Top,
                    multiplier: 1,
                    constant: 0))
            self.view.addConstraint(
                NSLayoutConstraint(
                    item: self.forwardingView,
                    attribute: NSLayoutAttribute.Bottom,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.view,
                    attribute: NSLayoutAttribute.Bottom,
                    multiplier: 1,
                    constant: 0))
            
            self.layout.initialize()
            self.setupKeys()
            self.constraintsAdded = true
            
            // TODO: read up on swift setter behavior on init
            self.setMode(0)
        }
        
        self.setHeight()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        self.setupConstraints()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.setNeedsUpdateConstraints()
    }
    
//    override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        self.setHeight()
//    }
    
//    override func viewDidAppear(animated: Bool) {
//        self.setHeight()
//    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        self.setHeight()
        
//        self.forwardingView.frame = self.view.bounds
    }
    
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
                    
                    if key.outputText != nil {
                        keyView.addTarget(self, action: "keyPressed:", forControlEvents: .TouchUpInside)
                        //                    keyView.addTarget(self, action: "takeScreenshotDelay", forControlEvents: .TouchDown)
                    }
                    
                    if key.type == Key.KeyType.Character || key.type == Key.KeyType.Period {
                        keyView.addTarget(keyView, action: Selector("showPopup"), forControlEvents: showOptions)
                        keyView.addTarget(keyView, action: Selector("hidePopup"), forControlEvents: hideOptions)
                    }
                    
                    //        self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), forState: .Normal)
                    //        self.nextKeyboardButton.sizeToFit()
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
    
    override func textWillChange(textInput: UITextInput) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(textInput: UITextInput) {
        // The app has just changed the document's contents, the document context has been updated.
    }
    
    func setHeight() {
//        for constraint in self.view.constraints() {
//            var actualConstraint = constraint as NSLayoutConstraint
//            if let identifier = actualConstraint.identifier {
//                if identifier == "UIView-Encapsulated-Layout-Height" {
//                    //actualConstraint.constant = 400
//                    //actualConstraint.active = false
//                    NSLog("system keyboard height: \(actualConstraint.constant)")
//                }
//            }
//        }
//        
//        if self.view.frame.height != 0 {
//            if self.heightConstraint == nil {
//                self.heightConstraint = NSLayoutConstraint(
//                    item:self.view,
//                    attribute:NSLayoutAttribute.Height,
//                    relatedBy:NSLayoutRelation.Equal,
//                    toItem:nil,
//                    attribute:NSLayoutAttribute.NotAnAttribute,
//                    multiplier:0,
//                    constant:400)
//                self.heightConstraint!.priority = 1000
//                
//                self.view.addConstraint(self.heightConstraint!) // TODO: what if view already has constraint added?
//            }
//        }
        
        return;
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
        (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).deleteBackward()
        
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
        (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).deleteBackward()
    }
    
    func shiftDown(sender: KeyboardKey) {
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
        switch self.shiftState {
        case .Disabled:
            self.shiftState = .Locked
            sender.highlighted = true
        case .Enabled:
            self.shiftState = .Locked
            sender.highlighted = true
        case .Locked:
            self.shiftState = .Locked
            sender.highlighted = true
        }
        
        sender.text = "L"
    }
    
    func updateKeyCaps(lowercase: Bool) {
        for (model, key) in self.layout.modelToView {
            key.text = (lowercase ? model.lowercaseKeyCap : model.keyCap)
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
}
