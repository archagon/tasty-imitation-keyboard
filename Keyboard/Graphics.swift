//
//  Graphics.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/5/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

func drawBackspace(bounds: CGRect, color: UIColor) {
    let highestX = CGFloat(43.5)
    let highestY = CGFloat(31.5)
    let xScalingFactor = (CGFloat(1.0) / highestX) * bounds.width
    let yScalingFactor = (CGFloat(1.0) / highestY) * bounds.height
    let lineWidthScalingFactor = bounds.width / highestX
    
    //// PaintCode Trial Version
    //// www.paintcodeapp.com
    
    //// Color Declarations
    let color = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)
    let color2 = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
    
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
}

func drawShift(bounds: CGRect, color: UIColor, withRect: Bool) {
    let highestX = CGFloat(37)
    let highestY = CGFloat((withRect ? 34.5 + 4 : 31.5))
    let xScalingFactor = (CGFloat(1.0) / highestX) * bounds.width
    let yScalingFactor = (CGFloat(1.0) / highestY) * bounds.height
    
    //// PaintCode Trial Version
    //// www.paintcodeapp.com
    
    //// Color Declarations
    let color2 = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
    
    //// Bezier Drawing
    var bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPointMake(28 * xScalingFactor, 18.7 * yScalingFactor))
    bezierPath.addLineToPoint(CGPointMake(37  * xScalingFactor, 18.7 * yScalingFactor))
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
        let rectanglePath = UIBezierPath(rect: CGRectMake(9.5, 34.5, 18.5, 4))
        color2.setFill()
        rectanglePath.fill()
    }
}
