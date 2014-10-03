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
set the name of your subclass in the Info.plist file.
*/

class Catboard: KeyboardViewController {
    
    var runningKeystrokes: Int = 0
    
    override func keyPressed(sender: KeyboardKey) {
        super.keyPressed(sender)
        
        // alas, this doesn't seem to work yet
        UIDevice.currentDevice().playInputClick()

        let model = self.layout.keyForView(sender)

//        NSLog("context before input: \((self.textDocumentProxy as UITextDocumentProxy).documentContextBeforeInput)")
//        NSLog("context after input: \((self.textDocumentProxy as UITextDocumentProxy).documentContextAfterInput)")

        if model != nil && model!.outputText != nil {
            if self.runningKeystrokes < 3 {
                if let textDocumentProxy = self.textDocumentProxy as? UIKeyInput {
                    textDocumentProxy.insertText(model!.outputText!)
                }
                self.runningKeystrokes += 1
            }
            else {
                if let textDocumentProxy = self.textDocumentProxy as? UIKeyInput {
                    textDocumentProxy.deleteBackward()
                    textDocumentProxy.deleteBackward()
                    textDocumentProxy.deleteBackward()
                    textDocumentProxy.insertText("😽")
                }
                self.runningKeystrokes = 0
            }
        }
    }
}
