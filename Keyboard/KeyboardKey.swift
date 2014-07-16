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

enum Direction: Int {
    case Left = 0
    case Down = 1
    case Right = 2
    case Up = 3
}

protocol Connectable {
    func attachmentPoints(direction: Direction) -> (CGPoint, CGPoint)
    func attach(direction: Direction?) // call with nil to detach
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
    var popup: KeyboardKeyPopup?
    
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
        
        self.clipsToBounds = false
        self.addSubview(self.keyView)
        
        let showOptions: UIControlEvents = .TouchDown | .TouchDragInside | .TouchDragEnter
        let hideOptions: UIControlEvents = .TouchUpInside | .TouchUpOutside | .TouchDragOutside
        self.addTarget(self, action: Selector("showPopup"), forControlEvents: showOptions)
        self.addTarget(self, action: Selector("hidePopup"), forControlEvents: hideOptions)
        self.addTarget(self, action: Selector("debugCycle"), forControlEvents: showOptions)
    }
    
    func debugCycle() {
        if self.keyView._attached == nil {
            self.keyView._attached = Direction.Up
        }
        else {
            if self.keyView._attached! == Direction.Up {
                self.keyView._attached = Direction.Left
            }
            else if self.keyView._attached! == Direction.Left {
                self.keyView._attached = Direction.Down
            }
            else if self.keyView._attached! == Direction.Down {
                self.keyView._attached = Direction.Right
            }
            else if self.keyView._attached! == Direction.Right {
                self.keyView._attached = nil
            }
        }
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
    
    func showPopup() {
        if !self.popup {
            let gap = 3
            let popupSize = CGFloat(1.5)
            
            var popupFrame = CGRectMake(0, 0, self.bounds.width * popupSize, self.bounds.height * popupSize)
            popupFrame.origin = CGPointMake(
                (self.bounds.size.width - popupFrame.size.width)/2.0,
                -popupFrame.size.height - CGFloat(gap))
            
            self.popup = KeyboardKeyPopup(frame: popupFrame, vertical: false)
            self.addSubview(self.popup)
            
            self.popup!.text = self.keyView.text
            self.keyView.label.hidden = true
            self.popup!.label.font = self.popup!.label.font.fontWithSize(22 * 1.5)
        }
    }
    
    func hidePopup() {
        if self.popup {
            self.popup!.removeFromSuperview()
            self.popup = nil
            self.keyView.label.hidden = false
        }
    }
    
    class KeyboardKeyBackground: UIControl, Connectable {
        
        var color: UIColor!
        var shadowColor: UIColor!
        var textColor: UIColor!
        var downColor: UIColor!
        var downShadowColor: UIColor!
        var downTextColor: UIColor!
        
        var _attached: Direction? {
        didSet {
            self.setNeedsDisplay()
        }
        }
        
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
            _attached = nil
            
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
            let cornerRadius = 3.0
            
            let segmentWidth: CGFloat = self.bounds.width
            let segmentHeight: CGFloat = self.bounds.height - CGFloat(shadowOffset)
            
            var path = CGPathCreateMutable();
            
//            CGPathMoveToPoint(path, nil, 0, CGFloat(shadowOffset) + segmentHeight)
            
            // order of edge drawing: left edge, down edge, right edge, up edge
            
            // base, untranslated corner points
            let startingPoints = [
                CGPointMake(0, segmentHeight),
                CGPointMake(0, 0),
                CGPointMake(segmentWidth, 0),
                CGPointMake(segmentWidth, segmentHeight),
            ]
            
            // actual coordinates for each edge, including translation
            var segmentPoints: [(CGPoint, CGPoint)] = [] // TODO: is this declaration correct?
            
            // actual coordinates for arc centers for each corner
            var arcCenters: [CGPoint] = []
            
            var arcStartingAngles: [CGFloat] = []
            
            for i in 0..<startingPoints.count {
                let currentPoint = startingPoints[i]
                let nextPoint = startingPoints[(i + 1) % startingPoints.count]
                
                var xDir = 0.0
                var yDir = 0.0
                
                if (i == 1) {
                    xDir = 1.0
                    arcStartingAngles += CGFloat(M_PI)
                }
                else if (i == 3) {
                    xDir = -1.0
                    arcStartingAngles += CGFloat(0)
                }
                
                if (i == 0) {
                    yDir = -1.0
                    arcStartingAngles += CGFloat(M_PI/2.0)
                }
                else if (i == 2) {
                    yDir = 1.0
                    arcStartingAngles += CGFloat(-M_PI/2.0)
                }
                
                let p0 = CGPointMake(
                    currentPoint.x + CGFloat(xDir * cornerRadius),
                    currentPoint.y + CGFloat(shadowOffset) + CGFloat(yDir * cornerRadius))
                let p1 = CGPointMake(
                    nextPoint.x - CGFloat(xDir * cornerRadius),
                    nextPoint.y + CGFloat(shadowOffset) - CGFloat(yDir * cornerRadius))
                
                segmentPoints += (p0, p1)
                
                let c = CGPointMake(
                    p0.x - CGFloat(yDir * cornerRadius),
                    p0.y + CGFloat(xDir * cornerRadius))
                
                arcCenters += c
            }
            
            // here be where we do the drawing
            
            if self._attached && self._attached!.toRaw() == 0 {
                CGPathMoveToPoint(path, nil, segmentPoints[1].0.x, segmentPoints[1].0.y)
            }
            else {
                CGPathMoveToPoint(path, nil, segmentPoints[0].0.x, segmentPoints[0].0.y)
            }
            
            for i in 0..<4 {
                if self._attached && self._attached!.toRaw() == i {
                    continue
                }
                
                CGPathAddLineToPoint(path, nil, segmentPoints[i].0.x, segmentPoints[i].0.y)
                CGPathAddLineToPoint(path, nil, segmentPoints[i].1.x, segmentPoints[i].1.y)
                
                if (self._attached && (self._attached!.toRaw() + 4 - 1) % 4 == i) {
                    // do nothing
                } else {
                    CGPathAddRelativeArc(path, nil, arcCenters[(i + 1) % 4].x, arcCenters[(i + 1) % 4].y, CGFloat(cornerRadius), arcStartingAngles[(i + 1) % 4], CGFloat(M_PI/2.0))
                }
            }
            
            CGPathCloseSubpath(path)
            
            let mainColor = (self.highlighted ? self.downColor : self.color).CGColor
            let shadowColor = (self.highlighted ? self.downShadowColor : self.shadowColor).CGColor
            
            CGContextSetFillColorWithColor(ctx, shadowColor)
            CGContextAddPath(ctx, path)
            CGContextFillPath(ctx)
            
            CGContextSetFillColorWithColor(ctx, mainColor)
            CGContextTranslateCTM(ctx, 0, -CGFloat(shadowOffset))
            CGContextAddPath(ctx, path)
            CGContextFillPath(ctx)
            CGContextTranslateCTM(ctx, 0, CGFloat(shadowOffset))
            
            /////////////
            // cleanup //
            /////////////
            
            CGColorSpaceRelease(csp)
            CGPathRelease(path)
        }
        
        func attachmentPoints(direction: Direction) -> (CGPoint, CGPoint) {
            return (CGPointZero, CGPointZero)
        }
        
        func attach(direction: Direction?) {
            self._attached = direction
        }
    }
    
    class KeyboardKeyPopup: KeyboardKeyBackground {
        
        init(frame: CGRect, vertical: Bool) {
            super.init(frame: frame)
        }
        
        // if action is nil, the key is not selectable
        func addOption(option: String, action: String?) {
        }
    }
}
