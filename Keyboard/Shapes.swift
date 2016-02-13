//
//  Shapes.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/5/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

// TODO: these shapes were traced and as such are erratic and inaccurate; should redo as SVG or PDF

///////////////////
// SHAPE OBJECTS //
///////////////////

class BackspaceShape: Shape {
    override func drawCall(color: UIColor) {
        drawBackspace(self.bounds, color: color)
    }
}

class ShiftShape: Shape {
    var withLock: Bool = false {
        didSet {
            self.overflowCanvas.setNeedsDisplay()
        }
    }
    
    override func drawCall(color: UIColor) {
        drawShift(self.bounds, color: color, withRect: self.withLock)
    }
}

class GlobeShape: Shape {
    override func drawCall(color: UIColor) {
        drawGlobe(self.bounds, color: color)
    }
}

class Shape: UIView {
    var color: UIColor? {
        didSet {
            if let _ = self.color {
                self.overflowCanvas.setNeedsDisplay()
            }
        }
    }
    
    // in case shapes draw out of bounds, we still want them to show
    var overflowCanvas: OverflowCanvas!
    
    convenience init() {
        self.init(frame: CGRectZero)
    }
    
    override required init(frame: CGRect) {
        super.init(frame: frame)
        
        self.opaque = false
        self.clipsToBounds = false
        
        self.overflowCanvas = OverflowCanvas(shape: self)
        self.addSubview(self.overflowCanvas)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        let overflowCanvasSizeRatio = CGFloat(1.25)
        let overflowCanvasSize = CGSizeMake(self.bounds.width * overflowCanvasSizeRatio, self.bounds.height * overflowCanvasSizeRatio)
        
        self.overflowCanvas.frame = CGRectMake(
            CGFloat((self.bounds.width - overflowCanvasSize.width) / 2.0),
            CGFloat((self.bounds.height - overflowCanvasSize.height) / 2.0),
            overflowCanvasSize.width,
            overflowCanvasSize.height)
        self.overflowCanvas.setNeedsDisplay()
    }
    
    func drawCall(color: UIColor) { /* override me! */ }
    
    class OverflowCanvas: UIView {
        unowned var shape: Shape
        
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
            CGColorSpaceCreateDeviceRGB()
            
            CGContextSaveGState(ctx)
            
            let xOffset = (self.bounds.width - self.shape.bounds.width) / CGFloat(2)
            let yOffset = (self.bounds.height - self.shape.bounds.height) / CGFloat(2)
            CGContextTranslateCTM(ctx, xOffset, yOffset)
            
            self.shape.drawCall(shape.color != nil ? shape.color! : UIColor.blackColor())
            
            CGContextRestoreGState(ctx)
        }
    }
}

/////////////////////
// SHAPE FUNCTIONS //
/////////////////////

func getFactors(fromSize: CGSize, toRect: CGRect) -> (xScalingFactor: CGFloat, yScalingFactor: CGFloat, lineWidthScalingFactor: CGFloat, fillIsHorizontal: Bool, offset: CGFloat) {
    
    let xSize = { () -> CGFloat in
        let scaledSize = (fromSize.width / CGFloat(2))
        if scaledSize > toRect.width {
            return (toRect.width / scaledSize) / CGFloat(2)
        }
        else {
            return CGFloat(0.5)
        }
    }()
    
    let ySize = { () -> CGFloat in
        let scaledSize = (fromSize.height / CGFloat(2))
        if scaledSize > toRect.height {
            return (toRect.height / scaledSize) / CGFloat(2)
        }
        else {
            return CGFloat(0.5)
        }
    }()
    
    let actualSize = min(xSize, ySize)
    
    return (actualSize, actualSize, actualSize, false, 0)
}

func centerShape(fromSize: CGSize, toRect: CGRect) {
    let xOffset = (toRect.width - fromSize.width) / CGFloat(2)
    let yOffset = (toRect.height - fromSize.height) / CGFloat(2)
    
    let ctx = UIGraphicsGetCurrentContext()
    CGContextSaveGState(ctx)
    CGContextTranslateCTM(ctx, xOffset, yOffset)
}

func endCenter() {
    let ctx = UIGraphicsGetCurrentContext()
    CGContextRestoreGState(ctx)
}

func drawBackspace(bounds: CGRect, color: UIColor) {
    let factors = getFactors(CGSizeMake(44, 32), toRect: bounds)
    let xScalingFactor = factors.xScalingFactor
    let yScalingFactor = factors.yScalingFactor
    let lineWidthScalingFactor = factors.lineWidthScalingFactor
    
    centerShape(CGSizeMake(44 * xScalingFactor, 32 * yScalingFactor), toRect: bounds)
    
    
    //// Color Declarations
    let color = color
    let color2 = UIColor.grayColor() // TODO:
    
    //// Bezier Drawing
    let bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPointMake(16 * xScalingFactor, 32 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(38 * xScalingFactor, 32 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(44 * xScalingFactor, 26 * yScalingFactor), controlPoint1: CGPointMake(38 * xScalingFactor, 32 * yScalingFactor), controlPoint2: CGPointMake(44 * xScalingFactor, 32 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(44 * xScalingFactor, 6 * yScalingFactor), controlPoint1: CGPointMake(44 * xScalingFactor, 22 * yScalingFactor), controlPoint2: CGPointMake(44 * xScalingFactor, 6 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(36 * xScalingFactor, 0 * yScalingFactor), controlPoint1: CGPointMake(44 * xScalingFactor, 6 * yScalingFactor), controlPoint2: CGPointMake(44 * xScalingFactor, 0 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(16 * xScalingFactor, 0 * yScalingFactor), controlPoint1: CGPointMake(32 * xScalingFactor, 0 * yScalingFactor), controlPoint2: CGPointMake(16 * xScalingFactor, 0 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(0 * xScalingFactor, 18 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(16 * xScalingFactor, 32 * yScalingFactor))
    bezierPath.closePath()
    color.setFill()
    bezierPath.fill()
    
    
    //// Bezier 2 Drawing
    let bezier2Path = UIBezierPath()
    bezier2Path.moveToPoint(CGPointMake(20 * xScalingFactor, 10 * yScalingFactor))
    bezier2Path.addLineToPoint(CGPointMake(34 * xScalingFactor, 22 * yScalingFactor))
    bezier2Path.addLineToPoint(CGPointMake(20 * xScalingFactor, 10 * yScalingFactor))
    bezier2Path.closePath()
    UIColor.grayColor().setFill()
    bezier2Path.fill()
    color2.setStroke()
    bezier2Path.lineWidth = 2.5 * lineWidthScalingFactor
    bezier2Path.stroke()
    
    
    //// Bezier 3 Drawing
    let bezier3Path = UIBezierPath()
    bezier3Path.moveToPoint(CGPointMake(20 * xScalingFactor, 22 * yScalingFactor))
    bezier3Path.addLineToPoint(CGPointMake(34 * xScalingFactor, 10 * yScalingFactor))
    bezier3Path.addLineToPoint(CGPointMake(20 * xScalingFactor, 22 * yScalingFactor))
    bezier3Path.closePath()
    UIColor.redColor().setFill()
    bezier3Path.fill()
    color2.setStroke()
    bezier3Path.lineWidth = 2.5 * lineWidthScalingFactor
    bezier3Path.stroke()
    
    endCenter()
}

func drawShift(bounds: CGRect, color: UIColor, withRect: Bool) {
    let factors = getFactors(CGSizeMake(38, (withRect ? 34 + 4 : 32)), toRect: bounds)
    let xScalingFactor = factors.xScalingFactor
    let yScalingFactor = factors.yScalingFactor
    _ = factors.lineWidthScalingFactor
    
    centerShape(CGSizeMake(38 * xScalingFactor, (withRect ? 34 + 4 : 32) * yScalingFactor), toRect: bounds)
    
    
    //// Color Declarations
    let color2 = color
    
    //// Bezier Drawing
    let bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPointMake(28 * xScalingFactor, 18 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(38 * xScalingFactor, 18 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(38 * xScalingFactor, 18 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(19 * xScalingFactor, 0 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(0 * xScalingFactor, 18 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(0 * xScalingFactor, 18 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(10 * xScalingFactor, 18 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(10 * xScalingFactor, 28 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(14 * xScalingFactor, 32 * yScalingFactor), controlPoint1: CGPointMake(10 * xScalingFactor, 28 * yScalingFactor), controlPoint2: CGPointMake(10 * xScalingFactor, 32 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(24 * xScalingFactor, 32 * yScalingFactor), controlPoint1: CGPointMake(16 * xScalingFactor, 32 * yScalingFactor), controlPoint2: CGPointMake(24 * xScalingFactor, 32 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(28 * xScalingFactor, 28 * yScalingFactor), controlPoint1: CGPointMake(24 * xScalingFactor, 32 * yScalingFactor), controlPoint2: CGPointMake(28 * xScalingFactor, 32 * yScalingFactor))
    bezierPath.addCurveToPoint(CGPointMake(28 * xScalingFactor, 18 * yScalingFactor), controlPoint1: CGPointMake(28 * xScalingFactor, 26 * yScalingFactor), controlPoint2: CGPointMake(28 * xScalingFactor, 18 * yScalingFactor))
    bezierPath.closePath()
    color2.setFill()
    bezierPath.fill()
    
    
    if withRect {
        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRectMake(10 * xScalingFactor, 34 * yScalingFactor, 18 * xScalingFactor, 4 * yScalingFactor))
        color2.setFill()
        rectanglePath.fill()
    }
    
    endCenter()
}

func drawGlobe(bounds: CGRect, color: UIColor) {
    let factors = getFactors(CGSizeMake(41, 40), toRect: bounds)
    let xScalingFactor = factors.xScalingFactor
    let yScalingFactor = factors.yScalingFactor
    let lineWidthScalingFactor = factors.lineWidthScalingFactor
    
    centerShape(CGSizeMake(41 * xScalingFactor, 40 * yScalingFactor), toRect: bounds)
    
    
    //// Color Declarations
    let color = color
    
    //// Oval Drawing
    let ovalPath = UIBezierPath(ovalInRect: CGRectMake(0 * xScalingFactor, 0 * yScalingFactor, 40 * xScalingFactor, 40 * yScalingFactor))
    color.setStroke()
    ovalPath.lineWidth = 1 * lineWidthScalingFactor
    ovalPath.stroke()
    
    
    //// Bezier Drawing
    let bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPointMake(20 * xScalingFactor, -0 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(20 * xScalingFactor, 40 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(20 * xScalingFactor, -0 * yScalingFactor))
    bezierPath.closePath()
    color.setStroke()
    bezierPath.lineWidth = 1 * lineWidthScalingFactor
    bezierPath.stroke()
    
    
    //// Bezier 2 Drawing
    let bezier2Path = UIBezierPath()
    bezier2Path.moveToPoint(CGPointMake(0.5 * xScalingFactor, 19.5 * yScalingFactor))
    bezier2Path.addLineToPoint(CGPointMake(39.5 * xScalingFactor, 19.5 * yScalingFactor))
    bezier2Path.addLineToPoint(CGPointMake(0.5 * xScalingFactor, 19.5 * yScalingFactor))
    bezier2Path.closePath()
    color.setStroke()
    bezier2Path.lineWidth = 1 * lineWidthScalingFactor
    bezier2Path.stroke()
    
    
    //// Bezier 3 Drawing
    let bezier3Path = UIBezierPath()
    bezier3Path.moveToPoint(CGPointMake(21.63 * xScalingFactor, 0.42 * yScalingFactor))
    bezier3Path.addCurveToPoint(CGPointMake(21.63 * xScalingFactor, 39.6 * yScalingFactor), controlPoint1: CGPointMake(21.63 * xScalingFactor, 0.42 * yScalingFactor), controlPoint2: CGPointMake(41 * xScalingFactor, 19 * yScalingFactor))
    bezier3Path.lineCapStyle = .Round;
    
    color.setStroke()
    bezier3Path.lineWidth = 1 * lineWidthScalingFactor
    bezier3Path.stroke()
    
    
    //// Bezier 4 Drawing
    let bezier4Path = UIBezierPath()
    bezier4Path.moveToPoint(CGPointMake(17.76 * xScalingFactor, 0.74 * yScalingFactor))
    bezier4Path.addCurveToPoint(CGPointMake(18.72 * xScalingFactor, 39.6 * yScalingFactor), controlPoint1: CGPointMake(17.76 * xScalingFactor, 0.74 * yScalingFactor), controlPoint2: CGPointMake(-2.5 * xScalingFactor, 19.04 * yScalingFactor))
    bezier4Path.lineCapStyle = .Round;
    
    color.setStroke()
    bezier4Path.lineWidth = 1 * lineWidthScalingFactor
    bezier4Path.stroke()
    
    
    //// Bezier 5 Drawing
    let bezier5Path = UIBezierPath()
    bezier5Path.moveToPoint(CGPointMake(6 * xScalingFactor, 7 * yScalingFactor))
    bezier5Path.addCurveToPoint(CGPointMake(34 * xScalingFactor, 7 * yScalingFactor), controlPoint1: CGPointMake(6 * xScalingFactor, 7 * yScalingFactor), controlPoint2: CGPointMake(19 * xScalingFactor, 21 * yScalingFactor))
    bezier5Path.lineCapStyle = .Round;
    
    color.setStroke()
    bezier5Path.lineWidth = 1 * lineWidthScalingFactor
    bezier5Path.stroke()
    
    
    //// Bezier 6 Drawing
    let bezier6Path = UIBezierPath()
    bezier6Path.moveToPoint(CGPointMake(6 * xScalingFactor, 33 * yScalingFactor))
    bezier6Path.addCurveToPoint(CGPointMake(34 * xScalingFactor, 33 * yScalingFactor), controlPoint1: CGPointMake(6 * xScalingFactor, 33 * yScalingFactor), controlPoint2: CGPointMake(19 * xScalingFactor, 22 * yScalingFactor))
    bezier6Path.lineCapStyle = .Round;
    
    color.setStroke()
    bezier6Path.lineWidth = 1 * lineWidthScalingFactor
    bezier6Path.stroke()
    
    endCenter()
}
