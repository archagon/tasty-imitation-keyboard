//
//  KeyboardKeyBackground.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class KeyboardKeyBackground: UIView, KeyboardView, Connectable {
    
    var underOffset: Double { didSet { self.setNeedsDisplay() }}
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
    var drawOver: Bool { didSet { self.setNeedsDisplay() }}
    var drawBorder: Bool { didSet { self.setNeedsDisplay() }}
    
    private var startingPoints: [CGPoint]
    private var segmentPoints: [(CGPoint, CGPoint)]
    private var arcCenters: [CGPoint]
    private var arcStartingAngles: [CGFloat]
    
    private var attached: Direction? { didSet { self.setNeedsDisplay() }}

    //// TODO: does this increase performance (if used correctly?)
    //override class func layerClass() -> AnyClass {
    //    return CAShapeLayer.self
    //}
    
    override init(frame: CGRect) {
        attached = nil
        
        startingPoints = []
        segmentPoints = []
        arcCenters = []
        arcStartingAngles = []
        
        underOffset = 1.0
        cornerRadius = 3.0
        
        color = UIColor.whiteColor()
        underColor = UIColor.grayColor()
        borderColor = UIColor.blackColor()
        drawUnder = true
        drawOver = true
        drawBorder = false
        
        super.init(frame: frame)
        
        self.contentMode = UIViewContentMode.Redraw
        self.opaque = false
        self.userInteractionEnabled = false
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        generatePointsForDrawing()
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
            if self.attached != nil && self.attached!.toRaw() == i {
                continue
            }
            
            var edgePath = CGPathCreateMutable()
            
            CGPathMoveToPoint(edgePath, nil, self.segmentPoints[i].0.x, self.segmentPoints[i].0.y)
            CGPathAddLineToPoint(edgePath, nil, self.segmentPoints[i].1.x, self.segmentPoints[i].1.y)
            
            // TODO: figure out if this is ncessary
            if !firstEdge {
                CGPathMoveToPoint(fillPath, nil, self.segmentPoints[i].0.x, self.segmentPoints[i].0.y)
                firstEdge = true
            }
            else {
                CGPathAddLineToPoint(fillPath, nil, self.segmentPoints[i].0.x, self.segmentPoints[i].0.y)
            }
            CGPathAddLineToPoint(fillPath, nil, self.segmentPoints[i].1.x, self.segmentPoints[i].1.y)
            
            if (self.attached != nil && self.attached!.toRaw() == ((i + 1) % 4)) {
                // do nothing
            } else {
                CGPathAddRelativeArc(edgePath, nil, self.arcCenters[(i + 1) % 4].x, self.arcCenters[(i + 1) % 4].y, CGFloat(self.cornerRadius), self.arcStartingAngles[(i + 1) % 4], CGFloat(M_PI/2.0))
                CGPathAddRelativeArc(fillPath, nil, self.arcCenters[(i + 1) % 4].x, self.arcCenters[(i + 1) % 4].y, CGFloat(self.cornerRadius), self.arcStartingAngles[(i + 1) % 4], CGFloat(M_PI/2.0))
            }
            
            edgePaths.append(edgePath)
        }
        
        if self.drawUnder && self.attached != Direction.Down {
            CGContextSaveGState(ctx)
                // TODO: is this the right way to do this? either way, it works for now
                CGContextTranslateCTM(ctx, 0, -CGFloat(underOffset))
                CGContextAddPath(ctx, fillPath)
                CGContextTranslateCTM(ctx, 0, CGFloat(underOffset))
                CGContextAddPath(ctx, fillPath)
                CGContextEOClip(ctx)
            
                CGContextTranslateCTM(ctx, 0, CGFloat(underOffset))
                CGContextSetFillColorWithColor(ctx, self.underColor.CGColor)
                CGContextAddPath(ctx, fillPath)
                CGContextFillPath(ctx)
            CGContextRestoreGState(ctx)
        }
        
        // TODO: border stroke outside, not inside
        CGContextTranslateCTM(ctx, 0, -CGFloat(underOffset))
        CGContextSaveGState(ctx)
            if self.drawOver {
                // if we don't clip this draw call, the border will look messed up on account of exceeding the view bounds
                // TODO: OverflowCanvas
                CGContextAddPath(ctx, fillPath)
                CGContextClip(ctx)
                
                CGContextSetFillColorWithColor(ctx, self.color.CGColor)
                CGContextSetStrokeColorWithColor(ctx, self.borderColor.CGColor)
                CGContextSetLineWidth(ctx, 1)
                CGContextAddPath(ctx, fillPath)
                CGContextFillPath(ctx)
            }
        
            if self.drawBorder {
                for path in edgePaths {
                    CGContextAddPath(ctx, path)
                    CGContextStrokePath(ctx)
                }
            }
        CGContextRestoreGState(ctx)
        CGContextTranslateCTM(ctx, 0, CGFloat(underOffset))
    }
    
    func generatePointsForDrawing() {
        let segmentWidth = self.bounds.width
        let segmentHeight = self.bounds.height - CGFloat(underOffset)
        
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
                currentPoint.x + CGFloat(xDir * cornerRadius),
                currentPoint.y + CGFloat(underOffset) + CGFloat(yDir * cornerRadius))
            let p1 = CGPointMake(
                nextPoint.x - CGFloat(xDir * cornerRadius),
                nextPoint.y + CGFloat(underOffset) - CGFloat(yDir * cornerRadius))
            
            self.segmentPoints.append((p0, p1))
            
            let c = CGPointMake(
                p0.x - CGFloat(yDir * cornerRadius),
                p0.y + CGFloat(xDir * cornerRadius))
            
            self.arcCenters.append(c)
        }
    }
    
    func attachmentPoints(direction: Direction) -> (CGPoint, CGPoint) {
        var returnValue = (
            self.segmentPoints[direction.clockwise().toRaw()].0,
            self.segmentPoints[direction.counterclockwise().toRaw()].1)
        
        // TODO: quick hack
        returnValue.0.y -= CGFloat(self.underOffset)
        returnValue.1.y -= CGFloat(self.underOffset)
        
        return returnValue
    }
    
    func attachmentDirection() -> Direction? {
        return self.attached
    }
    
    func attach(direction: Direction?) {
        self.attached = direction
    }
}
