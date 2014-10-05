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
    
    // TODO: I dunno what happened, this used to work
    //func keyPressed(key: Key) {}
    
    // TODO: but this one CAN be overriden? what's going on?!
    func banner() -> BannerView { return BannerView() }
}
