//
//  KeyboardViewControllerExtendableMethods.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 9/28/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

extension KeyboardViewController {
    
    ///////////////////////////////////////////////
    // OVERRIDE THESE METHODS IN YOUR SUPERCLASS //
    ///////////////////////////////////////////////
    
    // Be sure to call super.
    func keyPressed(sender: KeyboardKey) {
        if self.shiftState == ShiftState.Enabled {
            self.shiftState = ShiftState.Disabled
        }
    }
}
