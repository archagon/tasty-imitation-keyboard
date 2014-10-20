//
//  KeyboardKey.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// TODO: animation on color set
// TODO: correct corner radius
// TODO: correct colors
// TODO: refactor

// popup constraints have to be setup with the topmost view in mind; hence these callbacks
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

//extension UIView {
//    func blurredSnapshot() -> UIImage {
//        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, (self.window != nil ? self.window!.screen.scale : 1))
//        self.drawViewHierarchyInRect(self.frame, afterScreenUpdates: false)
//        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
//        var blurredImage = snapshotImage.applyLightEffect()
//        UIGraphicsEndImageContext()
//        return blurredImage
//    }
//}

class KeyboardKey: UIControl {
    
    var delegate: KeyboardKeyProtocol?
    
    var vibrancy: VibrancyType?
    
    var text: String {
        didSet {
            self.label.text = text
            self.label.frame = CGRectMake((self.bounds.width - self.bounds.width * CGFloat(0.8)) / CGFloat(2), 0, self.bounds.width * CGFloat(0.8), self.bounds.height)
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
    override var selected: Bool {
        didSet {
            updateColors()
        }
    }
    override var highlighted: Bool {
        didSet {
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
            updateColors()
        }
    }
    
    var withBlur: Bool
    
    var background: KeyboardKeyBackground
    var popup: KeyboardKeyBackground?
    var connector: KeyboardConnector?
    
    var displayView: UIView
    var displayViewContentView: UIView
    var displayMaskView: UIView?
    var maskLayer: CAShapeLayer
    var borderView: UIView
    var borderLayer: CAShapeLayer
    var underLayer: CAShapeLayer
    var underView: UIView
    var shadowView: UIView
    var shadowLayer: CAShapeLayer
    
    class DumbLayer: CALayer {
        override func addAnimation(anim: CAAnimation!, forKey key: String!) {
        }
    }
    
    override class func layerClass() -> AnyClass {
        return DumbLayer.self
    }
    
    init(vibrancy optionalVibrancy: VibrancyType?) {
        self.withBlur = (optionalVibrancy != nil)
        
        self.displayView = {
            if let vibrancy = optionalVibrancy {
                let blurEffect = { () -> UIVisualEffect? in
                    switch vibrancy {
                    case .LightSpecial:
                        //return UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight)) -- goes with grey 0.25
                        return UIBlurEffect(style: UIBlurEffectStyle.Light)
                    case .DarkSpecial:
                        return UIBlurEffect(style: UIBlurEffectStyle.Light)
                    case .DarkRegular:
                        return UIBlurEffect(style: UIBlurEffectStyle.Light)
                    }
                }()
                return (blurEffect != nil ? UIVisualEffectView(effect: blurEffect!) : UIView())
            }
            else {
                return UIView()
            }
        }()
        
        self.borderLayer = CAShapeLayer()
        self.borderView = UIView()
        self.underLayer = CAShapeLayer()
        self.underView = UIView()
        self.shadowLayer = CAShapeLayer()
        self.shadowView = UIView()
        self.maskLayer = CAShapeLayer()
        
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
        
        self.background = KeyboardKeyBackground(blur: withBlur, cornerRadius: 4, underOffset: self.underOffset)
        
        self.textColor = UIColor.blackColor()
        self.popupDirection = nil
        
        super.init(frame: CGRectZero)
        
        self.addSubview(self.shadowView)
        self.shadowView.layer.addSublayer(self.shadowLayer)
        
        if self.withBlur {
            // use it as a mask
            self.displayMaskView = UIView()
            self.displayMaskView?.layer.mask = self.maskLayer
            self.displayMaskView?.addSubview(self.displayView)
            self.addSubview(self.displayMaskView!)
        }
        else {
            // use it to draw directly
            self.displayViewContentView.layer.addSublayer(self.maskLayer)
            self.addSubview(self.displayView)
        }
        
        self.underView.layer.addSublayer(self.underLayer)
        self.addSubview(self.underView)
        
        self.borderView.layer.addSublayer(self.borderLayer)
        self.addSubview(self.borderView)
        
        self.addSubview(self.background)
        self.background.addSubview(self.label)
        
        let setupViews: Void = {
            self.label.textAlignment = NSTextAlignment.Center
            self.label.baselineAdjustment = UIBaselineAdjustment.AlignCenters
            self.label.font = self.label.font.fontWithSize(22)
            self.label.adjustsFontSizeToFitWidth = false
            self.label.minimumScaleFactor = CGFloat(0.1)
            self.label.userInteractionEnabled = false
            self.label.numberOfLines = 1
            
            self.shadowLayer.shadowOpacity = Float(0.2)
            self.shadowLayer.shadowRadius = 4
            self.shadowLayer.shadowOffset = CGSizeMake(0, 3)
            
            self.borderLayer.lineWidth = CGFloat(0.5)
            self.borderLayer.fillColor = UIColor.clearColor().CGColor
        }()
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func setNeedsLayout() {
        return super.setNeedsLayout()
    }
    
    var oldBounds: CGRect?
    override func layoutSubviews() {
        self.layoutPopupIfNeeded()
        
        var boundingBox = (self.popup != nil ? CGRectUnion(self.bounds, self.popup!.frame) : self.bounds)
        
        if self.bounds.width == 0 || self.bounds.height == 0 {
            return
        }
        if oldBounds != nil && CGRectEqualToRect(boundingBox, oldBounds!) {
            return
        }
        oldBounds = boundingBox

        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.background.frame = self.bounds
        self.label.frame = CGRectMake((self.bounds.width - self.bounds.width * CGFloat(0.8)) / CGFloat(2), 0, self.bounds.width * CGFloat(0.8), self.bounds.height)
        
        if let maskView = self.displayMaskView {
            maskView.frame = boundingBox
            self.displayView.frame = maskView.bounds
        }
        else {
            self.displayView.frame = boundingBox
        }

        self.shadowView.frame = boundingBox
        self.borderView.frame = boundingBox
        self.underView.frame = boundingBox
        
        CATransaction.commit()
        
        self.refreshViews()

//        if self.text == "a" || self.text == "A" {
//            self.background.trackMe = true
//            NSLog("relayingout a: \(self.bounds)")
//        }
    }
    
    func refreshViews() {
        self.refreshShapes()
        self.redrawText()
        self.redrawShape()
        self.updateColors()
    }
    
//   TODO:  UIView mask
    
    func refreshShapes() {
        // TODO: dunno why this is necessary
        self.background.setNeedsLayout()
        
        self.background.layoutIfNeeded()
        self.popup?.layoutIfNeeded()
        self.connector?.layoutIfNeeded()
        
        var testPath = UIBezierPath()
        var edgePath = UIBezierPath()
        
        let unitSquare = CGRectMake(0, 0, 1, 1)
        
        // TODO: withUnder
        let addCurves = { (fromShape: KeyboardKeyBackground?, toPath: UIBezierPath, toEdgePaths: UIBezierPath) -> Void in
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
        
        addCurves(self.popup, testPath, edgePath)
        addCurves(self.connector, testPath, edgePath)
        
        var shadowPath = UIBezierPath(CGPath: testPath.CGPath)
        
        addCurves(self.background, testPath, edgePath)
        
        var underPath = self.background.underPath
        var translatedUnitSquare = self.displayView.convertRect(unitSquare, fromView: self.background)
        let transformFromShapeToView = CGAffineTransformMakeTranslation(translatedUnitSquare.origin.x, translatedUnitSquare.origin.y)
        underPath?.applyTransform(transformFromShapeToView)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if let popup = self.popup {
            self.shadowLayer.shadowPath = shadowPath.CGPath
        }
        
        self.underLayer.path = underPath?.CGPath
        self.maskLayer.path = testPath.CGPath
        self.borderLayer.path = edgePath.CGPath
        
        CATransaction.commit()
    }
    
    func layoutPopupIfNeeded() {
        if self.popup != nil && self.popupDirection == nil {
            self.shadowView.hidden = false
            self.borderView.hidden = (self.withBlur ? true : false)
            
            self.popupDirection = Direction.Up
            
            self.layoutPopup(self.popupDirection!)
            self.configurePopup(self.popupDirection!)
            
            self.delegate?.willShowPopup(self, direction: self.popupDirection!)
        }
        else {
            self.shadowView.hidden = true
            self.borderView.hidden = true
        }
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
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let switchColors = self.highlighted || self.selected
        
        if switchColors {
            if let downColor = self.downColor {
                if self.withBlur {
                    self.displayViewContentView.backgroundColor = downColor
                }
                else {
                    self.maskLayer.fillColor = downColor.CGColor
                }
            }
            else {
                if self.withBlur {
                    self.displayViewContentView.backgroundColor = self.color
                }
                else {
                    self.maskLayer.fillColor = self.color.CGColor
                }
            }
            
            if let downUnderColor = self.downUnderColor {
                self.underLayer.fillColor = downUnderColor.CGColor
            }
            else {
                self.underLayer.fillColor = self.underColor.CGColor
            }
            
            if let downBorderColor = self.downBorderColor {
                self.borderLayer.strokeColor = downBorderColor.CGColor
            }
            else {
                self.borderLayer.strokeColor = self.borderColor.CGColor
            }
            
            if let downTextColor = self.downTextColor {
                self.label.textColor = downTextColor
                self.popupLabel?.textColor = downTextColor
                self.shape?.color = downTextColor
            }
            else {
                self.label.textColor = self.textColor
                self.popupLabel?.textColor = self.textColor
                self.shape?.color = self.textColor
            }
        }
        else {
            if self.withBlur {
                self.displayViewContentView.backgroundColor = self.color
            }
            else {
                self.maskLayer.fillColor = self.color.CGColor
            }
            
            self.underLayer.fillColor = self.underColor.CGColor
            
            self.borderLayer.strokeColor = self.borderColor.CGColor
            
            self.label.textColor = self.textColor
            self.popupLabel?.textColor = self.textColor
            self.shape?.color = self.textColor
        }
        
        CATransaction.commit()
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
        self.connector = KeyboardConnector(blur: withBlur, cornerRadius: 4, underOffset: self.underOffset, start: kv, end: p, startConnectable: kv, endConnectable: p, startDirection: direction, endDirection: direction.opposite())
        self.connector!.layer.zPosition = -1
        self.addSubview(self.connector!)
        
//        self.drawBorder = true
        
        if direction == Direction.Up {
//            self.popup!.drawUnder = false
//            self.connector!.drawUnder = false
        }
    }
    
    func showPopup() {
        if self.popup == nil {
            self.layer.zPosition = 1000
            
            var popup = KeyboardKeyBackground(blur: withBlur, cornerRadius: 9.0, underOffset: self.underOffset)
            self.popup = popup
            self.addSubview(popup)
            
            var popupLabel = UILabel()
            popupLabel.textAlignment = self.label.textAlignment
            popupLabel.font = self.label.font.fontWithSize(22 * 2)
            popupLabel.frame = popup.bounds
            popupLabel.text = self.label.text
            popup.addSubview(popupLabel)
            self.popupLabel = popupLabel
            
            self.label.hidden = true
        }
    }
    
    func hidePopup() {
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
            
            self.layer.zPosition = 0
            
            self.popupDirection = nil
        }
    }
}
