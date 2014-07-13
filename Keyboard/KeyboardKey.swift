//
//  KeyboardKey.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// components
//     - large letter popup
//     - if hold, show extra menu — default if finger slides off
//     - translucent buttons
//     - light and dark themes
//     - iPad sizes
//     - iPad slide apart keyboard
//     - JSON-like parsing
//     > storyboard + custom widget
//     > framework

protocol Connectable {
}

class KeyboardConnector: UIView {
}

func drawConnection<T: Connectable>(conn1: T, conn2: T) {
    // take coords of conn1
    // take coords of conn2
    // draw splines between them using protocol colors and specs
    // done!
}

@IBDesignable class KeyboardKey: UIControl {
    
    var keyView: KeyboardKeyBackground
    
    @IBInspectable var text: String! {
    didSet {
        self.redrawText()
    }
    }
    
    override var frame: CGRect {
    didSet {
        self.redrawText()
    }
    }
    
    override var enabled: Bool {
    didSet {
        self.keyView.enabled = enabled
    }
    }
    
    override var selected: Bool {
    didSet {
        self.keyView.selected = selected
    }
    }
    
    @IBInspectable override var highlighted: Bool {
    didSet {
//        self.layer.backgroundColor = (highlighted ? UIColor.blueColor().CGColor : UIColor.redColor().CGColor)
        self.keyView.highlighted = highlighted
    }
    }
    
    init(coder aDecoder: NSCoder!) {
        self.keyView = KeyboardKeyBackground(frame: CGRectZero)
        
        super.init(coder: aDecoder)
        
        self.addSubview(self.keyView)
    }
    
    init(frame: CGRect) {
        self.keyView = KeyboardKeyBackground(frame: CGRectZero)
        
        super.init(frame: frame)
        
        self.addSubview(self.keyView)
    }
    
//    override func sizeThatFits(size: CGSize) -> CGSize {
//        return super.sizeThatFits(size)
//    }
    
    override func layoutSubviews() {
        self.redrawText()
    }
    
    func redrawText() {
        self.keyView.frame = self.bounds
//        self.button.frame = self.bounds
        
//        self.button.setTitle(self.text, forState: UIControlState.Normal)
        self.keyView.text = (self.text ? self.text : "")
    }
    
    class KeyboardKeyBackground: UIControl {
        
        var color: UIColor!
        var shadowColor: UIColor!
        var textColor: UIColor!
        var downColor: UIColor!
        var downShadowColor: UIColor!
        var downTextColor: UIColor!
        
        let arcHeightPercentageRadius = 0.15
        
        var text: String {
        didSet {
            self.label.text = text
            self.label.frame = self.bounds
            self.setNeedsDisplay()
        }
        }
        
        var label: UILabel
    
        override var highlighted: Bool {
        didSet {
            if highlighted {
                self.label.textColor = self.downTextColor
            }
            else {
                self.label.textColor = self.textColor
            }
            self.setNeedsDisplay()
        }
        }
        
        init(frame: CGRect) {
            text = "" // TODO: does this call the setter?
            label = UILabel()
            
            super.init(frame: frame)
            
            self.setDefaultColors()
            
            self.contentMode = UIViewContentMode.Redraw
            self.opaque = false
            self.userInteractionEnabled = false
            
            self.label.textAlignment = NSTextAlignment.Center
            self.label.font = self.label.font.fontWithSize(22)
            self.label.adjustsFontSizeToFitWidth = true
//            self.label.minimumFontSize = 10
            self.label.userInteractionEnabled = false
            self.addSubview(self.label)
        }
        
        func setDefaultColors() {
            self.color = UIColor(red: 0.98, green: 1.0, blue: 0.98, alpha: 1.0)
            self.shadowColor = UIColor(red: 0.98 * 0.4, green: 1.0 * 0.4, blue: 0.98 * 0.4, alpha: 1.0)
            self.textColor = UIColor(red: 0.25, green: 0.25, blue: 0.5, alpha: 1.0)
            self.downColor = UIColor(red: 0.98 * 0.85, green: 1.0 * 0.85, blue: 0.98 * 0.85, alpha: 1.0)
            self.downShadowColor = UIColor(red: 0.98 * 0.4 * 0.85, green: 1.0 * 0.4 * 0.85, blue: 0.98 * 0.4 * 0.85, alpha: 1.0)
            self.downTextColor = UIColor(red: 0.25 * 0.75, green: 0.25 * 0.75, blue: 0.5 * 0.75, alpha: 1.0)
        }
        
        override func layoutSubviews() {
            self.label.frame = self.bounds
        }
        
        override func drawRect(rect: CGRect) {
            ///////////
            // setup //
            ///////////
            
            let ctx = UIGraphicsGetCurrentContext()
            let csp = CGColorSpaceCreateDeviceRGB()
            
            /////////////////////////
            // draw the background //
            /////////////////////////
            
            CGContextSetFillColorWithColor(ctx, UIColor.clearColor().CGColor)
            CGContextFillRect(ctx, self.bounds)
            
            /////////////////////
            // draw the border //
            /////////////////////
            
            let shadowOffset = 1.0
            
            let segmentWidth = self.bounds.width
            let segmentHeight = self.bounds.height - shadowOffset
            let arcLength = segmentHeight * arcHeightPercentageRadius
            
            let startMidpoint = CGPoint(x: 0, y: segmentHeight/2.0)
            
            var path = CGPathCreateMutable();
            
            CGPathMoveToPoint(path, nil, startMidpoint.x, startMidpoint.y)
            
            func correctPosition(index: Int, offset: Int) -> Bool {
                let shiftedOffset = offset % 4
                var shiftedIndex = index - shiftedOffset
                shiftedIndex = (shiftedIndex + 4) % 4
                return shiftedIndex < 2
            }
            
            for i in 0...3 {
                let firstPoint = CGPoint(
                    x: correctPosition(i, 1) ? segmentWidth : 0,
                    y: correctPosition(i, 0) ? segmentHeight : 0)
                let nextPoint = CGPoint(
                    x: correctPosition(i, 0) ? segmentWidth : 0,
                    y: correctPosition(i, -1) ? segmentHeight : 0)
                
                CGPathAddArcToPoint(path, nil,
                    firstPoint.x,
                    firstPoint.y,
                    nextPoint.x,
                    nextPoint.y,
                    arcLength)
            }
            
            CGPathAddLineToPoint(path, nil, startMidpoint.x, startMidpoint.y)
            CGPathCloseSubpath(path)
            
            let mainColor = (self.highlighted ? self.downColor : self.color).CGColor
            let shadowColor = (self.highlighted ? self.downShadowColor : self.shadowColor).CGColor
            
            CGContextSetFillColorWithColor(ctx, shadowColor)
            CGContextTranslateCTM(ctx, 0, shadowOffset)
            CGContextAddPath(ctx, path)
            CGContextFillPath(ctx)
            CGContextTranslateCTM(ctx, 0, -shadowOffset)
            
            CGContextSetFillColorWithColor(ctx, mainColor)
            CGContextAddPath(ctx, path)
            CGContextFillPath(ctx)
            
            //CGContextSetStrokeColor(ctx, color2)
            //CGContextSetLineWidth(ctx, 1.0)
            //CGContextAddPath(ctx, path)
            //CGContextStrokePath(ctx)
            
            /////////////
            // cleanup //
            /////////////
            
            CGColorSpaceRelease(csp)
            CGPathRelease(path)
        }
    }
}
