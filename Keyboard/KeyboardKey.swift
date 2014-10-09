//
//  KeyboardKey.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// components
//     - large letter popup
//     - if hold, show extra menu — default if finger slides off
//     - translucent buttons
//     - light and dark themes
//     - iPad sizes
//     - iPad slide apart keyboard
//     - JSON-like parsing
//     > storyboard + custom widget
//     > framework

// system bugs
//      - attach() receives incorrect enum when using -O
//      - inability to use class generics without compiler crashes
//      - inability to use method generics without compiler crashes when using -O
//      - framework (?) compiler crashes when using -Ofast

// popup constraints have to be setup with the superview in mind; hence these callbacks
protocol KeyboardKeyProtocol {
    func frameForPopup(key: KeyboardKey, direction: Direction) -> CGRect
    func willShowPopup(key: KeyboardKey, direction: Direction) //may be called multiple times during layout
    func willHidePopup(key: KeyboardKey)
}

class KeyboardKey: UIControl, KeyboardView {
    
    var delegate: KeyboardKeyProtocol?
    
    var keyView: KeyboardKeyBackground
    var popup: KeyboardKeyBackground?
    var connector: KeyboardConnector?
    
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
    
    var text: String! {
        didSet {
            self.redrawText()
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
    
    var vibrancyView: UIVisualEffectView?
    var underlay: KeyboardKeyBackground
    var overlay: KeyboardKeyBackground?
    
    init(vibrancy: Bool) {
        self.keyView = KeyboardKeyBackground(frame: CGRectZero)
        
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
            vibrancyView.contentView.addSubview(self.keyView)
            self.vibrancyView = vibrancyView
        }
        else {
            self.addSubview(self.keyView)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.vibrancyView?.frame = self.bounds
        self.underlay.frame = self.bounds
        if let keyViewSuperview = keyView.superview {
            self.keyView.frame = keyViewSuperview.bounds
        }
        
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
        
        self.keyView.text = ((self.text != nil) ? self.text : "")
    }
    
    func redrawShape() {
        if let shape = self.shape {
            self.text = nil
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
        var keyboardViews: [KeyboardView] = [self.keyView]
        if self.popup != nil { keyboardViews.append(self.popup!) }
        if self.connector != nil { keyboardViews.append(self.connector!) }
        
        var switchColors = self.highlighted || self.selected
        
        self.underlay.hidden = !self.drawUnder
        self.keyView.drawUnder = false
//        self.underlay.hidden = true
//        self.keyView.drawUnder = true
        
        for kv in keyboardViews {
            var keyboardView = kv
            keyboardView.color = (switchColors && self.downColor != nil ? self.downColor! : self.color)
            keyboardView.underColor = (switchColors && self.downUnderColor != nil ? self.downUnderColor! : self.underColor)
            keyboardView.borderColor = (switchColors && self.downBorderColor != nil ? self.downBorderColor! : self.borderColor)
            keyboardView.drawBorder = self.drawBorder
        }
        
        self.keyView.label.textColor = (switchColors && self.downTextColor != nil ? self.downTextColor! : self.textColor)
        if self.popup != nil {
            self.popup!.label.textColor = (switchColors && self.downTextColor != nil ? self.downTextColor! : self.textColor)
        }
        
        if vibrancyView != nil {
            self.keyView.color = UIColor.whiteColor().colorWithAlphaComponent(0.25)
        }
        
        self.underlay.color = UIColor(red: CGFloat(38.6)/CGFloat(255), green: CGFloat(18)/CGFloat(255), blue: CGFloat(39.3)/CGFloat(255), alpha: 0.4)
    }
    
    func layoutPopup(dir: Direction) {
        assert(self.popup != nil, "popup not found")
        
        if let popup = self.popup {
            if let delegate = self.delegate {
                let frame = delegate.frameForPopup(self, direction: dir)
                popup.frame = frame
            }
            else {
                popup.frame = CGRectZero
                popup.center = self.center
            }
        }
    }
    
    func configurePopup(direction: Direction) {
        assert(self.popup != nil, "popup not found")
        
        self.keyView.attach(direction)
        self.popup!.attach(direction.opposite())
        
        let kv = self.keyView
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
            
            self.popup = KeyboardKeyBackground(frame: CGRectZero)
            self.popup!.cornerRadius = 9.0
            self.addSubview(self.popup!)
            
            self.popup!.text = self.keyView.text
            self.keyView.label.hidden = true
            self.popup!.label.font = self.popup!.label.font.fontWithSize(22 * 2.0)
            
//            self.popupDirection = .Up
        }
    }
    
    func hidePopup() {
        if self.popup != nil {
            self.delegate?.willHidePopup(self)
            
            self.connector?.removeFromSuperview()
            self.connector = nil
            
            self.popup?.removeFromSuperview()
            self.popup = nil
            
            self.keyView.label.hidden = false
            self.keyView.attach(nil)
            
            self.keyView.drawBorder = false
            
            self.layer.zPosition = 0
            
            self.popupDirection = nil
        }
    }
}
