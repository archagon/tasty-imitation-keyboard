//
//  ImageKey.swift
//  RussianPhoneticKeyboard
//
//  Created by Alexei Baboulevitch on 11/2/14.
//  Copyright (c) 2014 Alexei Baboulevitch. All rights reserved.
//

import UIKit

class ImageKey: KeyboardKey {
    
    var image: UIImageView? {
        didSet {
            self.redrawImage()
            updateColors()
        }
    }
    
    override func updateColors() {
        super.updateColors()
        
        let switchColors = self.highlighted || self.selected
        
        if switchColors {
            if let downTextColor = self.downTextColor {
                self.image?.tintColor = downTextColor
            }
            else {
                self.image?.tintColor = self.textColor
            }
        }
        else {
            self.image?.tintColor = self.textColor
        }
    }
    
    override func refreshShapes() {
        super.refreshShapes()
        self.redrawImage()
    }
    
    func redrawImage() {
        if let image = self.image {
            if image.superview != self {
                image.removeFromSuperview()
                self.addSubview(image)
            }
            
            image.frame.origin = CGPointMake(
                (self.bounds.width - image.frame.width) / CGFloat(2),
                (self.bounds.height - image.frame.height) / CGFloat(2))
        }
    }
}