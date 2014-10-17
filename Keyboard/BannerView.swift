//
//  BannerView.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/5/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// this banner sits in the empty space on top of the keyboard
class BannerView: UIView {
    
    var globalColors: GlobalColors.Type
    var darkMode: Bool
    var solidColorMode: Bool
    
    required init(globalColors: GlobalColors.Type, darkMode: Bool, solidColorMode: Bool) {
        self.globalColors = globalColors
        self.darkMode = darkMode
        self.solidColorMode = solidColorMode
        
        super.init(frame: CGRectZero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
