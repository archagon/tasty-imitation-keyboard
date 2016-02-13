//
//  KeyboardConnector.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

protocol Connectable: class {
    func attachmentPoints(direction: Direction) -> (CGPoint, CGPoint)
    func attachmentDirection() -> Direction?
    func attach(direction: Direction?) // call with nil to detach
}

// TODO: Xcode crashes -- as of 2014-10-9, still crashes if implemented
// <ConnectableView: UIView where ConnectableView: Connectable>
class KeyboardConnector: KeyboardKeyBackground {

    var start: UIView
    var end: UIView
    var startDir: Direction
    var endDir: Direction

    weak var startConnectable: Connectable?
    weak var endConnectable: Connectable?
    var convertedStartPoints: (CGPoint, CGPoint)!
    var convertedEndPoints: (CGPoint, CGPoint)!
    
    var offset: CGPoint
    
    // TODO: until bug is fixed, make sure start/end and startConnectable/endConnectable are the same object
    init(cornerRadius: CGFloat, underOffset: CGFloat, start s: UIView, end e: UIView, startConnectable sC: Connectable, endConnectable eC: Connectable, startDirection: Direction, endDirection: Direction) {
        start = s
        end = e
        startDir = startDirection
        endDir = endDirection
        startConnectable = sC
        endConnectable = eC

        offset = CGPointZero

        super.init(cornerRadius: cornerRadius, underOffset: underOffset)
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        self.resizeFrame()
        super.layoutSubviews()
    }

    func generateConvertedPoints() {
        if self.startConnectable == nil || self.endConnectable == nil {
            return
        }
        
        if let superview = self.superview {
            let startPoints = self.startConnectable!.attachmentPoints(self.startDir)
            let endPoints = self.endConnectable!.attachmentPoints(self.endDir)

            self.convertedStartPoints = (
                superview.convertPoint(startPoints.0, fromView: self.start),
                superview.convertPoint(startPoints.1, fromView: self.start))
            self.convertedEndPoints = (
                superview.convertPoint(endPoints.0, fromView: self.end),
                superview.convertPoint(endPoints.1, fromView: self.end))
        }
    }

    func resizeFrame() {
        generateConvertedPoints()

        let buffer: CGFloat = 32
        self.offset = CGPointMake(buffer/2, buffer/2)

        let minX = min(convertedStartPoints.0.x, convertedStartPoints.1.x, convertedEndPoints.0.x, convertedEndPoints.1.x)
        let minY = min(convertedStartPoints.0.y, convertedStartPoints.1.y, convertedEndPoints.0.y, convertedEndPoints.1.y)
        let maxX = max(convertedStartPoints.0.x, convertedStartPoints.1.x, convertedEndPoints.0.x, convertedEndPoints.1.x)
        let maxY = max(convertedStartPoints.0.y, convertedStartPoints.1.y, convertedEndPoints.0.y, convertedEndPoints.1.y)
        let width = maxX - minX
        let height = maxY - minY
        
        self.frame = CGRectMake(minX - buffer/2, minY - buffer/2, width + buffer, height + buffer)
    }
    
    override func generatePointsForDrawing(bounds: CGRect) {
        if self.startConnectable == nil || self.endConnectable == nil {
            return
        }
        
        //////////////////
        // prepare data //
        //////////////////

        let startPoints = self.startConnectable!.attachmentPoints(self.startDir)
        let endPoints = self.endConnectable!.attachmentPoints(self.endDir)

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

        let path = CGPathCreateMutable();

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

        let bezierPath = UIBezierPath()
        var currentEdgePath = UIBezierPath()
        var edgePaths = [UIBezierPath]()
        
        bezierPath.moveToPoint(myConvertedStartPoints.0)
        
        bezierPath.addCurveToPoint(
            myConvertedEndPoints.1,
            controlPoint1: (isVertical ?
                CGPointMake(myConvertedStartPoints.0.x, midpoint) :
                CGPointMake(midpoint, myConvertedStartPoints.0.y)),
            controlPoint2: (isVertical ?
                CGPointMake(myConvertedEndPoints.1.x, midpoint) :
                CGPointMake(midpoint, myConvertedEndPoints.1.y)))
        
        currentEdgePath = UIBezierPath()
        currentEdgePath.moveToPoint(myConvertedStartPoints.0)
        currentEdgePath.addCurveToPoint(
            myConvertedEndPoints.1,
            controlPoint1: (isVertical ?
                CGPointMake(myConvertedStartPoints.0.x, midpoint) :
                CGPointMake(midpoint, myConvertedStartPoints.0.y)),
            controlPoint2: (isVertical ?
                CGPointMake(myConvertedEndPoints.1.x, midpoint) :
                CGPointMake(midpoint, myConvertedEndPoints.1.y)))
        currentEdgePath.applyTransform(CGAffineTransformMakeTranslation(0, -self.underOffset))
        edgePaths.append(currentEdgePath)
        
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
        
        currentEdgePath = UIBezierPath()
        currentEdgePath.moveToPoint(myConvertedEndPoints.0)
        currentEdgePath.addCurveToPoint(
            myConvertedStartPoints.1,
            controlPoint1: (isVertical ?
                CGPointMake(myConvertedEndPoints.0.x, midpoint) :
                CGPointMake(midpoint, myConvertedEndPoints.0.y)),
            controlPoint2: (isVertical ?
                CGPointMake(myConvertedStartPoints.1.x, midpoint) :
                CGPointMake(midpoint, myConvertedStartPoints.1.y)))
        currentEdgePath.applyTransform(CGAffineTransformMakeTranslation(0, -self.underOffset))
        edgePaths.append(currentEdgePath)
        
        bezierPath.addLineToPoint(myConvertedStartPoints.0)
        
        bezierPath.closePath()
        bezierPath.applyTransform(CGAffineTransformMakeTranslation(0, -self.underOffset))
        
        self.fillPath = bezierPath
        self.edgePaths = edgePaths
    }

}
