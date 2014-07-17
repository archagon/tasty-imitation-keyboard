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
    case Down = 3
    case Right = 2
    case Up = 1
    
    func clockwise() -> Direction {
        switch self {
        case Left:
            return Up
        case Right:
            return Down
        case Up:
            return Right
        case Down:
            return Left
        }
    }
    
    func counterclockwise() -> Direction {
        switch self {
        case Left:
            return Down
        case Right:
            return Up
        case Up:
            return Left
        case Down:
            return Right
        }
    }
}

protocol Connectable {
    func attachmentPoints(direction: Direction) -> (CGPoint, CGPoint)
    func attach(direction: Direction?) // call with nil to detach
}

// TODO: Xcode crashes
class KeyboardConnector: UIView {
    
    var start: UIView
    var end: UIView
    
    // TODO: temporary fix for Swift compiler crash
    var startConnectable: Connectable
    var endConnectable: Connectable
    var convertedStartPoints: (CGPoint, CGPoint)!
    var convertedEndPoints: (CGPoint, CGPoint)!
    
    init<ConnectableView: UIView where ConnectableView: Connectable>(start: ConnectableView, end: ConnectableView) {
        self.start = start
        self.end = end
        self.startConnectable = start
        self.endConnectable = end
    
        super.init(frame: CGRectZero)
        
        self.backgroundColor = UIColor.clearColor()
//        self.backgroundColor = UIColor.redColor()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.resizeFrame()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeFrame()
    }
    
    func generateConvertedPoints() {
        if !self.superview {
            return
        }
        
        let startPoints = self.startConnectable.attachmentPoints(.Up)
        let endPoints = self.endConnectable.attachmentPoints(.Down)
        
        self.convertedStartPoints = (
            self.superview.convertPoint(startPoints.0, fromView: self.start),
            self.superview.convertPoint(startPoints.1, fromView: self.start))
        self.convertedEndPoints = (
            self.superview.convertPoint(endPoints.0, fromView: self.end),
            self.superview.convertPoint(endPoints.1, fromView: self.end))
    }
    
    func resizeFrame() {
        generateConvertedPoints()
        
        let minX = min(convertedStartPoints.0.x, convertedStartPoints.1.x, convertedEndPoints.0.x, convertedEndPoints.1.x)
        let minY = min(convertedStartPoints.0.y, convertedStartPoints.1.y, convertedEndPoints.0.y, convertedEndPoints.1.y)
        let maxX = max(convertedStartPoints.0.x, convertedStartPoints.1.x, convertedEndPoints.0.x, convertedEndPoints.1.x)
        let maxY = max(convertedStartPoints.0.y, convertedStartPoints.1.y, convertedEndPoints.0.y, convertedEndPoints.1.y)
        let width = maxX - minX
        let height = maxY - minY + 15
        
        self.frame = CGRectMake(minX, minY - 15, width, height)
    }
    
    override func drawRect(rect: CGRect) {
        let startPoints = self.startConnectable.attachmentPoints(.Up)
        let endPoints = self.endConnectable.attachmentPoints(.Down)
        
        let myConvertedStartPoints = (
            self.convertPoint(startPoints.0, fromView: self.start),
            self.convertPoint(startPoints.1, fromView: self.start))
        let myConvertedEndPoints = (
            self.convertPoint(endPoints.0, fromView: self.end),
            self.convertPoint(endPoints.1, fromView: self.end))
        
        let ctx = UIGraphicsGetCurrentContext()
        let csp = CGColorSpaceCreateDeviceRGB()
        
        var path = CGPathCreateMutable();
        CGPathRetain(path)
        
        CGPathMoveToPoint(path, nil, myConvertedStartPoints.0.x, myConvertedStartPoints.0.y)
        CGPathAddLineToPoint(path, nil, myConvertedEndPoints.1.x, myConvertedEndPoints.1.y)
        CGPathAddLineToPoint(path, nil, myConvertedEndPoints.0.x, myConvertedEndPoints.0.y)
        CGPathAddLineToPoint(path, nil, myConvertedStartPoints.1.x, myConvertedStartPoints.1.y)
        CGPathCloseSubpath(path)
        
        let borderColor = UIColor(hue: 0, saturation: 0, brightness: 0.68, alpha: 1.0).CGColor
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextSetStrokeColorWithColor(ctx, borderColor)
        CGContextSetLineWidth(ctx, 1)
        
        CGContextAddPath(ctx, path)
        CGContextClip(ctx)
        CGContextAddPath(ctx, path)
        CGContextFillPath(ctx)
        
        CGContextMoveToPoint(ctx, myConvertedStartPoints.0.x, myConvertedStartPoints.0.y)
        CGContextAddLineToPoint(ctx, myConvertedEndPoints.1.x, myConvertedEndPoints.1.y)
        CGContextStrokePath(ctx)
        CGContextMoveToPoint(ctx, myConvertedEndPoints.0.x, myConvertedEndPoints.0.y)
        CGContextAddLineToPoint(ctx, myConvertedStartPoints.1.x, myConvertedStartPoints.1.y)
        CGContextStrokePath(ctx)
        
//        CGPathRelease(path)
    }
}

@IBDesignable class KeyboardKey: UIControl {
    
    var keyView: KeyboardKeyBackground
    var popup: KeyboardKeyPopup?
    var connector: KeyboardConnector?
    
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
//        self.addTarget(self, action: Selector("debugCycle"), forControlEvents: showOptions)
    }
    
    func debugCycle() {
        if self.keyView._attached == nil {
            self.keyView._attached = Direction.Left
        }
        else {
            if self.keyView._attached! == Direction.Up {
                self.keyView._attached = nil
            }
            else if self.keyView._attached! == Direction.Left {
                self.keyView._attached = Direction.Down
            }
            else if self.keyView._attached! == Direction.Down {
                self.keyView._attached = Direction.Right
            }
            else if self.keyView._attached! == Direction.Right {
                self.keyView._attached = Direction.Up
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
    
    override func drawRect(rect: CGRect) {
//        super.drawRect(rect)
    }
    
    func showPopup() {
        if !self.popup {
            let gap = 2
            
            var popupFrame = CGRectMake(0, 0, 53, 53)
            popupFrame.origin = CGPointMake(
                (self.bounds.size.width - popupFrame.size.width)/2.0,
                -popupFrame.size.height - CGFloat(gap))
            
            self.popup = KeyboardKeyPopup(frame: popupFrame, vertical: false)
            self.popup!.cornerRadius = 9.0
            self.addSubview(self.popup)
            
            self.popup!.text = self.keyView.text
            self.keyView.label.hidden = true
            self.popup!.label.font = self.popup!.label.font.fontWithSize(22 * 2.0)
            
            self.popup!.attach(Direction.Down)
            self.keyView.attach(Direction.Up)
            
            self.connector = KeyboardConnector(start: self.keyView, end: self.popup!)
            self.addSubview(self.connector)
            
            self.popup!.border = true
            self.keyView.border = true
        }
    }
    
    func hidePopup() {
        if self.popup {
            self.connector?.removeFromSuperview()
            self.connector = nil
            
            self.popup?.removeFromSuperview()
            self.popup = nil
            
            self.keyView.label.hidden = false
            self.keyView.attach(nil)
            
            self.keyView.border = false
        }
    }
    
    class KeyboardKeyBackground: UIControl, Connectable {
        
        var shadowOffset: Double
        var cornerRadius: Double
        var border: Bool {
        didSet {
            generatePointsForDrawing() // TODO: add this elsewhere as well
            self.setNeedsDisplay()
        }
        }
        
        var color: UIColor!
        var shadowColor: UIColor!
        var textColor: UIColor!
        var downColor: UIColor!
        var downShadowColor: UIColor!
        var downTextColor: UIColor!
        var borderColor: UIColor!
        
        var _startingPoints: [CGPoint]
        var _segmentPoints: [(CGPoint, CGPoint)]
        var _arcCenters: [CGPoint]
        var _arcStartingAngles: [CGFloat]
        
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
            
            _startingPoints = []
            _segmentPoints = []
            _arcCenters = []
            _arcStartingAngles = []
            
            shadowOffset = 1.0
            cornerRadius = 3.0
            border = false
            
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
            self.clipsToBounds = false
            self.addSubview(self.label)
            
            generatePointsForDrawing()
        }
        
        func setDefaultColors() {
            self.color = UIColor(red: 0.98, green: 1.0, blue: 0.98, alpha: 1.0)
            self.shadowColor = UIColor(red: 0.98 * 0.4, green: 1.0 * 0.4, blue: 0.98 * 0.4, alpha: 1.0)
            self.textColor = UIColor(red: 0.25, green: 0.25, blue: 0.5, alpha: 1.0)
            self.downColor = UIColor(red: 0.98 * 0.85, green: 1.0 * 0.85, blue: 0.98 * 0.85, alpha: 1.0)
            self.downShadowColor = UIColor(red: 0.98 * 0.4 * 0.85, green: 1.0 * 0.4 * 0.85, blue: 0.98 * 0.4 * 0.85, alpha: 1.0)
            self.downTextColor = UIColor(red: 0.25 * 0.75, green: 0.25 * 0.75, blue: 0.5 * 0.75, alpha: 1.0)
            self.borderColor = UIColor(hue: 0, saturation: 0, brightness: 0.68, alpha: 1.0)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            generatePointsForDrawing()
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
            
            var path = CGPathCreateMutable();
            
            // order of edge drawing: left edge, down edge, right edge, up edge
            
            // here be where we do the drawing
            
            if self._attached {
                NSLog("skipping: \(self._attached!.toRaw())")
            }
            
            if self._attached && self._attached!.toRaw() == 0 {
                CGPathMoveToPoint(path, nil, self._segmentPoints[1].0.x, self._segmentPoints[1].0.y)
            }
            else {
                CGPathMoveToPoint(path, nil, self._segmentPoints[0].0.x, self._segmentPoints[0].0.y)
            }
            
            for i in 0..<4 {
                if self._attached && self._attached!.toRaw() == i {
                    continue
                }
                
                CGPathAddLineToPoint(path, nil, self._segmentPoints[i].0.x, self._segmentPoints[i].0.y)
                CGPathAddLineToPoint(path, nil, self._segmentPoints[i].1.x, self._segmentPoints[i].1.y)
                
                if (self._attached && (self._attached!.toRaw() + 4 - 1) % 4 == i) {
                    // do nothing
                } else {
                    CGPathAddRelativeArc(path, nil, self._arcCenters[(i + 1) % 4].x, self._arcCenters[(i + 1) % 4].y, CGFloat(self.cornerRadius), self._arcStartingAngles[(i + 1) % 4], CGFloat(M_PI/2.0))
                }
            }
            
//            CGPathCloseSubpath(path)
            
            let mainColor = (self.highlighted ? self.downColor : self.color).CGColor
            let shadowColor = (self.highlighted ? self.downShadowColor : self.shadowColor).CGColor
            
            if !(self._attached && self._attached! == .Down) {
                CGContextSetFillColorWithColor(ctx, shadowColor)
                CGContextAddPath(ctx, path)
                CGContextFillPath(ctx)
            }
            
            CGContextSetFillColorWithColor(ctx, mainColor)
            CGContextSetStrokeColorWithColor(ctx, self.borderColor.CGColor)
            CGContextSetLineWidth(ctx, 1)
            
            // TODO: border stroke outside, not inside
            CGContextTranslateCTM(ctx, 0, -CGFloat(shadowOffset))
            CGContextSaveGState(ctx)
            CGContextAddPath(ctx, path)
            CGContextClip(ctx)
            CGContextAddPath(ctx, path)
            CGContextFillPath(ctx)
            if self.border {
                CGContextAddPath(ctx, path)
                CGContextStrokePath(ctx)
            }
            CGContextRestoreGState(ctx)
            CGContextTranslateCTM(ctx, 0, CGFloat(shadowOffset))
            
            /////////////
            // cleanup //
            /////////////
            
            CGColorSpaceRelease(csp)
            CGPathRelease(path)
        }
        
        func generatePointsForDrawing() {
            let segmentWidth = self.bounds.width
            let segmentHeight = self.bounds.height - CGFloat(shadowOffset)
            
            // base, untranslated corner points
            self._startingPoints = [
                CGPointMake(0, segmentHeight),
                CGPointMake(0, 0),
                CGPointMake(segmentWidth, 0),
                CGPointMake(segmentWidth, segmentHeight),
            ]
            
            // actual coordinates for each edge, including translation
            self._segmentPoints = [] // TODO: is this declaration correct?
            
            // actual coordinates for arc centers for each corner
            self._arcCenters = []
            
            self._arcStartingAngles = []
            
            for i in 0 ..< self._startingPoints.count {
                let currentPoint = self._startingPoints[i]
                let nextPoint = self._startingPoints[(i + 1) % self._startingPoints.count]
                
                var xDir = 0.0
                var yDir = 0.0
                
                if (i == 1) {
                    xDir = 1.0
                    self._arcStartingAngles += CGFloat(M_PI)
                }
                else if (i == 3) {
                    xDir = -1.0
                    self._arcStartingAngles += CGFloat(0)
                }
                
                if (i == 0) {
                    yDir = -1.0
                    self._arcStartingAngles += CGFloat(M_PI/2.0)
                }
                else if (i == 2) {
                    yDir = 1.0
                    self._arcStartingAngles += CGFloat(-M_PI/2.0)
                }
                
                let p0 = CGPointMake(
                    currentPoint.x + CGFloat(xDir * cornerRadius),
                    currentPoint.y + CGFloat(shadowOffset) + CGFloat(yDir * cornerRadius))
                let p1 = CGPointMake(
                    nextPoint.x - CGFloat(xDir * cornerRadius),
                    nextPoint.y + CGFloat(shadowOffset) - CGFloat(yDir * cornerRadius))
                
                self._segmentPoints += (p0, p1)
                
                let c = CGPointMake(
                    p0.x - CGFloat(yDir * cornerRadius),
                    p0.y + CGFloat(xDir * cornerRadius))
                
                self._arcCenters += c
            }
        }
        
        func attachmentPoints(direction: Direction) -> (CGPoint, CGPoint) {
            var returnValue = (
                self._segmentPoints[direction.clockwise().toRaw()].0,
                self._segmentPoints[direction.counterclockwise().toRaw()].1)
            
            // TODO: quick hack
            if direction == .Down {
                returnValue.0.y -= CGFloat(self.shadowOffset)
                returnValue.1.y -= CGFloat(self.shadowOffset)
            }
            
            return returnValue
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
