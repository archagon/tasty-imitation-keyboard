//
//  KeyboardKeyBackground.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// This class does not actually draw its contents; rather, it generates bezier curves for others to use.
// (You can still move it around, resize it, and add subviews to it. It just won't display the curve assigned to it.)
class KeyboardKeyBackground: UIView, Connectable {
    
    var fillPath: UIBezierPath?
    var edgePaths: [UIBezierPath]?
    
    // do not set this manually
    var cornerRadius: CGFloat
    var underOffset: CGFloat
    
    var startingPoints: [CGPoint]
    var segmentPoints: [(CGPoint, CGPoint)]
    var arcCenters: [CGPoint]
    var arcStartingAngles: [CGFloat]
    
    var attached: Direction? {
        didSet {
            self.generatePointsForDrawing(self.bounds)
            self.setNeedsDisplay()
        }
    }
    var hideDirectionIsOpposite: Bool {
        didSet {
            self.generatePointsForDrawing(self.bounds)
            self.setNeedsDisplay()
        }
    }
    
    init(blur: Bool, cornerRadius: CGFloat, underOffset: CGFloat) {
        attached = nil
        hideDirectionIsOpposite = false
        
        startingPoints = []
        segmentPoints = []
        arcCenters = []
        arcStartingAngles = []
        
        self.cornerRadius = cornerRadius
        self.underOffset = underOffset
        
        super.init(frame: frame)
        
        self.userInteractionEnabled = false
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    var oldBounds: CGRect?
    override func layoutSubviews() {
        if self.bounds.width == 0 || self.bounds.height == 0 {
            return
        }
        if oldBounds != nil && CGRectEqualToRect(self.bounds, oldBounds!) {
            return
        }
        oldBounds = self.bounds
        
        super.layoutSubviews()
        
        self.generatePointsForDrawing(self.bounds)
    }
    
    func generatePointsForDrawing(bounds: CGRect) {
        let segmentWidth = bounds.width
        let segmentHeight = bounds.height - CGFloat(underOffset)
        
        // base, untranslated corner points
        self.startingPoints = [
            CGPointMake(0, segmentHeight),
            CGPointMake(0, 0),
            CGPointMake(segmentWidth, 0),
            CGPointMake(segmentWidth, segmentHeight),
        ]
        
        // actual coordinates for each edge, including translation
        self.segmentPoints = [] // TODO: is this declaration correct?
        
        // actual coordinates for arc centers for each corner
        self.arcCenters = []
        
        self.arcStartingAngles = []
        
        for i in 0 ..< self.startingPoints.count {
            let currentPoint = self.startingPoints[i]
            let nextPoint = self.startingPoints[(i + 1) % self.startingPoints.count]
            
            var xDir = 0.0
            var yDir = 0.0
            
            if (i == 1) {
                xDir = 1.0
                self.arcStartingAngles.append(CGFloat(M_PI))
            }
            else if (i == 3) {
                xDir = -1.0
                self.arcStartingAngles.append(CGFloat(0))
            }
            
            if (i == 0) {
                yDir = -1.0
                self.arcStartingAngles.append(CGFloat(M_PI/2.0))
            }
            else if (i == 2) {
                yDir = 1.0
                self.arcStartingAngles.append(CGFloat(-M_PI/2.0))
            }
            
            let p0 = CGPointMake(
                currentPoint.x + (CGFloat(xDir) * cornerRadius),
                currentPoint.y + CGFloat(underOffset) + (CGFloat(yDir) * cornerRadius))
            let p1 = CGPointMake(
                nextPoint.x - (CGFloat(xDir) * cornerRadius),
                nextPoint.y + CGFloat(underOffset) - (CGFloat(yDir) * cornerRadius))
            
            self.segmentPoints.append((p0, p1))
            
            let c = CGPointMake(
                p0.x - (CGFloat(yDir) * cornerRadius),
                p0.y + (CGFloat(xDir) * cornerRadius))
            
            self.arcCenters.append(c)
        }
        
        // order of edge drawing: left edge, down edge, right edge, up edge
        
        // We need to have separate paths for all the edges so we can toggle them as needed.
        // Unfortunately, it doesn't seem possible to assemble the connected fill path
        // by simply using CGPathAddPath, since it closes all the subpaths, so we have to
        // duplicate the code a little bit.
        
        var fillPath = UIBezierPath()
        var edgePaths: [UIBezierPath] = []
        var firstEdge = false
        
        for i in 0..<4 {
            if self.attached != nil && (self.hideDirectionIsOpposite ? self.attached!.toRaw() != i : self.attached!.toRaw() == i) {
                continue
            }
            
            var edgePath = UIBezierPath()
            
            edgePath.moveToPoint(self.segmentPoints[i].0)
            edgePath.addLineToPoint(self.segmentPoints[i].1)
            
            // TODO: figure out if this is ncessary
            if !firstEdge {
                fillPath.moveToPoint(self.segmentPoints[i].0)
                firstEdge = true
            }
            else {
                fillPath.addLineToPoint(self.segmentPoints[i].0)
            }
            fillPath.addLineToPoint(self.segmentPoints[i].1)
            
            if (self.attached != nil && (self.hideDirectionIsOpposite ? self.attached!.toRaw() != ((i + 1) % 4) : self.attached!.toRaw() == ((i + 1) % 4))) {
                // do nothing
            } else {
                let startAngle = self.arcStartingAngles[(i + 1) % 4]
                let endAngle = startAngle + CGFloat(M_PI/2.0)
                edgePath.addArcWithCenter(self.arcCenters[(i + 1) % 4], radius: CGFloat(self.cornerRadius), startAngle: startAngle, endAngle: endAngle, clockwise: true)
                fillPath.addArcWithCenter(self.arcCenters[(i + 1) % 4], radius: CGFloat(self.cornerRadius), startAngle: startAngle, endAngle: endAngle, clockwise: true)
            }
            
            edgePaths.append(edgePath)
        }
        
        self.fillPath = fillPath
        self.edgePaths = edgePaths
    }
    
    func attachmentPoints(direction: Direction) -> (CGPoint, CGPoint) {
        var returnValue = (
            self.segmentPoints[direction.clockwise().toRaw()].0,
            self.segmentPoints[direction.counterclockwise().toRaw()].1)
        
        // TODO: quick hack
        //returnValue.0.y -= CGFloat(self.underOffset)
        //returnValue.1.y -= CGFloat(self.underOffset)
        
        return returnValue
    }
    
    func attachmentDirection() -> Direction? {
        return self.attached
    }
    
    func attach(direction: Direction?) {
        self.attached = direction
    }
}
