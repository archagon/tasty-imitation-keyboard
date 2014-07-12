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
    
    var background: KeyboardKeyBackground
    
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
        self.background.enabled = enabled
    }
    }
    
    override var selected: Bool {
    didSet {
        self.background.selected = selected
    }
    }
    
    @IBInspectable override var highlighted: Bool {
    didSet {
//        self.layer.backgroundColor = (highlighted ? UIColor.blueColor().CGColor : UIColor.redColor().CGColor)
        self.background.highlighted = highlighted
    }
    }
    
    init(coder aDecoder: NSCoder!) {
        background = KeyboardKeyBackground(frame: CGRectZero)
        
        super.init(coder: aDecoder)
        
        self.addSubview(background)
    }
    
    init(frame: CGRect) {
        background = KeyboardKeyBackground(frame: CGRectZero)
        
        super.init(frame: frame)
        
        self.addSubview(background)
        
//        self.button.setTitleShadowColor(UIColor.blueColor(), forState: UIControlState.Normal);
//        self.button.titleLabel.font = self.button.titleLabel.font.fontWithSize(frame.height * 0.50)
    }
    
//    override func sizeThatFits(size: CGSize) -> CGSize {
//        return super.sizeThatFits(size)
//    }
    
    override func layoutSubviews() {
        self.redrawText()
    }
    
    func redrawText() {
        self.background.frame = self.bounds
//        self.button.frame = self.bounds
        
//        self.button.setTitle(self.text, forState: UIControlState.Normal)
        self.background.text = (self.text ? self.text : "")
    }
    
    class KeyboardKeyBackground: UIControl {
        
//        let cornerOffset = [0.05, 0.05]
        let cornerOffset = [0.0, 0.0]
        let arcHeightPercentageRadius = 0.15
        let color = [0.98, 1.0, 0.98]
        
        var normalTextColor = [0.25, 0.25, 0.5]
        var disabledTextColor: Array<Double>
        var selectedTextColor: Array<Double>
        
        var currentColor: Array<Double> // TODO: tuple
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
                self.currentColor = color.map { $0 * 0.85 }
                self.label.textColor = UIColor(
                    red: selectedTextColor[0],
                    green: selectedTextColor[1],
                    blue: selectedTextColor[2],
                    alpha: 1.0)
            }
            else {
                self.currentColor = color
                self.label.textColor = UIColor(
                    red: normalTextColor[0],
                    green: normalTextColor[1],
                    blue: normalTextColor[2],
                    alpha: 1.0)
            }
            self.setNeedsDisplay()
        }
        }
        
        init(frame: CGRect) {
            currentColor = self.color
            text = ""
            label = UILabel()
            disabledTextColor = normalTextColor.map { $0 * 1.5 }
            selectedTextColor = normalTextColor.map { $0 * 0.75 }
            
            super.init(frame: frame)
            
            self.contentMode = UIViewContentMode.Redraw
            self.opaque = false
            self.userInteractionEnabled = false
            
            self.label.frame = self.bounds
            self.label.textAlignment = NSTextAlignment.Center
            self.addSubview(self.label)
            self.label.userInteractionEnabled = false
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
            
            let segmentWidth = self.bounds.width * (1 - (cornerOffset[0] * 2))
            let segmentHeight = self.bounds.height * (1 - (cornerOffset[1] * 2))
            let arcLength = segmentHeight * arcHeightPercentageRadius
            
            let startMidpoint = CGPoint(
                x: self.bounds.width * cornerOffset[0],
                y: self.bounds.height * cornerOffset[1] + segmentHeight/2.0)
            
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
                    x: self.bounds.width * cornerOffset[0] + (correctPosition(i, 1) ? segmentWidth : 0),
                    y: self.bounds.height * cornerOffset[1] + (correctPosition(i, 0) ? segmentHeight : 0))
                let nextPoint = CGPoint(
                    x: self.bounds.width * cornerOffset[0] + (correctPosition(i, 0) ? segmentWidth : 0),
                    y: self.bounds.height * cornerOffset[1] + (correctPosition(i, -1) ? segmentHeight : 0))
                
                CGPathAddArcToPoint(path, nil,
                    firstPoint.x,
                    firstPoint.y,
                    nextPoint.x,
                    nextPoint.y,
                    arcLength)
            }
            
            CGPathAddLineToPoint(path, nil, startMidpoint.x, startMidpoint.y)
            CGPathCloseSubpath(path)
            
            var drawColor = self.currentColor
            drawColor.append(1.0)
            let color2 = drawColor.map { $0 * 0.80 }
            color2[3] = 1.0
            let color3 = drawColor.map { $0 * 0.4 }
            color3[3] = 0.85

            let shadowOffset = 2.0
            
            CGContextSetFillColor(ctx, color3)
            CGContextTranslateCTM(ctx, 0, shadowOffset)
            CGContextAddPath(ctx, path)
            CGContextFillPath(ctx)
            CGContextTranslateCTM(ctx, 0, -shadowOffset)
            
            CGContextSetFillColor(ctx, drawColor)
            CGContextAddPath(ctx, path)
            CGContextFillPath(ctx)
            
            CGContextSetStrokeColor(ctx, color2)
            CGContextSetLineWidth(ctx, 1.0)
            CGContextAddPath(ctx, path)
            CGContextStrokePath(ctx)
            
            /////////////
            // cleanup //
            /////////////
            
            CGColorSpaceRelease(csp)
            CGPathRelease(path)
        }
    }
}
