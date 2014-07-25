//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class KeyboardViewController: UIInputViewController {
    
    var keyboard: Keyboard
    var forwardingView: ForwardingView
    var layout: KeyboardLayout

    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.keyboard = defaultKeyboard()
        self.forwardingView = ForwardingView(frame: CGRectZero)
        self.layout = KeyboardLayout(model: self.keyboard, superview: self.forwardingView)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.view.addSubview(self.forwardingView)
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.layout.initialize()
        self.setupKeys()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.forwardingView.frame = self.view.bounds
    }
    
    func setupKeys() {
        for rowKeys in self.keyboard.rows {
            for key in rowKeys {
                var keyView = self.layout.viewForKey(key)! // TODO: check
                
                switch key.type {
                case Key.KeyType.KeyboardChange:
                    keyView.addTarget(self, action: "advanceToNextInputMode", forControlEvents: .TouchUpInside)
                case Key.KeyType.Backspace:
                    keyView.addTarget(self, action: "backspacePressed:", forControlEvents: .TouchUpInside)
                default:
                    break
                }
                
                if key.outputText {
                    keyView.addTarget(self, action: "keyPressed:", forControlEvents: .TouchUpInside)
                    keyView.addTarget(self, action: "takeScreenshotDelay", forControlEvents: .TouchDown)
                }
                
                let showOptions: UIControlEvents = .TouchDown | .TouchDragInside | .TouchDragEnter
                let hideOptions: UIControlEvents = .TouchUpInside | .TouchUpOutside | .TouchDragOutside
                
                if key.type == Key.KeyType.Character || key.type == Key.KeyType.Period {
                    keyView.addTarget(keyView, action: Selector("showPopup"), forControlEvents: showOptions)
                    keyView.addTarget(keyView, action: Selector("hidePopup"), forControlEvents: hideOptions)
                }
                
                //        self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), forState: .Normal)
                //        self.nextKeyboardButton.sizeToFit()
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
    
    var blah = 0
    func keyPressed(sender: KeyboardKey) {
        UIDevice.currentDevice().playInputClick()
        
        let model = self.layout.keyForView(sender)
        
        NSLog("context before input: \((self.textDocumentProxy as UITextDocumentProxy).documentContextBeforeInput)")
        NSLog("context after input: \((self.textDocumentProxy as UITextDocumentProxy).documentContextAfterInput)")
        
        if model && model!.outputText {
            if blah < 3 {
                (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).insertText(model!.outputText)
                blah += 1
            }
            else {
                (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).deleteBackward()
                (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).deleteBackward()
                (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).deleteBackward()
                (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).insertText("😽")
                blah = 0
            }
        }
    }
    
    func backspacePressed(sender: KeyboardKey) {
        UIDevice.currentDevice().playInputClick()
        
        (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).deleteBackward()
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
}
