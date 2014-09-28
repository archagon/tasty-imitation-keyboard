//
//  Catboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 9/24/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

/*
This is the demo keyboard. If you're implementing your own keyboard, simply follow the example here and then
set the keyboard name in the Info.plist file.
*/

// demo delegate of keyboard
class Catboard: KeyboardViewController {
    
    override func keyPressed(sender: KeyboardKey) {
//        var randomNumber = Int(arc4random() % 200)
//        self.heightConstraint?.constant = CGFloat(200 + randomNumber)
        
//        return;
        UIDevice.currentDevice().playInputClick()
//
//        let model = self.layout.keyForView(sender)
//
//        NSLog("context before input: \((self.textDocumentProxy as UITextDocumentProxy).documentContextBeforeInput)")
//        NSLog("context after input: \((self.textDocumentProxy as UITextDocumentProxy).documentContextAfterInput)")
//
//        // TODO: if let chain
//        if model != nil && model!.outputText != nil {
//            if blah < 3 {
//                (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).insertText(model!.outputText!)
//                blah += 1
//            }
//            else {
//                (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).deleteBackward()
//                (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).deleteBackward()
//                (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).deleteBackward()
//                (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).insertText("😽")
//                blah = 0
//            }
//        }
//        
//        if self.shiftState == .Enabled {
//            self.shiftState = .Disabled
//        }
    }
}
