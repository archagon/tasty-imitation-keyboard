//
//  KeyboardInputTraits.swift
//  RussianPhoneticKeyboard
//
//  Created by Alexei Baboulevitch on 11/1/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

//        optional var autocorrectionType: UITextAutocorrectionType { get set } // default is UITextAutocorrectionTypeDefault
//        @availability(iOS, introduced=5.0)
//        optional var spellCheckingType: UITextSpellCheckingType { get set } // default is UITextSpellCheckingTypeDefault;
//        optional var keyboardType: UIKeyboardType { get set } // default is UIKeyboardTypeDefault
//        optional var returnKeyType: UIReturnKeyType { get set } // default is UIReturnKeyDefault (See note under UIReturnKeyType enum)
//        optional var enablesReturnKeyAutomatically: Bool { get set } // default is NO (when YES, will automatically disable return key when text widget has zero-length contents, and will automatically enable when text widget has non-zero-length contents)

var traitPollingTimer: CADisplayLink?

extension KeyboardViewController {
    
    func addInputTraitsObservers() {
        // note that KVO doesn't work on textDocumentProxy, so we have to poll
        traitPollingTimer?.invalidate()
        traitPollingTimer = UIScreen.main.displayLink(withTarget: self, selector: #selector(KeyboardViewController.pollTraits))
        traitPollingTimer?.add(to: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    @objc func pollTraits() {
        let proxy = self.textDocumentProxy
        
        if let layout = self.layout {
            let appearanceIsDark = (proxy.keyboardAppearance == UIKeyboardAppearance.dark)
            if appearanceIsDark != layout.darkMode {
                self.updateAppearances(appearanceIsDark)
            }
        }
    }
}
