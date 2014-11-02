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
    
    class var layoutClass: KeyboardLayout.Type { get { return KeyboardLayout.self }}
    class var layoutConstants: LayoutConstants.Type { get { return LayoutConstants.self }}
    class var globalColors: GlobalColors.Type { get { return GlobalColors.self }}
    
    // TODO: these are declared in KeyboardViewController because extending methods declared in an extension
    // sort of doesn't work all the time
    
    //func keyPressed(key: Key)
    
    // a banner that sits in the empty space on top of the keyboard
    //func createBanner() -> ExtraView?
}
