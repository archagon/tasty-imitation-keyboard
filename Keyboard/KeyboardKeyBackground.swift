//
//  KeyboardKeyBackground.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

// This class does not actually draw its contents; rather, it generates bezier curves for others to use.
// (You can still move it around, resize it, and add subviews to it. It just won't display the curve assigned to it.)
class KeyboardKeyBackground: UIView, Connectable {
    
    var fillPath: UIBezierPath?
    var underPath: UIBezierPath?
    var edgePaths: [UIBezierPath]?
    
    // do not set this manually
    var cornerRadius: CGFloat
    var underOffset: CGFloat
    
    var startingPoints: [CGPoint]
    var segmentPoints: [(CGPoint, CGPoint)]
    var arcCenters: [CGPoint]
    var arcStartingAngles: [CGFloat]
    
    var dirty: Bool

    var attached: Direction? {
        didSet {
            self.dirty = true
            self.setNeedsLayout()
        }
    }
    var hideDirectionIsOpposite: Bool {
        didSet {
            self.dirty = true
            self.setNeedsLayout()
        }
    }
    
    init(cornerRadius: CGFloat, underOffset: CGFloat) {
        attached = nil
        hideDirectionIsOpposite = false
        dirty = false
        
        startingPoints = []
        segmentPoints = []
        arcCenters = []
        arcStartingAngles = []
        
        startingPoints.reserveCapacity(4)
        segmentPoints.reserveCapacity(4)
        arcCenters.reserveCapacity(4)
        arcStartingAngles.reserveCapacity(4)
        
        for _ in 0..<4 {
            startingPoints.append(CGPointZero)
            segmentPoints.append((CGPointZero, CGPointZero))
            arcCenters.append(CGPointZero)
            arcStartingAngles.append(0)
        }
        
        self.cornerRadius = cornerRadius
        self.underOffset = underOffset
        
        super.init(frame: CGRectZero)
        
        self.userInteractionEnabled = false
    }
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var oldBounds: CGRect?
    override func layoutSubviews() {
        if !self.dirty {
            if self.bounds.width == 0 || self.bounds.height == 0 {
                return
            }
            if oldBounds != nil && CGRectEqualToRect(self.bounds, oldBounds!) {
                return
            }
        }
        oldBounds = self.bounds
        
        super.layoutSubviews()
        
        self.generatePointsForDrawing(self.bounds)
        
        self.dirty = false
    }
    
    let floatPi = CGFloat(M_PI)
    let floatPiDiv2 = CGFloat(M_PI/2.0)
    let floatPiDivNeg2 = -CGFloat(M_PI/2.0)
    
    func generatePointsForDrawing(bounds: CGRect) {
        let segmentWidth = bounds.width
        let segmentHeight = bounds.height - CGFloat(underOffset)
        
        // base, untranslated corner points
        self.startingPoints[0] = CGPointMake(0, segmentHeight)
        self.startingPoints[1] = CGPointMake(0, 0)
        self.startingPoints[2] = CGPointMake(segmentWidth, 0)
        self.startingPoints[3] = CGPointMake(segmentWidth, segmentHeight)
        
        self.arcStartingAngles[0] = floatPiDiv2
        self.arcStartingAngles[2] = floatPiDivNeg2
        self.arcStartingAngles[1] = floatPi
        self.arcStartingAngles[3] = 0
        
        //// actual coordinates for each edge, including translation
        //self.segmentPoints.removeAll(keepCapacity: true)
        //
        //// actual coordinates for arc centers for each corner
        //self.arcCenters.removeAll(keepCapacity: true)
        //
        //self.arcStartingAngles.removeAll(keepCapacity: true)
        
        for i in 0 ..< self.startingPoints.count {
            let currentPoint = self.startingPoints[i]
            let nextPoint = self.startingPoints[(i + 1) % self.startingPoints.count]
            
            var floatXCorner: CGFloat = 0
            var floatYCorner: CGFloat = 0
            
            if (i == 1) {
                floatXCorner = cornerRadius
            }
            else if (i == 3) {
                floatXCorner = -cornerRadius
            }
            
            if (i == 0) {
                floatYCorner = -cornerRadius
            }
            else if (i == 2) {
                floatYCorner = cornerRadius
            }
            
            let p0 = CGPointMake(
                currentPoint.x + (floatXCorner),
                currentPoint.y + underOffset + (floatYCorner))
            let p1 = CGPointMake(
                nextPoint.x - (floatXCorner),
                nextPoint.y + underOffset - (floatYCorner))
            
            self.segmentPoints[i] = (p0, p1)
            
            let c = CGPointMake(
                p0.x - (floatYCorner),
                p0.y + (floatXCorner))

            self.arcCenters[i] = c
        }
        
        // order of edge drawing: left edge, down edge, right edge, up edge
        
        // We need to have separate paths for all the edges so we can toggle them as needed.
        // Unfortunately, it doesn't seem possible to assemble the connected fill path
        // by simply using CGPathAddPath, since it closes all the subpaths, so we have to
        // duplicate the code a little bit.
        
        let fillPath = UIBezierPath()
        var edgePaths: [UIBezierPath] = []
        var prevPoint: CGPoint?
        
        for i in 0..<4 {
            var edgePath: UIBezierPath?
            let segmentPoint = self.segmentPoints[i]
            
            if self.attached != nil && (self.hideDirectionIsOpposite ? self.attached!.rawValue != i : self.attached!.rawValue == i) {
                // do nothing
                // TODO: quick hack
                if !self.hideDirectionIsOpposite {
                    continue
                }
            }
            else {
                edgePath = UIBezierPath()
                
                // TODO: figure out if this is ncessary
                if prevPoint == nil {
                    prevPoint = segmentPoint.0
                    fillPath.moveToPoint(prevPoint!)
                }

                fillPath.addLineToPoint(segmentPoint.0)
                fillPath.addLineToPoint(segmentPoint.1)
                
                edgePath!.moveToPoint(segmentPoint.0)
                edgePath!.addLineToPoint(segmentPoint.1)
                
                prevPoint = segmentPoint.1
            }
            
            let shouldDrawArcInOppositeMode = (self.attached != nil ? (self.attached!.rawValue == i) || (self.attached!.rawValue == ((i + 1) % 4)) : false)
            
            if (self.attached != nil && (self.hideDirectionIsOpposite ? !shouldDrawArcInOppositeMode : self.attached!.rawValue == ((i + 1) % 4))) {
                // do nothing
            } else {
                edgePath = (edgePath == nil ? UIBezierPath() : edgePath)
                
                if prevPoint == nil {
                    prevPoint = segmentPoint.1
                    fillPath.moveToPoint(prevPoint!)
                }
                
                let startAngle = self.arcStartingAngles[(i + 1) % 4]
                let endAngle = startAngle + floatPiDiv2
                let arcCenter = self.arcCenters[(i + 1) % 4]
                
                fillPath.addLineToPoint(prevPoint!)
                fillPath.addArcWithCenter(arcCenter, radius: self.cornerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                
                edgePath!.moveToPoint(prevPoint!)
                edgePath!.addArcWithCenter(arcCenter, radius: self.cornerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                
                prevPoint = self.segmentPoints[(i + 1) % 4].0
            }
            
            edgePath?.applyTransform(CGAffineTransformMakeTranslation(0, -self.underOffset))
            
            if edgePath != nil { edgePaths.append(edgePath!) }
        }
        
        fillPath.closePath()
        fillPath.applyTransform(CGAffineTransformMakeTranslation(0, -self.underOffset))
        
        let underPath = { () -> UIBezierPath in
            let underPath = UIBezierPath()
            
            underPath.moveToPoint(self.segmentPoints[2].1)
            
            var startAngle = self.arcStartingAngles[3]
            var endAngle = startAngle + CGFloat(M_PI/2.0)
            underPath.addArcWithCenter(self.arcCenters[3], radius: CGFloat(self.cornerRadius), startAngle: startAngle, endAngle: endAngle, clockwise: true)

            underPath.addLineToPoint(self.segmentPoints[3].1)
            
            startAngle = self.arcStartingAngles[0]
            endAngle = startAngle + CGFloat(M_PI/2.0)
            underPath.addArcWithCenter(self.arcCenters[0], radius: CGFloat(self.cornerRadius), startAngle: startAngle, endAngle: endAngle, clockwise: true)
            
            underPath.addLineToPoint(CGPointMake(self.segmentPoints[0].0.x, self.segmentPoints[0].0.y - self.underOffset))
            
            startAngle = self.arcStartingAngles[1]
            endAngle = startAngle - CGFloat(M_PI/2.0)
            underPath.addArcWithCenter(CGPointMake(self.arcCenters[0].x, self.arcCenters[0].y - self.underOffset), radius: CGFloat(self.cornerRadius), startAngle: startAngle, endAngle: endAngle, clockwise: false)
            
            underPath.addLineToPoint(CGPointMake(self.segmentPoints[2].1.x - self.cornerRadius, self.segmentPoints[2].1.y + self.cornerRadius - self.underOffset))
            
            startAngle = self.arcStartingAngles[0]
            endAngle = startAngle - CGFloat(M_PI/2.0)
            underPath.addArcWithCenter(CGPointMake(self.arcCenters[3].x, self.arcCenters[3].y - self.underOffset), radius: CGFloat(self.cornerRadius), startAngle: startAngle, endAngle: endAngle, clockwise: false)
            
            underPath.closePath()
            
            return underPath
        }()
        
        self.fillPath = fillPath
        self.edgePaths = edgePaths
        self.underPath = underPath
    }
    
    func attachmentPoints(direction: Direction) -> (CGPoint, CGPoint) {
        let returnValue = (
            self.segmentPoints[direction.clockwise().rawValue].0,
            self.segmentPoints[direction.counterclockwise().rawValue].1)
        
        return returnValue
    }
    
    func attachmentDirection() -> Direction? {
        return self.attached
    }
    
    func attach(direction: Direction?) {
        self.attached = direction
    }
}
