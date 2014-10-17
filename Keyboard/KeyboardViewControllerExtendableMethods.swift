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
    class var bannerClass: BannerView.Type { get { return BannerView.self }}
    class var layoutConstants: LayoutConstants.Type { get { return LayoutConstants.self }}
    class var globalColors: GlobalColors.Type { get { return GlobalColors.self }}
    
    // TODO: I dunno what happened, this used to work
    //func keyPressed(key: Key) {}
}
