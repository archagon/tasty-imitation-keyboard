//
//  KeyboardConnector.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

protocol Connectable {
    func attachmentPoints(direction: Direction) -> (CGPoint, CGPoint)
    func attachmentDirection() -> Direction?
    func attach(direction: Direction?) // call with nil to detach
}

// TODO: Xcode crashes
// <ConnectableView: UIView where ConnectableView: Connectable>
class KeyboardConnector: UIView {
    
    var start: UIView
    var end: UIView
    var startDir: Direction
    var endDir: Direction
    
    // TODO: temporary fix for Swift compiler crash
    var startConnectable: Connectable
    var endConnectable: Connectable
    var convertedStartPoints: (CGPoint, CGPoint)!
    var convertedEndPoints: (CGPoint, CGPoint)!
    
    // TODO: until bug is fixed, make sure start/end and startConnectable/endConnectable are the same object
    init(start: UIView, end: UIView, startConnectable: Connectable, endConnectable: Connectable, startDirection: Direction, endDirection: Direction) {
        assert(startConnectable.attachmentDirection() == Direction.Up, "not up")
        assert(endConnectable.attachmentDirection() == Direction.Down, "not down")
        
        self.start = start
        self.end = end
        self.startDir = startDirection
        self.endDir = endDirection
        self.startConnectable = startConnectable
        self.endConnectable = endConnectable
        
        super.init(frame: CGRectZero)
        
        self.backgroundColor = UIColor.clearColor()
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
        
        let startPoints = self.startConnectable.attachmentPoints(self.startDir)
        let endPoints = self.endConnectable.attachmentPoints(self.endDir)
        
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
        let height = maxY - minY + 5
        
        self.frame = CGRectMake(minX, minY, width, height)
    }
    
    override func drawRect(rect: CGRect) {
        resizeFrame()
        
        let startPoints = self.startConnectable.attachmentPoints(self.startDir)
        let endPoints = self.endConnectable.attachmentPoints(self.endDir)
        
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
        
        // for now, assuming axis-aligned attachment points
        
        let isVertical = (self.startDir == .Up || self.startDir == .Down) && (self.endDir == .Up || self.endDir == .Down)
        
        var midpoint: CGFloat
        if  isVertical {
            midpoint = myConvertedStartPoints.0.y + (myConvertedEndPoints.1.y - myConvertedStartPoints.0.y) / 2
        }
        else {
            midpoint = myConvertedStartPoints.0.x + (myConvertedEndPoints.1.x - myConvertedStartPoints.0.x) / 2
        }
        
        var bezierPath = UIBezierPath()
        bezierPath.moveToPoint(myConvertedStartPoints.0)
        bezierPath.addCurveToPoint(
            myConvertedEndPoints.1,
            controlPoint1: (isVertical ?
                CGPointMake(myConvertedStartPoints.0.x, midpoint) :
                CGPointMake(midpoint, myConvertedStartPoints.0.y)),
            controlPoint2: (isVertical ?
                CGPointMake(myConvertedEndPoints.1.x, midpoint) :
                CGPointMake(midpoint, myConvertedEndPoints.1.y)))
        bezierPath.addLineToPoint(myConvertedEndPoints.0)
        bezierPath.addCurveToPoint(
            myConvertedStartPoints.1,
            controlPoint1: (isVertical ?
                CGPointMake(myConvertedEndPoints.0.x, midpoint) :
                CGPointMake(midpoint, myConvertedEndPoints.0.y)),
            controlPoint2: (isVertical ?
                CGPointMake(myConvertedStartPoints.1.x, midpoint) :
                CGPointMake(midpoint, myConvertedStartPoints.1.y)))
        bezierPath.addLineToPoint(myConvertedStartPoints.0)
        bezierPath.closePath()
        
        let borderColor = UIColor(hue: 0, saturation: 0, brightness: 0.68, alpha: 1.0).CGColor
        let shadowColor = UIColor(hue: (220/360.0), saturation: 0.04, brightness: 0.56, alpha: 1)
        
        CGContextSetStrokeColorWithColor(ctx, borderColor)
        CGContextSetLineWidth(ctx, 1)
        
        CGContextTranslateCTM(ctx, 0, 1)
        shadowColor.setFill()
        CGContextAddPath(ctx, bezierPath.CGPath)
        CGContextFillPath(ctx)
        CGContextTranslateCTM(ctx, 0, -1)
        
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextAddPath(ctx, bezierPath.CGPath)
        CGContextClip(ctx)
        CGContextAddPath(ctx, bezierPath.CGPath)
        CGContextFillPath(ctx)
        
        CGContextMoveToPoint(ctx, myConvertedStartPoints.0.x, myConvertedStartPoints.0.y)
        CGContextAddCurveToPoint(
            ctx,
            (isVertical ? myConvertedStartPoints.0.x : midpoint),
            (isVertical ? midpoint : myConvertedStartPoints.0.y),
            (isVertical ? myConvertedEndPoints.1.x : midpoint),
            (isVertical ? midpoint : myConvertedEndPoints.1.y),
            myConvertedEndPoints.1.x,
            myConvertedEndPoints.1.y)
        CGContextStrokePath(ctx)
        
        CGContextMoveToPoint(ctx, myConvertedEndPoints.0.x, myConvertedEndPoints.0.y)
        CGContextAddCurveToPoint(
            ctx,
            (isVertical ? myConvertedEndPoints.0.x : midpoint),
            (isVertical ? midpoint : myConvertedEndPoints.0.y),
            (isVertical ? myConvertedStartPoints.1.x : midpoint),
            (isVertical ? midpoint : myConvertedStartPoints.1.y),
            myConvertedStartPoints.1.x,
            myConvertedStartPoints.1.y)
        CGContextStrokePath(ctx)
    }
}
