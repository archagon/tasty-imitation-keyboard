//
//  KeyboardKeyBackground.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// TODO: CAShapeLayer
// TODO: dark keys semi-transparent, pass through blur; dark theme?
class KeyboardKeyBackground: UIView, KeyboardView, Connectable {
    
    var shadowOffset: Double { didSet { self.setNeedsDisplay() }}
    var cornerRadius: Double {
    didSet {
        self.generatePointsForDrawing()
        self.setNeedsDisplay()
    }
    }
    
    var color: UIColor { didSet { self.setNeedsDisplay() }}
    var underColor: UIColor { didSet { self.setNeedsDisplay() }}
    var borderColor: UIColor { didSet { self.setNeedsDisplay() }}
    var drawUnder: Bool { didSet { self.setNeedsDisplay() }}
    var drawBorder: Bool { didSet { self.setNeedsDisplay() }}
    
    var _startingPoints: [CGPoint]
    var _segmentPoints: [(CGPoint, CGPoint)]
    var _arcCenters: [CGPoint]
    var _arcStartingAngles: [CGFloat]
    
    var _attached: Direction? { didSet { self.setNeedsDisplay() }}
    
    let arcHeightPercentageRadius = 0.15
    
    var text: String {
    didSet {
        self.label.text = text
        self.label.frame = self.bounds
        self.setNeedsDisplay()
    }
    }
    
    var label: UILabel
    
    override init(frame: CGRect) {
        text = "" // TODO: does this call the setter?
        label = UILabel()
        _attached = nil
        
        _startingPoints = []
        _segmentPoints = []
        _arcCenters = []
        _arcStartingAngles = []
        
        shadowOffset = 1.0
        cornerRadius = 3.0
        
        self.color = UIColor.whiteColor()
        self.underColor = UIColor.grayColor()
        self.borderColor = UIColor.blackColor()
        self.drawUnder = true
        self.drawBorder = false
        
        super.init(frame: frame)
        
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
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
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
        
        // order of edge drawing: left edge, down edge, right edge, up edge
        
        // We need to have separate paths for all the edges so we can toggle them as needed.
        // Unfortunately, it doesn't seem possible to assemble the connected fill path
        // by simply using CGPathAddPath, since it closes all the subpaths, so we have to
        // duplicate the code a little bit.
        
        var fillPath = CGPathCreateMutable();
        var edgePaths: [CGMutablePathRef] = []
        var firstEdge = false
        
        for i in 0..<4 {
            if self._attached != nil && self._attached!.toRaw() == i {
                continue
            }
            
            var edgePath = CGPathCreateMutable()
            
            CGPathMoveToPoint(edgePath, nil, self._segmentPoints[i].0.x, self._segmentPoints[i].0.y)
            CGPathAddLineToPoint(edgePath, nil, self._segmentPoints[i].1.x, self._segmentPoints[i].1.y)
            
            // TODO: figure out if this is ncessary
            if !firstEdge {
                CGPathMoveToPoint(fillPath, nil, self._segmentPoints[i].0.x, self._segmentPoints[i].0.y)
                firstEdge = true
            }
            else {
                CGPathAddLineToPoint(fillPath, nil, self._segmentPoints[i].0.x, self._segmentPoints[i].0.y)
            }
            CGPathAddLineToPoint(fillPath, nil, self._segmentPoints[i].1.x, self._segmentPoints[i].1.y)
            
            if (self._attached != nil && self._attached!.toRaw() == ((i + 1) % 4)) {
                // do nothing
            } else {
                CGPathAddRelativeArc(edgePath, nil, self._arcCenters[(i + 1) % 4].x, self._arcCenters[(i + 1) % 4].y, CGFloat(self.cornerRadius), self._arcStartingAngles[(i + 1) % 4], CGFloat(M_PI/2.0))
                CGPathAddRelativeArc(fillPath, nil, self._arcCenters[(i + 1) % 4].x, self._arcCenters[(i + 1) % 4].y, CGFloat(self.cornerRadius), self._arcStartingAngles[(i + 1) % 4], CGFloat(M_PI/2.0))
            }
            
            edgePaths.append(edgePath)
        }
        
        if self.drawUnder && self._attached != Direction.Down {
            CGContextSetFillColorWithColor(ctx, self.underColor.CGColor)
            CGContextAddPath(ctx, fillPath)
            CGContextFillPath(ctx)
        }
        
        CGContextSetFillColorWithColor(ctx, self.color.CGColor)
        CGContextSetStrokeColorWithColor(ctx, self.borderColor.CGColor)
        CGContextSetLineWidth(ctx, 1)
        
        // TODO: border stroke outside, not inside
        CGContextTranslateCTM(ctx, 0, -CGFloat(shadowOffset))
        CGContextSaveGState(ctx)
        CGContextAddPath(ctx, fillPath)
        CGContextClip(ctx)
        CGContextAddPath(ctx, fillPath)
        CGContextFillPath(ctx)
        if self.drawBorder {
            for path in edgePaths {
                CGContextAddPath(ctx, path)
                CGContextStrokePath(ctx)
            }
        }
        CGContextRestoreGState(ctx)
        CGContextTranslateCTM(ctx, 0, CGFloat(shadowOffset))
        
        /////////////
        // cleanup //
        /////////////
        
        // TODO: apparently you don't need to call CFRelease for "annotated" CG APIs... does this apply to paths and color spaces?
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
                self._arcStartingAngles.append(CGFloat(M_PI))
            }
            else if (i == 3) {
                xDir = -1.0
                self._arcStartingAngles.append(CGFloat(0))
            }
            
            if (i == 0) {
                yDir = -1.0
                self._arcStartingAngles.append(CGFloat(M_PI/2.0))
            }
            else if (i == 2) {
                yDir = 1.0
                self._arcStartingAngles.append(CGFloat(-M_PI/2.0))
            }
            
            let p0 = CGPointMake(
                currentPoint.x + CGFloat(xDir * cornerRadius),
                currentPoint.y + CGFloat(shadowOffset) + CGFloat(yDir * cornerRadius))
            let p1 = CGPointMake(
                nextPoint.x - CGFloat(xDir * cornerRadius),
                nextPoint.y + CGFloat(shadowOffset) - CGFloat(yDir * cornerRadius))
            
            self._segmentPoints.append((p0, p1))
            
            let c = CGPointMake(
                p0.x - CGFloat(yDir * cornerRadius),
                p0.y + CGFloat(xDir * cornerRadius))
            
            self._arcCenters.append(c)
        }
    }
    
    func attachmentPoints(direction: Direction) -> (CGPoint, CGPoint) {
        var returnValue = (
            self._segmentPoints[direction.clockwise().toRaw()].0,
            self._segmentPoints[direction.counterclockwise().toRaw()].1)
        
        // TODO: quick hack
        returnValue.0.y -= CGFloat(self.shadowOffset)
        returnValue.1.y -= CGFloat(self.shadowOffset)
        
        return returnValue
    }
    
    func attachmentDirection() -> Direction? {
        return self._attached
    }
    
    func attach(direction: Direction?) {
        self._attached = direction
    }
}

//class KeyboardKeyPopup: KeyboardKeyBackground {
//    
//    init(frame: CGRect, vertical: Bool) {
//        super.init(frame: frame)
//    }
//    
//    // if action is nil, the key is not selectable
//    func addOption(option: String, action: String?) {
//    }
//}
