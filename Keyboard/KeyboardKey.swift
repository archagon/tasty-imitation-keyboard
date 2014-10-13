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

class KeyboardKey: UIControl, KeyboardView {
    
    var delegate: KeyboardKeyProtocol?
    
    var vibrancy: VibrancyType?
    
    var background: KeyboardKeyBackground
    
    var underlay: KeyboardKeyBackground
    var overlay: KeyboardKeyBackground?
    
    var popup: KeyboardKeyBackground?
    
    var connector: KeyboardConnector?
    
    var label: UILabel
    var popupLabel: UILabel?
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
    
    var shape: Shape? {
        didSet {
            self.redrawShape()
        }
    }
    
    override var frame: CGRect {
        didSet {
            self.redrawText()
        }
    }
    
    var blurryTemp: Bool = false
    init(vibrancy: Bool) {
        self.vibrancy = VibrancyType.DarkRegular
        
        self.blurryTemp = (arc4random() % 2 == 0 ? true : false)
        self.background = KeyboardKeyBackground(blur: blurryTemp)
//        self.backgroundContainer = VibrancyContainer(view: self.background, vibrancyType: self.vibrancy)
        
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
        
        self.underlay = KeyboardKeyBackground(blur: false)
        
        super.init(frame: frame)

//        self.addSubview(self.backgroundContainer)
        
        self.underlay.drawOver = false
        self.underlay.drawBorder = false
        self.underlay.drawUnder = true
        self.addSubview(self.underlay)
        
//        if vibrancy {
////            let blur = UIBlurEffect(style: UIBlurEffectStyle.ExtraLight)
//            let blur = UIBlurEffect(style: UIBlurEffectStyle.Dark)
//            let vibrancy = UIVibrancyEffect(forBlurEffect: blur)
//            var vibrancyView = UIVisualEffectView(effect: vibrancy)
//            
//            self.addSubview(vibrancyView)
//            
//            vibrancyView.contentView.addSubview(self.background)
//            self.vibrancyView = vibrancyView
//            
//            self.overlay = KeyboardKeyBackground(frame: CGRectZero)
//            self.overlay?.color = UIColor.whiteColor()
//            self.overlay?.drawUnder = false
//            self.addSubview(self.overlay!)
//        }
//        else {
//            self.addSubview(self.background)
//        }
        
        self.addSubview(self.background)
        
        self.label.textAlignment = NSTextAlignment.Center
        self.label.font = self.label.font.fontWithSize(22)
        self.label.adjustsFontSizeToFitWidth = true
        self.label.userInteractionEnabled = false
        self.clipsToBounds = false
        
        self.addSubview(self.label)
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
        
//        self.backgroundContainer.frame = self.bounds
        self.background.frame = self.bounds
//        self.underlay.frame = self.bounds
//        self.overlay?.frame = self.bounds
        
        self.label.frame = self.bounds
        
        self.redrawText()
        self.redrawShape()
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
        }
    }
    
    var awesomeBackground: UIView?
    func createAwesomeBackground() {
        self.popup?.drawBorder = true
        self.background.drawBorder = true
        self.connector?.drawBorder = true
        
        if self.blurryTemp {
            self.popup?.hidden = true
            self.background.hidden = true
            self.connector?.hidden = true
        }
        else {
            self.popup?.hidden = false
            self.background.hidden = false
            self.connector?.hidden = false
            
            return
        }
        
        self.popup?.drawUnder = false
        self.connector?.drawUnder = false
        
        self.background.layoutIfNeeded()
        self.popup?.layoutIfNeeded()
        self.connector?.layoutIfNeeded()
        
        var testPath = UIBezierPath()
//        testPath.usesEvenOddFillRule = true
        
        var boundingBox = CGRectUnion(self.bounds, self.popup!.frame)
        var prettyView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
        prettyView.backgroundColor = (self.blurryTemp ? nil : UIColor.yellowColor())
        prettyView.frame = boundingBox
        self.addSubview(prettyView)
        
        let unitSquare = CGRectMake(0, 0, 1, 1)
        
        var backgroundPath = self.background.fillPath!
        var translatedUnitSquare = prettyView.convertRect(unitSquare, fromView: self.background)
        let transformFromBackgroundToView = CGAffineTransformMakeTranslation(translatedUnitSquare.origin.x, translatedUnitSquare.origin.y)
        backgroundPath.applyTransform(transformFromBackgroundToView)
        testPath.appendPath(backgroundPath)
        
        var connectorPath = self.connector!.fillPath!
        translatedUnitSquare = prettyView.convertRect(unitSquare, fromView: self.connector!)
        let transformFromConnectorToView = CGAffineTransformMakeTranslation(translatedUnitSquare.origin.x, translatedUnitSquare.origin.y)
        connectorPath.applyTransform(transformFromConnectorToView)
        testPath.appendPath(connectorPath)
        
        var popupPath = self.popup!.fillPath!
        translatedUnitSquare = prettyView.convertRect(unitSquare, fromView: self.popup!)
        let transformFromPopupToView = CGAffineTransformMakeTranslation(translatedUnitSquare.origin.x, translatedUnitSquare.origin.y)
        popupPath.applyTransform(transformFromPopupToView)
        testPath.appendPath(popupPath)
        
        var shapeLayer = CAShapeLayer()
        shapeLayer.path = testPath.CGPath
//        shapeLayer.borderWidth = 2
//        shapeLayer.borderColor = UIColor.blackColor().CGColor
        prettyView.layer.mask = shapeLayer
        prettyView.layer.borderWidth = 3
        prettyView.layer.borderColor = UIColor.blackColor().CGColor
        
        self.awesomeBackground = prettyView
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
        var keyboardViews: [KeyboardView] = [self.background]
        if self.popup != nil { keyboardViews.append(self.popup!) }
        if self.connector != nil { keyboardViews.append(self.connector!) }
        
        var switchColors = self.highlighted || self.selected
        
        self.underlay.hidden = !self.drawUnder
        self.background.drawUnder = false
//        self.underlay.hidden = true
//        self.keyView.drawUnder = true
        
        for kv in keyboardViews {
            var keyboardView = kv
            keyboardView.color = (switchColors && self.downColor != nil ? self.downColor! : self.color)
            keyboardView.underColor = (switchColors && self.downUnderColor != nil ? self.downUnderColor! : self.underColor)
            keyboardView.borderColor = (switchColors && self.downBorderColor != nil ? self.downBorderColor! : self.borderColor)
            keyboardView.drawBorder = self.drawBorder
        }
        
        self.label.textColor = (switchColors && self.downTextColor != nil ? self.downTextColor! : self.textColor)
        if self.popup != nil {
//            self.popup!.label.textColor = (switchColors && self.downTextColor != nil ? self.downTextColor! : self.textColor)
        }
        
//        if self.backgroundContainer.vibrancyView != nil {
////            self.background.color = UIColor.whiteColor().colorWithAlphaComponent(0.25)
////            self.background.color = UIColor.whiteColor().colorWithAlphaComponent(0.35)
//            self.background.color = UIColor.redColor().colorWithAlphaComponent(CGFloat(0.5))
//            self.overlay?.hidden = !switchColors
//        }
        
        self.underlay.color = UIColor(red: CGFloat(38.6)/CGFloat(255), green: CGFloat(18)/CGFloat(255), blue: CGFloat(39.3)/CGFloat(255), alpha: 0.4)
        
        if self.blurryTemp {
            self.background.color = UIColor.clearColor()
            self.popup?.color = UIColor.clearColor()
        }
        else {
            self.background.color = UIColor.yellowColor()
            self.popup?.color = UIColor.yellowColor()
        }
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
        self.connector = KeyboardConnector(start: kv, end: p, startConnectable: kv, endConnectable: p, startDirection: direction, endDirection: direction.opposite())
        self.connector!.layer.zPosition = -1
        self.addSubview(self.connector!)
        
        self.drawBorder = true
        
        if direction == Direction.Up {
            self.popup!.drawUnder = false
            self.connector!.drawUnder = false
        }
    }
    
    func showPopup() {
//        self.center = CGPointMake(self.center.x, self.center.y - CGFloat(30))
        
        if self.popup == nil {
            self.layer.zPosition = 1000
            
            var popup = KeyboardKeyBackground(blur: true)
            popup.cornerRadius = 9.0
//            self.addSubview(popup)
            
            self.popup = popup
            self.addSubview(popup)
            
            var popupLabel = UILabel()
            popupLabel.textColor = UIColor.blackColor()
            popupLabel.textAlignment = self.label.textAlignment
            popupLabel.font = self.label.font.fontWithSize(22 * 2)
            popupLabel.frame = popup.bounds
            popupLabel.text = self.label.text
//            popup.addSubview(popupLabel)
            self.popupLabel = popupLabel
            
            self.label.hidden = true
            
//            self.popupDirection = .Up
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
            
            self.background.drawBorder = false
            
            self.layer.zPosition = 0
            
            self.popupDirection = nil
        }
    }
}
