//
//  KeyboardKey.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// popup constraints have to be setup with the superview in mind; hence these callbacks
protocol KeyboardKeyProtocol {
    func frameForPopup(key: KeyboardKey, direction: Direction) -> CGRect
    func willShowPopup(key: KeyboardKey, direction: Direction) //may be called multiple times during layout
    func willHidePopup(key: KeyboardKey)
}

enum VibrancyType {
    case LightSpecial
    case DarkSpecial
    case DarkRegular
}

// properties: vibrancy alpha percentage, underlay color, corner radius, graphics size

class KeyboardKey: UIControl {
    
    var delegate: KeyboardKeyProtocol?
    
    var vibrancy: VibrancyType?
    
    var text: String {
        didSet {
            self.label.text = text
            self.label.frame = self.bounds
            self.redrawText()
        }
    }
    
    var color: UIColor { didSet { updateColors() }}
    var underColor: UIColor { didSet { updateColors() }}
    var borderColor: UIColor { didSet { updateColors() }}
    var drawUnder: Bool { didSet { updateColors() }}
    var drawOver: Bool { didSet { updateColors() }}
    var drawBorder: Bool { didSet { updateColors() }}
    var underOffset: CGFloat { didSet { updateColors() }}
    
    var textColor: UIColor { didSet { updateColors() }}
    var downColor: UIColor? { didSet { updateColors() }}
    var downUnderColor: UIColor? { didSet { updateColors() }}
    var downBorderColor: UIColor? { didSet { updateColors() }}
    var downTextColor: UIColor? { didSet { updateColors() }}
    
    var popupDirection: Direction?
    
    override var enabled: Bool { didSet { updateColors() }}
    override var selected: Bool
        {
        didSet
        {
            updateColors()
        }
    }
    override var highlighted: Bool {
        didSet
        {
            updateColors()
        }
    }
    
    override var frame: CGRect {
        didSet {
            self.redrawText()
        }
    }
    
    var label: UILabel
    var popupLabel: UILabel?
    var shape: Shape? {
        didSet {
            self.redrawShape()
        }
    }
    
    var withBlur: Bool
    
    var background: KeyboardKeyBackground
    var popup: KeyboardKeyBackground?
    var connector: KeyboardConnector?
    
    var displayView: UIView
    var displayViewContentView: UIView
    var maskLayer: CAShapeLayer
    var borderLayer: CAShapeLayer
    var underLayer: CAShapeLayer
    var shadowView: UIView
    var shadowLayer: CAShapeLayer
    
    init(vibrancy: Bool) {
        self.vibrancy = VibrancyType.DarkRegular
        
//        let withBlur = (arc4random() % 2 == 0 ? true : false)
        let withBlur = false
        self.withBlur = withBlur
        
        self.background = KeyboardKeyBackground(blur: withBlur, cornerRadius: 3, underOffset: 2)
        
        self.displayView = {
            if withBlur {
                return UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
            }
            else {
                return UIView()
            }
        }()
        self.borderLayer = CAShapeLayer()
        self.underLayer = CAShapeLayer()
        self.shadowLayer = CAShapeLayer()
        self.maskLayer = CAShapeLayer()
        self.shadowView = UIView()
        
        if let effectView = self.displayView as? UIVisualEffectView {
            self.displayViewContentView = effectView.contentView
        }
        else {
            self.displayViewContentView = self.displayView
        }
        
        self.label = UILabel()
        self.text = ""
        
        self.color = UIColor.whiteColor()
        self.underColor = UIColor.grayColor()
        self.borderColor = UIColor.blackColor()
        self.drawUnder = true
        self.drawOver = true
        self.drawBorder = false
        self.underOffset = 1
        
        self.textColor = UIColor.blackColor()
        self.popupDirection = nil
        
        super.init(frame: frame)
        
        self.addSubview(self.shadowView)
        self.shadowView.layer.addSublayer(self.shadowLayer)
        
        self.addSubview(self.displayView)
        self.displayView.layer.mask = self.maskLayer
        self.displayViewContentView.layer.addSublayer(self.borderLayer)
        
        self.addSubview(self.background)
        self.background.addSubview(self.label)
        
        self.label.textAlignment = NSTextAlignment.Center
        self.label.font = self.label.font.fontWithSize(22)
        self.label.adjustsFontSizeToFitWidth = true
        self.label.userInteractionEnabled = false
        self.clipsToBounds = false
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func setNeedsLayout() {
        return super.setNeedsLayout()
    }
    
    var oldBounds: CGRect?
    override func layoutSubviews() {
        self.layoutPopup()
        
        if self.bounds.width == 0 || self.bounds.height == 0 {
            return
        }
        if oldBounds != nil && CGRectEqualToRect(self.bounds, oldBounds!) {
            return
        }
        oldBounds = self.bounds
        
        super.layoutSubviews()
        
        // TODO: no on 0, sam
        
        
        if self.text == "a" {
            NSLog("relayingout a: \(self.bounds)")
        }
        
        self.background.frame = self.bounds
        self.label.frame = self.bounds
        
        var boundingBox = CGRectUnion(self.bounds, self.popup!.frame)
        self.displayView.frame = boundingBox
        self.shadowView.frame = boundingBox
        
        self.refreshShapes()
        
        //        self.label.
        
        self.redrawText()
        self.redrawShape()
    }
    
    func refreshShapes() {
        self.background.layoutIfNeeded()
        self.popup?.layoutIfNeeded()
        self.connector?.layoutIfNeeded()
        
        var testPath = UIBezierPath()
        var edgePath = UIBezierPath()
        
        let addCurves = { (fromShape: KeyboardKeyBackground?, toPath: UIBezierPath, toEdgePaths: UIBezierPath) -> Void in
            let unitSquare = CGRectMake(0, 0, 1, 1)
            if let shape = fromShape {
                var path = shape.fillPath
                var translatedUnitSquare = self.displayView.convertRect(unitSquare, fromView: shape)
                let transformFromShapeToView = CGAffineTransformMakeTranslation(translatedUnitSquare.origin.x, translatedUnitSquare.origin.y)
                path?.applyTransform(transformFromShapeToView)
                if path != nil { toPath.appendPath(path!) }
                if let edgePaths = shape.edgePaths {
                    for (e, anEdgePath) in enumerate(edgePaths) {
                        var editablePath = anEdgePath
                        editablePath.applyTransform(transformFromShapeToView)
                        toEdgePaths.appendPath(editablePath)
                    }
                }
            }
        }
        
        addCurves(self.background, testPath, edgePath)
        addCurves(self.connector, testPath, edgePath)
        addCurves(self.popup, testPath, edgePath)
        
        // SHADOW
        
        self.shadowLayer.shadowOpacity = Float(0.5)
        self.shadowLayer.shadowRadius = 5
//        shadowView.frame = boundingBox
        self.shadowLayer.shadowPath = UIBezierPath(ovalInRect: CGRectMake(2, (shadowView.bounds.height / CGFloat(2)) - CGFloat(10) + CGFloat(5), shadowView.bounds.width - CGFloat(4), 20)).CGPath
        
        // UNDERLAY
        
        // BACKGROUND MASK
        
        self.maskLayer.path = testPath.CGPath
//        self.displayViewContentView.layer.backgroundColor = UIColor.yellowColor().CGColor
        
        // BORDER
        
        self.borderLayer.path = edgePath.CGPath
        self.borderLayer.borderWidth = 5
        borderLayer.strokeColor = UIColor.blueColor().CGColor
        borderLayer.fillColor = UIColor.clearColor().CGColor
    }
    
    func layoutPopup() {
        if self.popup != nil && self.popupDirection == nil {
            self.popupDirection = Direction.Up
            
            self.layoutPopup(self.popupDirection!)
            self.configurePopup(self.popupDirection!)
            
            //            super.layoutSubviews()
            self.delegate?.willShowPopup(self, direction: self.popupDirection!)
            
            var upperLeftCorner = self.popup!.frame.origin
            var popupPosition = self.superview!.convertPoint(upperLeftCorner, fromView: self) // TODO: hack
            
            //            if popupPosition.y < 0 {
            //            if self.popup!.bounds.height < 10 {
            //                if self.frame.origin.x < self.superview!.bounds.width/2 { // TODO: hack
            //                    self.popupDirection = Direction.Right
            //                }
            //                else {
            //                    self.popupDirection = Direction.Left
            //                }
            //                self.setupPopupConstraints(self.popupDirection)
            //                self.delegate?.willShowPopup(self, direction: self.popupDirection)
            //                self.configurePopup(self.popupDirection)
            //                super.layoutSubviews()
            //            }
            
//            self.createAwesomeBackground()
        }
    }
    
    //    var shadowAlpha: CGFloat { didSet { self.setNeedsDisplay() }}
    //    var shadowOffset: CGPoint { didSet { self.setNeedsDisplay() }}
    //    var shadowBlurRadius: CGFloat { didSet { self.setNeedsDisplay() }}
    //    shadowAlpha = CGFloat(0.35)
    //    shadowOffset = CGPointMake(0, 1.5)
    //    shadowBlurRadius = CGFloat(12)
    
    var awesomeBackground: UIView?
    var awesomeShadow: UIView?
    func createAwesomeBackground() {
        return;
        
//        self.popup?.hidden = true
//        self.background.hidden = true
//        self.connector?.hidden = true
        
        self.background.layoutIfNeeded()
        self.popup?.layoutIfNeeded()
        self.connector?.layoutIfNeeded()
        
        var testPath = UIBezierPath()
        var edgePath = UIBezierPath()
        
        var boundingBox = CGRectUnion(self.bounds, self.popup!.frame)
        var prettyView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
//        prettyView.backgroundColor = (self.blurryTemp ? nil : UIColor.yellowColor())
//        prettyView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(CGFloat(0.25))
        prettyView.contentView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(CGFloat(0.25))
        prettyView.frame = boundingBox
        
//        var shadowShapeLayer = CAShapeLayer()
////        shadowView.layer = shadowShapeLayer
//        let scalingFactor: CGSize = CGSizeMake(3, 1.5)
//        var shadowViewFrame = CGRectZero
////        shadowViewFrame.size = CGSizeMake(boundingBox.width * scalingFactor.width, boundingBox.height * scalingFactor.height)
////        shadowViewFrame.origin.x = boundingBox.origin.x + ((boundingBox.width - shadowViewFrame.width) / CGFloat(2))
////        shadowViewFrame.origin.y = boundingBox.origin.y + ((boundingBox.height - shadowViewFrame.height) / CGFloat(2))
////        shadowView.frame = shadowViewFrame
////        shadowView.frame = boundingBox
//        shadowShapeLayer.frame = boundingBox
//        shadowShapeLayer.opaque = false
        
//        shadowView.backgroundColor = UIColor.greenColor()
        
        self.awesomeBackground = prettyView
//        self.awesomeShadow = shadowView
        
//        self.addSubview(shadowView)
//        self.layer.addSublayer(shadowShapeLayer)
        self.addSubview(prettyView)
        
        let unitSquare = CGRectMake(0, 0, 1, 1)
        
        var backgroundPath = self.background.fillPath!
        var translatedUnitSquare = prettyView.convertRect(unitSquare, fromView: self.background)
        let transformFromBackgroundToView = CGAffineTransformMakeTranslation(translatedUnitSquare.origin.x, translatedUnitSquare.origin.y)
        backgroundPath.applyTransform(transformFromBackgroundToView)
        testPath.appendPath(backgroundPath)
        for (e, anEdgePath) in enumerate(self.background.edgePaths!) {
            var editablePath = anEdgePath
            editablePath.applyTransform(transformFromBackgroundToView)
            edgePath.appendPath(editablePath)
        }
        
        var connectorPath = self.connector!.fillPath!
        translatedUnitSquare = prettyView.convertRect(unitSquare, fromView: self.connector!)
        let transformFromConnectorToView = CGAffineTransformMakeTranslation(translatedUnitSquare.origin.x, translatedUnitSquare.origin.y)
        connectorPath.applyTransform(transformFromConnectorToView)
        testPath.appendPath(connectorPath)
        for (e, anEdgePath) in enumerate(self.connector!.edgePaths!) {
            var editablePath = anEdgePath.copy() as UIBezierPath
            editablePath.applyTransform(transformFromConnectorToView)
            edgePath.appendPath(editablePath)
        }
        
        var popupPath = self.popup!.fillPath!
        translatedUnitSquare = prettyView.convertRect(unitSquare, fromView: self.popup!)
        let transformFromPopupToView = CGAffineTransformMakeTranslation(translatedUnitSquare.origin.x, translatedUnitSquare.origin.y)
        popupPath.applyTransform(transformFromPopupToView)
        testPath.appendPath(popupPath)
        for (e, anEdgePath) in enumerate(self.popup!.edgePaths!) {
            var editablePath = anEdgePath
            editablePath.applyTransform(transformFromPopupToView)
            edgePath.appendPath(editablePath)
        }

        // SHADOW
        
//        shadowShapeLayer.path = testPath.CGPath
//        shadowShapeLayer.fillColor = UIColor.redColor().colorWithAlphaComponent(CGFloat(0.25)).CGColor
//        shadowShapeLayer.shadowColor = UIColor.blackColor().CGColor
//        shadowShapeLayer.shadowOffset = CGSizeMake(10, 10)
//        shadowShapeLayer.shadowOpacity = Float(0.75)
        
        var shapeLayer1 = CAShapeLayer()
//        shapeLayer1.fillColor = UIColor.blueColor().CGColor
//        maskLayer.path = testPath.bezierPathByReversingPath().CGPath
        var shadowView = UIView()
//        shapeLayer1.fillColor = UIColor.redColor().CGColor
        shapeLayer1.shadowOpacity = Float(0.5)
        shadowView.frame = boundingBox
//        shadowView.frame.origin.x -= 40
        shadowView.layer.addSublayer(shapeLayer1)
        shapeLayer1.shadowRadius = 5
        shapeLayer1.shadowPath = UIBezierPath(ovalInRect: CGRectMake(2, (shadowView.bounds.height / CGFloat(2)) - CGFloat(10) + CGFloat(5), shadowView.bounds.width - CGFloat(4), 20)).CGPath
        
//        shapeLayer1.shadowOpacity = Float(1)
//        shapeLayer1.mask = maskLayer
//        shapeLayer1.shadowOffset = CGSizeMake(-20, 20)
//        shapeLayer1.frame = shadowView.bounds
//        maskLayer.frame = shadowView.bounds
        var clipRectPath = UIBezierPath(rect: shadowView.bounds)
        clipRectPath.appendPath(testPath)
//        maskLayer.path = clipRectPath.CGPath
        self.addSubview(shadowView)
        awesomeShadow = shadowView
        
        
        // UNDERLAY
        
        // BG MASK
        
        var shapeLayer = CAShapeLayer()
        shapeLayer.path = testPath.CGPath
        prettyView.layer.mask = shapeLayer
//        shadowShapeLayer.removeFromSuperlayer()
//        shadowShapeLayer.frame.origin = CGPointZero
//        prettyView.layer.addSublayer(shadowShapeLayer)
        
        // BORDER
        
        var borderLayer = CAShapeLayer()
        borderLayer.path = edgePath.CGPath
        borderLayer.borderWidth = 5
//        borderLayer.borderColor = UIColor.blueColor().CGColor
        borderLayer.strokeColor = UIColor.blueColor().CGColor
        borderLayer.fillColor = UIColor.clearColor().CGColor
        prettyView.contentView.layer.addSublayer(borderLayer)
        
        prettyView.removeFromSuperview()
        self.addSubview(prettyView)
    }
    
    func redrawText() {
//        self.keyView.frame = self.bounds
//        self.button.frame = self.bounds
//        
//        self.button.setTitle(self.text, forState: UIControlState.Normal)
    }
    
    func redrawShape() {
        if let shape = self.shape {
            self.text = ""
            shape.removeFromSuperview()
            self.addSubview(shape)
            
            let sizeRatio = CGFloat(1)
            let size = CGSizeMake(self.bounds.width * sizeRatio, self.bounds.height * sizeRatio)
            shape.frame = CGRectMake(
                CGFloat((self.bounds.width - size.width) / 2.0),
                CGFloat((self.bounds.height - size.height) / 2.0),
                size.width,
                size.height)
            
            shape.setNeedsDisplay()
        }
    }
    
    func updateColors() {
        if self.withBlur {
            self.displayViewContentView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(CGFloat(0.25))
        }
        else {
            self.displayViewContentView.backgroundColor = self.color
        }
        
        let switchColors = self.highlighted || self.selected
        
        if switchColors {
            if let downColor = self.downColor {
                self.displayViewContentView.backgroundColor = downColor
            }
        }
        
        self.label.textColor = (switchColors && self.downTextColor != nil ? self.downTextColor! : self.textColor)
        if self.popup != nil {
//            self.popup!.label.textColor = (switchColors && self.downTextColor != nil ? self.downTextColor! : self.textColor)
        }
        
//        self.borderLayer.hidden = !switchColors
        self.borderLayer.hidden = true
        
//        if self.backgroundContainer.vibrancyView != nil {
////            self.background.color = UIColor.whiteColor().colorWithAlphaComponent(0.25)
////            self.background.color = UIColor.whiteColor().colorWithAlphaComponent(0.35)
//            self.background.color = UIColor.redColor().colorWithAlphaComponent(CGFloat(0.5))
//            self.overlay?.hidden = !switchColors
//        }
        
//        self.underlay.color = UIColor(red: CGFloat(38.6)/CGFloat(255), green: CGFloat(18)/CGFloat(255), blue: CGFloat(39.3)/CGFloat(255), alpha: 0.4)
    }
    
    func layoutPopup(dir: Direction) {
        assert(self.popup != nil, "popup not found")
        
        if let popup = self.popup {
            if let delegate = self.delegate {
                let frame = delegate.frameForPopup(self, direction: dir)
                popup.frame = frame
                popupLabel?.frame = popup.bounds
            }
            else {
                popup.frame = CGRectZero
                popup.center = self.center
            }
        }
    }
    
    func configurePopup(direction: Direction) {
        assert(self.popup != nil, "popup not found")
        
        self.background.attach(direction)
        self.popup!.attach(direction.opposite())
        
        let kv = self.background
        let p = self.popup!
        
        self.connector?.removeFromSuperview()
        self.connector = KeyboardConnector(blur: withBlur, cornerRadius: 3, underOffset: 2, start: kv, end: p, startConnectable: kv, endConnectable: p, startDirection: direction, endDirection: direction.opposite())
        self.connector!.layer.zPosition = -1
        self.addSubview(self.connector!)
        
//        self.drawBorder = true
        
        if direction == Direction.Up {
//            self.popup!.drawUnder = false
//            self.connector!.drawUnder = false
        }
    }
    
    func showPopup() {
//        self.center = CGPointMake(self.center.x, self.center.y - CGFloat(30))
        
        if self.popup == nil {
            self.layer.zPosition = 1000
            
            var popup = KeyboardKeyBackground(blur: withBlur, cornerRadius: 9.0, underOffset: 2)
//            self.addSubview(popup)
            
            self.popup = popup
            self.addSubview(popup)
            
            var popupLabel = UILabel()
            popupLabel.textColor = UIColor.blackColor()
            popupLabel.textAlignment = self.label.textAlignment
            popupLabel.font = self.label.font.fontWithSize(22 * 2)
            popupLabel.frame = popup.bounds
            popupLabel.text = self.label.text
            popup.addSubview(popupLabel)
            self.popupLabel = popupLabel
            
            self.label.hidden = true
            
//            self.popupDirection = .Up
        }
    }
    
    func hidePopup() {
        if self.awesomeBackground != nil {
            self.awesomeBackground?.removeFromSuperview()
            self.awesomeShadow?.removeFromSuperview()
        }
        
        if self.popup != nil {
            self.delegate?.willHidePopup(self)
            
            self.popupLabel?.removeFromSuperview()
            self.popupLabel = nil
            
            self.connector?.removeFromSuperview()
            self.connector = nil
            
            self.popup?.removeFromSuperview()
            self.popup = nil
            
            self.label.hidden = false
            self.background.attach(nil)
            
//            self.background.drawBorder = false
            
            self.layer.zPosition = 0
            
            self.popupDirection = nil
        }
    }
}
