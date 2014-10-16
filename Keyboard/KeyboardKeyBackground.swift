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
    
    var trackMePlz: Bool = false
    
    init(blur: Bool, cornerRadius: CGFloat, underOffset: CGFloat) {
        attached = nil
        hideDirectionIsOpposite = false
        dirty = false
        
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
    
    func generatePointsForDrawing(bounds: CGRect) {
        if self.trackMePlz {
            NSLog("generating points for \(self)")
        }
        
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
        var prevPoint: CGPoint?
        
        for i in 0..<4 {
            var edgePath: UIBezierPath?
            
            if self.attached != nil && (self.hideDirectionIsOpposite ? self.attached!.toRaw() != i : self.attached!.toRaw() == i) {
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
                    prevPoint = self.segmentPoints[i].0
                    fillPath.moveToPoint(prevPoint!)
                }

                fillPath.addLineToPoint(self.segmentPoints[i].0)
                fillPath.addLineToPoint(self.segmentPoints[i].1)
                
                edgePath!.moveToPoint(self.segmentPoints[i].0)
                edgePath!.addLineToPoint(self.segmentPoints[i].1)
                
                prevPoint = self.segmentPoints[i].1
            }
            
            let shouldDrawArcInOppositeMode = (self.attached != nil ? (self.attached!.toRaw() == i) || (self.attached!.toRaw() == ((i + 1) % 4)) : false)
            
            if (self.attached != nil && (self.hideDirectionIsOpposite ? !shouldDrawArcInOppositeMode : self.attached!.toRaw() == ((i + 1) % 4))) {
                // do nothing
            } else {
                edgePath = (edgePath == nil ? UIBezierPath() : edgePath)
                
                if prevPoint == nil {
                    prevPoint = self.segmentPoints[i].1
                    fillPath.moveToPoint(prevPoint!)
                }
                
                let startAngle = self.arcStartingAngles[(i + 1) % 4]
                let endAngle = startAngle + CGFloat(M_PI/2.0)
                
                fillPath.addLineToPoint(prevPoint!)
                fillPath.addArcWithCenter(self.arcCenters[(i + 1) % 4], radius: CGFloat(self.cornerRadius), startAngle: startAngle, endAngle: endAngle, clockwise: true)
                
                edgePath!.moveToPoint(prevPoint!)
                edgePath!.addArcWithCenter(self.arcCenters[(i + 1) % 4], radius: CGFloat(self.cornerRadius), startAngle: startAngle, endAngle: endAngle, clockwise: true)
                
                prevPoint = self.segmentPoints[(i + 1) % 4].0
            }
            
            edgePath?.applyTransform(CGAffineTransformMakeTranslation(0, -self.underOffset))
            
            if edgePath != nil { edgePaths.append(edgePath!) }
        }
        
        fillPath.closePath()
        fillPath.applyTransform(CGAffineTransformMakeTranslation(0, -self.underOffset))
        
        var underPath = { () -> UIBezierPath in
            var underPath = UIBezierPath()
            
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
