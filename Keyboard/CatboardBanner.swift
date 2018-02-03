//
//  CatboardBanner.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/5/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

/*
This is the demo banner. The banner is needed so that the top row popups have somewhere to go. Might as well fill it
with something (or leave it blank if you like.)
*/

class CatboardBanner: ExtraView {
    
    var catSwitch: UISwitch = UISwitch()
    var catLabel: UILabel = UILabel()
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        
        self.addSubview(self.catSwitch)
        self.addSubview(self.catLabel)
        
        self.catSwitch.isOn = UserDefaults.standard.bool(forKey: kCatTypeEnabled)
        self.catSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        self.catSwitch.addTarget(self, action: #selector(CatboardBanner.respondToSwitch), for: UIControlEvents.valueChanged)
        
        self.updateAppearance()
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
        self.catLabel.frame.origin = CGPoint(x: self.catSwitch.frame.origin.x + self.catSwitch.frame.width + 8, y: self.catLabel.frame.origin.y)
    }
    
    @objc func respondToSwitch() {
        UserDefaults.standard.set(self.catSwitch.isOn, forKey: kCatTypeEnabled)
        self.updateAppearance()
    }
    
    func updateAppearance() {
        if self.catSwitch.isOn {
            self.catLabel.text = "😺"
            self.catLabel.alpha = 1
        }
        else {
            self.catLabel.text = "🐱"
            self.catLabel.alpha = 0.5
        }
        
        self.catLabel.sizeToFit()
    }
}
