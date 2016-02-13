//
//  ImageKey.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 11/2/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

class ImageKey: KeyboardKey {
    
    var image: UIImageView? {
        willSet {
            let anImage = image
            anImage?.removeFromSuperview()
        }
        didSet {
            if let imageView = image {
                self.addSubview(imageView)
                imageView.contentMode = UIViewContentMode.ScaleAspectFit
                self.redrawImage()
                updateColors()
            }
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
            let imageSize = CGSizeMake(20, 20)
            let imageOrigin = CGPointMake(
                (self.bounds.width - imageSize.width) / CGFloat(2),
                (self.bounds.height - imageSize.height) / CGFloat(2))
            var imageFrame = CGRectZero
            imageFrame.origin = imageOrigin
            imageFrame.size = imageSize
            
            image.frame = imageFrame
        }
    }
}
