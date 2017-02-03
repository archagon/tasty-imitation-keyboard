//
//  KeyboardConnector.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

protocol Connectable: class {
    func attachmentPoints(_ direction: Direction) -> (CGPoint, CGPoint)
    func attachmentDirection() -> Direction?
    func attach(_ direction: Direction?) // call with nil to detach
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

        offset = CGPoint.zero

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
                superview.convert(startPoints.0, from: self.start),
                superview.convert(startPoints.1, from: self.start))
            self.convertedEndPoints = (
                superview.convert(endPoints.0, from: self.end),
                superview.convert(endPoints.1, from: self.end))
        }
    }

    func resizeFrame() {
        generateConvertedPoints()

        let buffer: CGFloat = 32
        self.offset = CGPoint(x: buffer/2, y: buffer/2)

        let minX = min(convertedStartPoints.0.x, convertedStartPoints.1.x, convertedEndPoints.0.x, convertedEndPoints.1.x)
        let minY = min(convertedStartPoints.0.y, convertedStartPoints.1.y, convertedEndPoints.0.y, convertedEndPoints.1.y)
        let maxX = max(convertedStartPoints.0.x, convertedStartPoints.1.x, convertedEndPoints.0.x, convertedEndPoints.1.x)
        let maxY = max(convertedStartPoints.0.y, convertedStartPoints.1.y, convertedEndPoints.0.y, convertedEndPoints.1.y)
        let width = maxX - minX
        let height = maxY - minY
        
        self.frame = CGRect(x: minX - buffer/2, y: minY - buffer/2, width: width + buffer, height: height + buffer)
    }
    
    override func generatePointsForDrawing(_ bounds: CGRect) {
        if self.startConnectable == nil || self.endConnectable == nil {
            return
        }
        
        //////////////////
        // prepare data //
        //////////////////

        let startPoints = self.startConnectable!.attachmentPoints(self.startDir)
        let endPoints = self.endConnectable!.attachmentPoints(self.endDir)

        var myConvertedStartPoints = (
            self.convert(startPoints.0, from: self.start),
            self.convert(startPoints.1, from: self.start))
        let myConvertedEndPoints = (
            self.convert(endPoints.0, from: self.end),
            self.convert(endPoints.1, from: self.end))

        if self.startDir == self.endDir {
            let tempPoint = myConvertedStartPoints.0
            myConvertedStartPoints.0 = myConvertedStartPoints.1
            myConvertedStartPoints.1 = tempPoint
        }

        let path = CGMutablePath();
        path.move(to: myConvertedStartPoints.0)
        path.addLine(to: myConvertedEndPoints.1)
        path.addLine(to: myConvertedEndPoints.0)
        path.addLine(to: myConvertedStartPoints.1)
        path.closeSubpath()

        // for now, assuming axis-aligned attachment points

        let isVertical = (self.startDir == Direction.up || self.startDir == Direction.down) && (self.endDir == Direction.up || self.endDir == Direction.down)

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
        
        bezierPath.move(to: myConvertedStartPoints.0)
        
        bezierPath.addCurve(
            to: myConvertedEndPoints.1,
            controlPoint1: (isVertical ?
                CGPoint(x: myConvertedStartPoints.0.x, y: midpoint) :
                CGPoint(x: midpoint, y: myConvertedStartPoints.0.y)),
            controlPoint2: (isVertical ?
                CGPoint(x: myConvertedEndPoints.1.x, y: midpoint) :
                CGPoint(x: midpoint, y: myConvertedEndPoints.1.y)))
        
        currentEdgePath = UIBezierPath()
        currentEdgePath.move(to: myConvertedStartPoints.0)
        currentEdgePath.addCurve(
            to: myConvertedEndPoints.1,
            controlPoint1: (isVertical ?
                CGPoint(x: myConvertedStartPoints.0.x, y: midpoint) :
                CGPoint(x: midpoint, y: myConvertedStartPoints.0.y)),
            controlPoint2: (isVertical ?
                CGPoint(x: myConvertedEndPoints.1.x, y: midpoint) :
                CGPoint(x: midpoint, y: myConvertedEndPoints.1.y)))
        currentEdgePath.apply(CGAffineTransform(translationX: 0, y: -self.underOffset))
        edgePaths.append(currentEdgePath)
        
        bezierPath.addLine(to: myConvertedEndPoints.0)
        
        bezierPath.addCurve(
            to: myConvertedStartPoints.1,
            controlPoint1: (isVertical ?
                CGPoint(x: myConvertedEndPoints.0.x, y: midpoint) :
                CGPoint(x: midpoint, y: myConvertedEndPoints.0.y)),
            controlPoint2: (isVertical ?
                CGPoint(x: myConvertedStartPoints.1.x, y: midpoint) :
                CGPoint(x: midpoint, y: myConvertedStartPoints.1.y)))
        bezierPath.addLine(to: myConvertedStartPoints.0)
        
        currentEdgePath = UIBezierPath()
        currentEdgePath.move(to: myConvertedEndPoints.0)
        currentEdgePath.addCurve(
            to: myConvertedStartPoints.1,
            controlPoint1: (isVertical ?
                CGPoint(x: myConvertedEndPoints.0.x, y: midpoint) :
                CGPoint(x: midpoint, y: myConvertedEndPoints.0.y)),
            controlPoint2: (isVertical ?
                CGPoint(x: myConvertedStartPoints.1.x, y: midpoint) :
                CGPoint(x: midpoint, y: myConvertedStartPoints.1.y)))
        currentEdgePath.apply(CGAffineTransform(translationX: 0, y: -self.underOffset))
        edgePaths.append(currentEdgePath)
        
        bezierPath.addLine(to: myConvertedStartPoints.0)
        
        bezierPath.close()
        bezierPath.apply(CGAffineTransform(translationX: 0, y: -self.underOffset))
        
        self.fillPath = bezierPath
        self.edgePaths = edgePaths
    }

}
