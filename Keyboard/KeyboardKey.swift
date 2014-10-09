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

// properties: vibrancy alpha percentage, underlay color, corner radius, graphics size

class KeyboardKey: UIControl, KeyboardView {
    
    var delegate: KeyboardKeyProtocol?
    
    var background: KeyboardKeyBackground
    var vibrancyView: UIVisualEffectView?
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
    var drawBorder: Bool { didSet { updateColors() }}
    
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
    
    init(vibrancy: Bool) {
        self.background = KeyboardKeyBackground(frame: CGRectZero)
        self.label = UILabel()
        self.text = ""
        
        self.color = UIColor.whiteColor()
        self.underColor = UIColor.grayColor()
        self.borderColor = UIColor.blackColor()
        self.drawUnder = true
        self.drawBorder = false
        self.textColor = UIColor.blackColor()
        self.popupDirection = nil
        
        self.underlay = KeyboardKeyBackground(frame: CGRectZero)
        
        super.init(frame: frame)
        
        self.underlay.drawOver = false
        self.underlay.drawBorder = false
        self.underlay.drawUnder = true
        self.addSubview(self.underlay)
        
        if vibrancy {
            let blur = UIBlurEffect(style: UIBlurEffectStyle.ExtraLight)
            let vibrancy = UIVibrancyEffect(forBlurEffect: blur)
            var vibrancyView = UIVisualEffectView(effect: vibrancy)
            
            self.addSubview(vibrancyView)
            
            vibrancyView.contentView.addSubview(self.background)
            self.vibrancyView = vibrancyView
            
            self.overlay = KeyboardKeyBackground(frame: CGRectZero)
            self.overlay?.color = UIColor.whiteColor()
            self.overlay?.drawUnder = false
            self.addSubview(self.overlay!)
        }
        else {
            self.addSubview(self.background)
        }
        
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.vibrancyView?.frame = self.bounds
        self.underlay.frame = self.bounds
        self.overlay?.frame = self.bounds
        
        if let superview = background.superview {
            self.background.frame = superview.bounds
        }
        
        self.label.frame = self.bounds
        
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
        
//        self.holder.frame = self.bounds
//        self.holder0.frame = self.bounds
        
        self.redrawText()
        self.redrawShape()
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
        
        if vibrancyView != nil {
            self.background.color = UIColor.whiteColor().colorWithAlphaComponent(0.25)
            self.overlay?.hidden = !switchColors
        }
        
        self.underlay.color = UIColor(red: CGFloat(38.6)/CGFloat(255), green: CGFloat(18)/CGFloat(255), blue: CGFloat(39.3)/CGFloat(255), alpha: 0.4)
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
        if self.popup == nil {
            self.layer.zPosition = 1000
            
            var popup = KeyboardKeyBackground(frame: CGRectZero)
            popup.cornerRadius = 9.0
            self.addSubview(popup)
            self.popup = popup
            
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
