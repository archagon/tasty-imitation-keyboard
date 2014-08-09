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
class KeyboardConnector: UIView, KeyboardView {
    
    var start: UIView
    var end: UIView
    var startDir: Direction
    var endDir: Direction
    
    // TODO: temporary fix for Swift compiler crash
    var startConnectable: Connectable
    var endConnectable: Connectable
    var convertedStartPoints: (CGPoint, CGPoint)!
    var convertedEndPoints: (CGPoint, CGPoint)!
    
    var color: UIColor { didSet { self.setNeedsDisplay() }}
    var underColor: UIColor { didSet { self.setNeedsDisplay() }}
    var borderColor: UIColor { didSet { self.setNeedsDisplay() }}
    var drawUnder: Bool { didSet { self.setNeedsDisplay() }}
    var drawBorder: Bool { didSet { self.setNeedsDisplay() }}
    var drawShadow: Bool { didSet { self.setNeedsDisplay() }}
    
    var _offset: CGPoint
    
    // TODO: until bug is fixed, make sure start/end and startConnectable/endConnectable are the same object
    init(start: UIView, end: UIView, startConnectable: Connectable, endConnectable: Connectable, startDirection: Direction, endDirection: Direction) {
        self.start = start
        self.end = end
        self.startDir = startDirection
        self.endDir = endDirection
        self.startConnectable = startConnectable
        self.endConnectable = endConnectable
        
        self.color = UIColor.whiteColor()
        self.underColor = UIColor.grayColor()
        self.borderColor = UIColor.blackColor()
        self.drawUnder = true
        self.drawBorder = true
        self.drawShadow = true
        
        self._offset = CGPointZero
        
        super.init(frame: CGRectZero)
        
        self.userInteractionEnabled = false // TODO: why is this even necessary if it's under all the other views?
        self.backgroundColor = UIColor.clearColor()
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.resizeFrame()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.resizeFrame()
        self.setNeedsDisplay()
    }
    
    func generateConvertedPoints() {
        if self.superview == nil {
            return
        }
        
        let startPoints = self.startConnectable.attachmentPoints(self.startDir)
        let endPoints = self.endConnectable.attachmentPoints(self.endDir)
        
        self.convertedStartPoints = (
            self.superview!.convertPoint(startPoints.0, fromView: self.start),
            self.superview!.convertPoint(startPoints.1, fromView: self.start))
        self.convertedEndPoints = (
            self.superview!.convertPoint(endPoints.0, fromView: self.end),
            self.superview!.convertPoint(endPoints.1, fromView: self.end))
    }
    
    func resizeFrame() {
        generateConvertedPoints()
        
        let buffer: CGFloat = 32
        self._offset = CGPointMake(buffer/2, buffer/2)
        
        let minX = min(convertedStartPoints.0.x, convertedStartPoints.1.x, convertedEndPoints.0.x, convertedEndPoints.1.x)
        let minY = min(convertedStartPoints.0.y, convertedStartPoints.1.y, convertedEndPoints.0.y, convertedEndPoints.1.y)
        let maxX = max(convertedStartPoints.0.x, convertedStartPoints.1.x, convertedEndPoints.0.x, convertedEndPoints.1.x)
        let maxY = max(convertedStartPoints.0.y, convertedStartPoints.1.y, convertedEndPoints.0.y, convertedEndPoints.1.y)
        let width = maxX - minX
        let height = maxY - minY
        
        self.frame = CGRectMake(minX - buffer/2, minY - buffer/2, width + buffer, height + buffer)
    }
    
    override func drawRect(rect: CGRect) {
        // TODO: quick hack
        resizeFrame()
        
        let startPoints = self.startConnectable.attachmentPoints(self.startDir)
        let endPoints = self.endConnectable.attachmentPoints(self.endDir)
        
        var myConvertedStartPoints = (
            self.convertPoint(startPoints.0, fromView: self.start),
            self.convertPoint(startPoints.1, fromView: self.start))
        let myConvertedEndPoints = (
            self.convertPoint(endPoints.0, fromView: self.end),
            self.convertPoint(endPoints.1, fromView: self.end))
        
        if self.startDir == self.endDir {
            let tempPoint = myConvertedStartPoints.0
            myConvertedStartPoints.0 = myConvertedStartPoints.1
            myConvertedStartPoints.1 = tempPoint
        }
        
        let ctx = UIGraphicsGetCurrentContext()
        let csp = CGColorSpaceCreateDeviceRGB()
        
        var path = CGPathCreateMutable();
        
        CGPathMoveToPoint(path, nil, myConvertedStartPoints.0.x, myConvertedStartPoints.0.y)
        CGPathAddLineToPoint(path, nil, myConvertedEndPoints.1.x, myConvertedEndPoints.1.y)
        CGPathAddLineToPoint(path, nil, myConvertedEndPoints.0.x, myConvertedEndPoints.0.y)
        CGPathAddLineToPoint(path, nil, myConvertedStartPoints.1.x, myConvertedStartPoints.1.y)
        CGPathCloseSubpath(path)
        
        // for now, assuming axis-aligned attachment points
        
        let isVertical = (self.startDir == Direction.Up || self.startDir == Direction.Down) && (self.endDir == Direction.Up || self.endDir == Direction.Down)
        
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
        
        let shadow = UIColor.blackColor().colorWithAlphaComponent(0.35)
        let shadowOffset = CGSizeMake(0, 1.5)
        let shadowBlurRadius: CGFloat = 12
        
        // shadow is drawn separate from the fill
        // http://stackoverflow.com/questions/6709064/coregraphics-quartz-drawing-shadow-on-transparent-alpha-path
//        CGContextSaveGState(ctx)
//        self.color.setFill()
//        CGContextSetShadowWithColor(ctx, shadowOffset, shadowBlurRadius, shadow.CGColor)
//        CGContextMoveToPoint(ctx, 0, 0);
//        CGContextAddLineToPoint(ctx, self.bounds.width, 0);
//        CGContextAddLineToPoint(ctx, self.bounds.width, self.bounds.height);
//        CGContextAddLineToPoint(ctx, 0, self.bounds.height);
//        CGContextClosePath(ctx);
//        CGContextAddPath(ctx, bezierPath.CGPath)
//        CGContextClip(ctx)
//        CGContextAddPath(ctx, bezierPath.CGPath)
//        CGContextDrawPath(ctx, kCGPathFillStroke)
//        CGContextRestoreGState(ctx)
        
//        CGContextAddPath(ctx, bezierPath.CGPath)
//        CGContextClip(ctx)
        
        CGContextSaveGState(ctx)
        UIColor.blackColor().setFill()
        CGContextSetShadowWithColor(ctx, shadowOffset, shadowBlurRadius, shadow.CGColor)
        bezierPath.fill()
        CGContextRestoreGState(ctx)
        
        if self.drawUnder {
            CGContextTranslateCTM(ctx, 0, 1)
            self.underColor.setFill()
            CGContextAddPath(ctx, bezierPath.CGPath)
            CGContextFillPath(ctx)
            CGContextTranslateCTM(ctx, 0, -1)
        }
        
        self.color.setFill()
        bezierPath.fill()
        
        if self.drawBorder {
            self.borderColor.setStroke()
            CGContextSetLineWidth(ctx, 0.5)
            
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
}
