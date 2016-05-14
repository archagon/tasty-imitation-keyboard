//
//  CareboardBanner.swift
//  TastyImitationKeyboard
//
//  Created by Andong Zhan on 5/13/16.
//  Copyright (c) 2014 Andong Zhan. All rights reserved.
//

import UIKit

/*
This is the demo banner. The banner is needed so that the top row popups have somewhere to go. Might as well fill it
with something (or leave it blank if you like.)
*/

class CareboardBanner: ExtraView {
    
    var catSwitch: UISwitch = UISwitch()
    var catLabel: UILabel = UILabel()
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        
//        self.addSubview(self.catSwitch)
//        self.addSubview(self.catLabel)
//        
//        self.catSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey(kCatTypeEnabled)
//        self.catSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75)
//        self.catSwitch.addTarget(self, action: #selector(CareboardBanner.respondToSwitch), forControlEvents: UIControlEvents.ValueChanged)
        
//        self.updateAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.catSwitch.center = self.center
        self.catLabel.center = self.center
        self.catLabel.frame.origin = CGPointMake(self.catSwitch.frame.origin.x + self.catSwitch.frame.width + 8, self.catLabel.frame.origin.y)
    }
    
//    func respondToSwitch() {
//        NSUserDefaults.standardUserDefaults().setBool(self.catSwitch.on, forKey: kCatTypeEnabled)
//        self.updateAppearance()
//    }
    
//    func updateAppearance() {
//        if self.catSwitch.on {
//            self.catLabel.text = "😺"
//            self.catLabel.alpha = 1
//        }
//        else {
//            self.catLabel.text = "🐱"
//            self.catLabel.alpha = 0.5
//        }
//        
//        self.catLabel.sizeToFit()
//    }
}
