//
//  KeyboardKeyBackground.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class KeyboardKeyBackground: UIView, KeyboardView, Connectable {
    
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
    var underOffset: CGFloat { didSet { self.setNeedsDisplay() }}
    
    private var underView: UIView
    private var overView: UIView?
    private var lowerBorderView: UIView?
    private var maskLayer: CAShapeLayer
    
    private var startingPoints: [CGPoint]
    private var segmentPoints: [(CGPoint, CGPoint)]
    private var arcCenters: [CGPoint]
    private var arcStartingAngles: [CGFloat]
    private var fillPath: UIBezierPath?
    private var edgePaths: [UIBezierPath]?
    
    private var attached: Direction? { didSet { self.setNeedsDisplay() }}

    //// TODO: does this increase performance (if used correctly?)
    //override class func layerClass() -> AnyClass {
    //    return CAShapeLayer.self
    //}
    
    init(blur: Bool) {
        attached = nil
        
        startingPoints = []
        segmentPoints = []
        arcCenters = []
        arcStartingAngles = []
        
        cornerRadius = 3.0
        
        color = UIColor.whiteColor()
        underColor = UIColor.grayColor()
        borderColor = UIColor.blackColor()
        drawUnder = true
        drawOver = true
        drawBorder = false
        underOffset = 1.0
        
        underView = (blur ? UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light)) : UIView())
        maskLayer = CAShapeLayer()
        
        super.init(frame: frame)
        
        self.contentMode = UIViewContentMode.Redraw
        self.opaque = false
        self.userInteractionEnabled = false
        
        if let lowerBorderView = self.lowerBorderView { self.addSubview(lowerBorderView) }
        self.addSubview(self.underView)
        if let overView = self.overView { self.addSubview(overView) }
        
        self.underView.layer.mask = self.maskLayer
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
        
        self.lowerBorderView?.frame = self.bounds
        self.underView.frame = self.bounds
        self.overView?.frame = self.bounds
        
        self.generatePointsForDrawing()
        
        self.maskLayer.path = self.fillPath?.CGPath
    }
    
    override func drawRect(rect: CGRect) {
        if let fillPath = self.fillPath {
            if let edgePaths = self.edgePaths {
                ///////////
                // setup //
                ///////////
                
                let ctx = UIGraphicsGetCurrentContext()
                let csp = CGColorSpaceCreateDeviceRGB()
                
                ////////////////
                // draw under //
                ////////////////
                
                if self.drawUnder && self.attached != Direction.Down {
                    CGContextSaveGState(ctx)
                        // TODO: is this the right way to do this? either way, it works for now
                        CGContextTranslateCTM(ctx, 0, -CGFloat(underOffset))
                        CGContextAddPath(ctx, fillPath.CGPath)
                        CGContextTranslateCTM(ctx, 0, CGFloat(underOffset))
                        CGContextAddPath(ctx, fillPath.CGPath)
                        CGContextEOClip(ctx)
                    
                        CGContextTranslateCTM(ctx, 0, CGFloat(underOffset))
                        CGContextSetFillColorWithColor(ctx, self.underColor.CGColor)
                        CGContextAddPath(ctx, fillPath.CGPath)
                        CGContextFillPath(ctx)
                    CGContextRestoreGState(ctx)
                }
                
                ///////////////
                // draw over //
                ///////////////
                
                // TODO: border stroke outside, not inside
                CGContextTranslateCTM(ctx, 0, -CGFloat(underOffset))
                CGContextSaveGState(ctx)
                    if self.drawOver {
                        // if we don't clip this draw call, the border will look messed up on account of exceeding the view bounds
                        // TODO: OverflowCanvas
                        CGContextAddPath(ctx, fillPath.CGPath)
                        CGContextClip(ctx)
                        
                        CGContextSetFillColorWithColor(ctx, self.color.CGColor)
                        CGContextSetStrokeColorWithColor(ctx, self.borderColor.CGColor)
                        CGContextSetLineWidth(ctx, 1)
                        CGContextAddPath(ctx, fillPath.CGPath)
                        CGContextFillPath(ctx)
                    }
                
                    if self.drawBorder {
                        for path in edgePaths {
                            CGContextAddPath(ctx, path.CGPath)
                            CGContextStrokePath(ctx)
                        }
                    }
                CGContextRestoreGState(ctx)
                CGContextTranslateCTM(ctx, 0, CGFloat(underOffset))
            }
            else {
                return
            }
        }
        else {
            return
        }
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
        
        // order of edge drawing: left edge, down edge, right edge, up edge
        
        // We need to have separate paths for all the edges so we can toggle them as needed.
        // Unfortunately, it doesn't seem possible to assemble the connected fill path
        // by simply using CGPathAddPath, since it closes all the subpaths, so we have to
        // duplicate the code a little bit.
        
        var fillPath = UIBezierPath()
        var edgePaths: [UIBezierPath] = []
        var firstEdge = false
        
        for i in 0..<4 {
            if self.attached != nil && self.attached!.toRaw() == i {
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
            
            if (self.attached != nil && self.attached!.toRaw() == ((i + 1) % 4)) {
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
