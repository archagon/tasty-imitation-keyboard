//
//  Shapes.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/5/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

///////////////////
// SHAPE OBJECTS //
///////////////////

class Shape: UIView {
    // in case shapes draw out of bounds, we still want them to show
    var overflowCanvas: OverflowCanvas!
    
    convenience override init() {
        self.init(frame: CGRectZero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.opaque = false
        self.clipsToBounds = false
        
        self.overflowCanvas = OverflowCanvas(shape: self)
        self.addSubview(self.overflowCanvas)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let overflowCanvasSizeRatio = CGFloat(1.25)
        let overflowCanvasSize = CGSizeMake(self.bounds.width * overflowCanvasSizeRatio, self.bounds.height * overflowCanvasSizeRatio)
        
        self.overflowCanvas.frame = CGRectMake(
            CGFloat((self.bounds.width - overflowCanvasSize.width) / 2.0),
            CGFloat((self.bounds.height - overflowCanvasSize.height) / 2.0),
            overflowCanvasSize.width,
            overflowCanvasSize.height)
        self.overflowCanvas.setNeedsDisplay()
    }
    
    func drawCall() { /* override me! */ }
    
    class OverflowCanvas: UIView {
        // TODO: retain cycle? does swift even have those?
        var shape: Shape
        
        init(shape: Shape) {
            self.shape = shape
            
            super.init(frame: CGRectZero)
            
            self.opaque = false
        }

        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func drawRect(rect: CGRect) {
            let ctx = UIGraphicsGetCurrentContext()
            let csp = CGColorSpaceCreateDeviceRGB()
            
            CGContextSaveGState(ctx)
            
            let xOffset = (self.bounds.width - self.shape.bounds.width) / CGFloat(2)
            let yOffset = (self.bounds.height - self.shape.bounds.height) / CGFloat(2)
            CGContextTranslateCTM(ctx, xOffset, yOffset)
            
            self.shape.drawCall()
            
            CGContextRestoreGState(ctx)
        }
    }
}

class BackspaceShape: Shape {
    override func drawCall() {
        drawBackspace(self.bounds, UIColor.redColor())
    }
}

class ShiftShape: Shape {
    var withLock: Bool = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func drawCall() {
        drawShift(self.bounds, UIColor.redColor(), self.withLock)
    }
}

class GlobeShape: Shape {
    override func drawCall() {
        drawGlobe(self.bounds, UIColor.redColor())
    }
}

/////////////////////
// SHAPE FUNCTIONS //
/////////////////////

func getFactors(fromSize: CGSize, toSize: CGSize) -> (xScalingFactor: CGFloat, yScalingFactor: CGFloat, lineWidthScalingFactor: CGFloat, fillIsHorizontal: Bool, offset: CGFloat) {
    let highestX = fromSize.width
    let highestY = fromSize.height
    var xScalingFactor = (CGFloat(1.0) / highestX) * toSize.width
    var yScalingFactor = (CGFloat(1.0) / highestY) * toSize.height
    
    let ratio = highestX / highestY
    let canvasRatio = toSize.width / toSize.height
    let fullHorizontal: Bool = (ratio > canvasRatio)
    
    var lineWidthScalingFactor: CGFloat!
    var offset: CGFloat!
    
    if fullHorizontal {
        yScalingFactor = (CGFloat(1.0) / highestY) * (toSize.height * (CGFloat(1) / ratio))
        
        let newY = highestY * yScalingFactor
        offset = (toSize.height - newY) / CGFloat(2)
        
        lineWidthScalingFactor = toSize.width / highestX
    }
    else {
        xScalingFactor = (CGFloat(1.0) / highestX) * (toSize.width * ratio)
        
        let newX = highestX * xScalingFactor
        offset = (toSize.width - newX) / CGFloat(2)
        
        lineWidthScalingFactor = toSize.height / highestY
    }
    
    return (xScalingFactor, yScalingFactor, lineWidthScalingFactor, fullHorizontal, offset)
}

func drawBackspace(bounds: CGRect, color: UIColor) {
    let factors = getFactors(CGSizeMake(43.5, 31.5), bounds.size)
    let xScalingFactor = factors.xScalingFactor
    let yScalingFactor = factors.yScalingFactor
    let lineWidthScalingFactor = factors.lineWidthScalingFactor
    
    let ctx = UIGraphicsGetCurrentContext()
    CGContextSaveGState(ctx)
    CGContextTranslateCTM(ctx, (factors.fillIsHorizontal ? 0 : factors.offset), (factors.fillIsHorizontal ? factors.offset : 0))
    
    //// PaintCode Trial Version
    //// www.paintcodeapp.com
    
    //// Color Declarations
    let color = color
    let color2 = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000) // TODO:
    
    //// Bezier Drawing
    var bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPointMake(16.19 * xScalingFactor, 31.5 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(37.7 * xScalingFactor, 31.5 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(43.5 * xScalingFactor, 26.5 * yScalingFactor), controlPoint1: CGPointMake(37.7 * xScalingFactor, 31.5 * yScalingFactor), controlPoint2: CGPointMake(43.5 * xScalingFactor, 31.5 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(43.5 * xScalingFactor, 5.5 * yScalingFactor), controlPoint1: CGPointMake(43.5 * xScalingFactor, 21.5 * yScalingFactor), controlPoint2: CGPointMake(43.5 * xScalingFactor, 5.5 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(37.43 * xScalingFactor, 0.5 * yScalingFactor), controlPoint1: CGPointMake(43.5 * xScalingFactor, 5.5 * yScalingFactor), controlPoint2: CGPointMake(43.5 * xScalingFactor, 0.5 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(16.19 * xScalingFactor, 0.5 * yScalingFactor), controlPoint1: CGPointMake(31.36 * xScalingFactor, 0.5 * yScalingFactor), controlPoint2: CGPointMake(16.19 * xScalingFactor, 0.5 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(0 * xScalingFactor, 16.5 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(16.19 * xScalingFactor, 31.5 * yScalingFactor))
    bezierPath.closePath()
    color.setFill()
    bezierPath.fill()
    
    
    //// Bezier 2 Drawing
    var bezier2Path = UIBezierPath()
    bezier2Path.moveToPoint(CGPointMake(20 * xScalingFactor, 9 * yScalingFactor))
    bezier2Path.addLineToPoint(CGPointMake(34 * xScalingFactor, 23 * yScalingFactor))
    bezier2Path.addLineToPoint(CGPointMake(20 * xScalingFactor, 9 * yScalingFactor))
    bezier2Path.closePath()
    UIColor.grayColor().setFill()
    bezier2Path.fill()
    color2.setStroke()
    bezier2Path.lineWidth = 2.5 * lineWidthScalingFactor
    bezier2Path.stroke()
    
    
    //// Bezier 3 Drawing
    var bezier3Path = UIBezierPath()
    bezier3Path.moveToPoint(CGPointMake(20 * xScalingFactor, 23 * yScalingFactor))
    bezier3Path.addLineToPoint(CGPointMake(34 * xScalingFactor, 9 * yScalingFactor))
    bezier3Path.addLineToPoint(CGPointMake(20 * xScalingFactor, 23 * yScalingFactor))
    bezier3Path.closePath()
    UIColor.redColor().setFill()
    bezier3Path.fill()
    color2.setStroke()
    bezier3Path.lineWidth = 2.5 * lineWidthScalingFactor
    bezier3Path.stroke()
    
    CGContextRestoreGState(ctx)
}

func drawShift(bounds: CGRect, color: UIColor, withRect: Bool) {
    let factors = getFactors(CGSizeMake(37, (withRect ? 34.5 + 4 : 31.5)), bounds.size)
    let xScalingFactor = factors.xScalingFactor
    let yScalingFactor = factors.yScalingFactor
    let lineWidthScalingFactor = factors.lineWidthScalingFactor
    
    let ctx = UIGraphicsGetCurrentContext()
    CGContextSaveGState(ctx)
    CGContextTranslateCTM(ctx, (factors.fillIsHorizontal ? 0 : factors.offset), (factors.fillIsHorizontal ? factors.offset : 0))
    
    //// PaintCode Trial Version
    //// www.paintcodeapp.com
    
    //// Color Declarations
    let color2 = color
    
    //// Bezier Drawing
    var bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPointMake(28 * xScalingFactor, 18.7 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(37 * xScalingFactor, 18.7 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(37 * xScalingFactor, 17.72 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(18.5 * xScalingFactor, 0 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(0 * xScalingFactor, 17.72 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(0 * xScalingFactor, 18.7 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(9 * xScalingFactor, 18.7 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(9 * xScalingFactor, 28.55 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(12 * xScalingFactor, 31.5 * yScalingFactor), controlPoint1: CGPointMake(9 * xScalingFactor, 28.55 * yScalingFactor), controlPoint2: CGPointMake(9 * xScalingFactor, 31.5 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(24 * xScalingFactor, 31.5 * yScalingFactor), controlPoint1: CGPointMake(15 * xScalingFactor, 31.5 * yScalingFactor), controlPoint2: CGPointMake(24 * xScalingFactor, 31.5 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(28 * xScalingFactor, 28.55 * yScalingFactor), controlPoint1: CGPointMake(24 * xScalingFactor, 31.5 * yScalingFactor), controlPoint2: CGPointMake(28 * xScalingFactor, 31.5 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(28 * xScalingFactor, 18.7 * yScalingFactor), controlPoint1: CGPointMake(28 * xScalingFactor, 25.59 * yScalingFactor), controlPoint2: CGPointMake(28 * xScalingFactor, 18.7 * yScalingFactor))
    bezierPath.closePath()
    color2.setFill()
    bezierPath.fill()
    
    
    if withRect {
        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRectMake(9.5 * xScalingFactor, 34.5 * yScalingFactor, 18.5 * xScalingFactor, 4 * yScalingFactor))
        color2.setFill()
        rectanglePath.fill()
    }
    
    CGContextRestoreGState(ctx)
}

func drawGlobe(bounds: CGRect, color: UIColor) {
    let factors = getFactors(CGSizeMake(41, 40), bounds.size)
    let xScalingFactor = factors.xScalingFactor
    let yScalingFactor = factors.yScalingFactor
    let lineWidthScalingFactor = factors.lineWidthScalingFactor
    
    let ctx = UIGraphicsGetCurrentContext()
    CGContextSaveGState(ctx)
    CGContextTranslateCTM(ctx, (factors.fillIsHorizontal ? 0 : factors.offset), (factors.fillIsHorizontal ? factors.offset : 0))
    
    //// PaintCode Trial Version
    //// www.paintcodeapp.com
    
    //// Color Declarations
    let color = color
    
    //// Oval Drawing
    var ovalPath = UIBezierPath(ovalInRect: CGRectMake(0 * xScalingFactor, 0 * yScalingFactor, 40 * xScalingFactor, 40 * yScalingFactor))
    color.setStroke()
    ovalPath.lineWidth = 2.5 * lineWidthScalingFactor
    ovalPath.stroke()
    
    
    //// Bezier Drawing
    var bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPointMake(20 * xScalingFactor, -0 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(20 * xScalingFactor, 40 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(20 * xScalingFactor, -0 * yScalingFactor))
    bezierPath.closePath()
    color.setStroke()
    bezierPath.lineWidth = 2 * lineWidthScalingFactor
    bezierPath.stroke()
    
    
    //// Bezier 2 Drawing
    var bezier2Path = UIBezierPath()
    bezier2Path.moveToPoint(CGPointMake(0.5 * xScalingFactor, 19.5 * yScalingFactor))
    bezier2Path.addLineToPoint(CGPointMake(39.5 * xScalingFactor, 19.5 * yScalingFactor))
    bezier2Path.addLineToPoint(CGPointMake(0.5 * xScalingFactor, 19.5 * yScalingFactor))
    bezier2Path.closePath()
    color.setStroke()
    bezier2Path.lineWidth = 2 * lineWidthScalingFactor
    bezier2Path.stroke()
    
    
    //// Bezier 3 Drawing
    var bezier3Path = UIBezierPath()
    bezier3Path.moveToPoint(CGPointMake(21.63 * xScalingFactor, 0.42 * yScalingFactor))
    bezier3Path.addCurveToPoint(CGPointMake(21.63 * xScalingFactor, 39.6 * yScalingFactor), controlPoint1: CGPointMake(21.63 * xScalingFactor, 0.42 * yScalingFactor), controlPoint2: CGPointMake(41 * xScalingFactor, 19 * yScalingFactor))
    bezier3Path.lineCapStyle = kCGLineCapRound;
    
    color.setStroke()
    bezier3Path.lineWidth = 2 * lineWidthScalingFactor
    bezier3Path.stroke()
    
    
    //// Bezier 4 Drawing
    var bezier4Path = UIBezierPath()
    bezier4Path.moveToPoint(CGPointMake(17.76 * xScalingFactor, 0.74 * yScalingFactor))
    bezier4Path.addCurveToPoint(CGPointMake(18.72 * xScalingFactor, 39.6 * yScalingFactor), controlPoint1: CGPointMake(17.76 * xScalingFactor, 0.74 * yScalingFactor), controlPoint2: CGPointMake(-2.5 * xScalingFactor, 19.04 * yScalingFactor))
    bezier4Path.lineCapStyle = kCGLineCapRound;
    
    color.setStroke()
    bezier4Path.lineWidth = 2 * lineWidthScalingFactor
    bezier4Path.stroke()
    
    
    //// Bezier 5 Drawing
    var bezier5Path = UIBezierPath()
    bezier5Path.moveToPoint(CGPointMake(6 * xScalingFactor, 7 * yScalingFactor))
    bezier5Path.addCurveToPoint(CGPointMake(34 * xScalingFactor, 7 * yScalingFactor), controlPoint1: CGPointMake(6 * xScalingFactor, 7 * yScalingFactor), controlPoint2: CGPointMake(19 * xScalingFactor, 21 * yScalingFactor))
    bezier5Path.lineCapStyle = kCGLineCapRound;
    
    color.setStroke()
    bezier5Path.lineWidth = 2 * lineWidthScalingFactor
    bezier5Path.stroke()
    
    
    //// Bezier 6 Drawing
    var bezier6Path = UIBezierPath()
    bezier6Path.moveToPoint(CGPointMake(6 * xScalingFactor, 33 * yScalingFactor))
    bezier6Path.addCurveToPoint(CGPointMake(34 * xScalingFactor, 33 * yScalingFactor), controlPoint1: CGPointMake(6 * xScalingFactor, 33 * yScalingFactor), controlPoint2: CGPointMake(19 * xScalingFactor, 22 * yScalingFactor))
    bezier6Path.lineCapStyle = kCGLineCapRound;
    
    color.setStroke()
    bezier6Path.lineWidth = 2.5 * lineWidthScalingFactor
    bezier6Path.stroke()
    
    CGContextRestoreGState(ctx)
}
