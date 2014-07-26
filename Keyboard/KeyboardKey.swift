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

// this is more of a view controller than a view, so we'll let the model stuff slide for now
class KeyboardKey: UIControl, KeyboardView {
    
    let model: Key
    
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
    
    override var enabled: Bool { didSet { updateColors() }}
    override var selected: Bool
    {
    didSet
    {
        updateColors()
    }}
    override var highlighted: Bool
    {
    didSet
    {
        updateColors()
    }}
    
    var text: String! {
    didSet {
        self.redrawText()
    }
    }
    
    override var frame: CGRect {
    didSet {
        self.redrawText()
    }
    }
    
    init(frame: CGRect, model: Key) {
        self.model = model
        self.keyView = KeyboardKeyBackground(frame: CGRectZero)
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
//        self.holder0 = UIVisualEffectView(effect: blurEffect)
//        self.holder = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: blurEffect))
        
        self.color = UIColor.whiteColor()
        self.underColor = UIColor.grayColor()
        self.borderColor = UIColor.blackColor()
        self.drawUnder = true
        self.drawBorder = false
        self.textColor = UIColor.blackColor()
        
        super.init(frame: frame)
        
        self.clipsToBounds = false
        self.addSubview(self.keyView)
        
//        self.holder0.contentView.addSubview(self.holder)
//        self.holder0.clipsToBounds = false
//        self.holder0.contentView.clipsToBounds = false
//        self.addSubview(self.holder0)
//        self.holder.contentView.addSubview(self.keyView)
//        self.holder.clipsToBounds = false
//        self.holder.contentView.clipsToBounds = false
    }
    
//    override func sizeThatFits(size: CGSize) -> CGSize {
//        return super.sizeThatFits(size)
//    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        self.holder.frame = self.bounds
//        self.holder0.frame = self.bounds
        self.redrawText()
    }
    
    func redrawText() {
        self.keyView.frame = self.bounds
//        self.button.frame = self.bounds
        
//        self.button.setTitle(self.text, forState: UIControlState.Normal)
        self.keyView.text = (self.text ? self.text : "")
    }
    
    // TODO: StyleKit?
    func updateColors() {
        var keyboardViews: [KeyboardView] = [self.keyView]
        if self.popup { keyboardViews += self.popup! }
        if self.connector { keyboardViews += self.connector! }
        
        var switchColors = self.highlighted || self.selected
        
        for kv in keyboardViews {
            var keyboardView = kv
            keyboardView.color = (switchColors && self.downColor ? self.downColor! : self.color)
            keyboardView.underColor = (switchColors && self.downUnderColor ? self.downUnderColor! : self.underColor)
            keyboardView.borderColor = (switchColors && self.downBorderColor ? self.downBorderColor! : self.borderColor)
            keyboardView.drawUnder = self.drawUnder
            keyboardView.drawBorder = self.drawBorder
        }
        
        self.keyView.label.textColor = (switchColors && self.downTextColor ? self.downTextColor! : self.textColor)
        if self.popup {
            self.popup!.label.textColor = (switchColors && self.downTextColor ? self.downTextColor! : self.textColor)
        }
    }
    
    func showPopup() {
        if !self.popup {
            var gap: CGFloat = 8
//            var popupFrame = CGRectMake(0, 0, 52, 52)
            var direction: Direction = .Up
            
//            let coordinate = self.keyView.convertPoint(CGPointMake(self.keyView.bounds.width, 0), toView: self.superview)
//            if (coordinate.y - CGFloat(gap) - popupFrame.height) <= 0.0 {
//                gap = 4.5
//                if (coordinate.x + CGFloat(gap) + popupFrame.width) >= self.superview.bounds.width {
//                    direction = Direction.Left
//                }
//                else {
//                    direction = Direction.Right
//                }
//            }
            
//            switch direction {
//            case .Up:
//                popupFrame.origin = CGPointMake(
//                    (self.bounds.size.width - popupFrame.size.width)/2.0,
//                    -popupFrame.size.height - CGFloat(gap))
//            case .Right:
//                popupFrame.origin = CGPointMake(
//                    self.bounds.size.width + CGFloat(gap),
//                    (self.bounds.size.height - popupFrame.size.height)/2.0)
//            case .Left:
//                popupFrame.origin = CGPointMake(
//                    CGFloat(0.0) - CGFloat(gap) - popupFrame.width,
//                    (self.bounds.size.height - popupFrame.size.height)/2.0)
//            case .Down:
//                assert(false, "can't show down yet")
//            }
            
            self.layer.zPosition = 1000
            
            self.popup = KeyboardKeyBackground(frame: CGRectZero)
            self.popup!.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.popup!.cornerRadius = 9.0
            self.addSubview(self.popup)
            
            self.addConstraint(NSLayoutConstraint(
                item: self.popup,
                attribute: NSLayoutAttribute.Width,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.keyView,
                attribute: NSLayoutAttribute.Width,
                multiplier: 1,
                constant: 26))

            // TODO: is this order right???
            self.addConstraint(NSLayoutConstraint(
                item: self.popup,
                attribute: NSLayoutAttribute.Height,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.keyView,
                attribute: NSLayoutAttribute.Height,
                multiplier: -1,
                constant: 94))
            
            self.addConstraint(NSLayoutConstraint(
                item: self.keyView,
                attribute: NSLayoutAttribute.Top,
                relatedBy: NSLayoutRelation.LessThanOrEqual,
                toItem: self.popup,
                attribute: NSLayoutAttribute.Bottom,
                multiplier: 1,
                constant: gap))
            
            self.superview.addConstraint(NSLayoutConstraint(
                item: self.popup,
                attribute: NSLayoutAttribute.Top,
                relatedBy: NSLayoutRelation.GreaterThanOrEqual,
                toItem: self.superview,
                attribute: NSLayoutAttribute.Top,
                multiplier: 1,
                constant: 0))
            
            self.addConstraint(NSLayoutConstraint(
                item: self.keyView,
                attribute: NSLayoutAttribute.CenterX,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.popup,
                attribute: NSLayoutAttribute.CenterX,
                multiplier: 1,
                constant: 0))
            
            self.popup!.text = self.keyView.text
            self.keyView.label.hidden = true
            self.popup!.label.font = self.popup!.label.font.fontWithSize(22 * 2.0)
            
            self.keyView.attach(direction)
            self.popup!.attach(direction.opposite())
            
            let kv = self.keyView
            let p = self.popup!

            self.connector = KeyboardConnector(start: kv, end: p, startConnectable: kv, endConnectable: p, startDirection: direction, endDirection: direction.opposite())
            self.addSubview(self.connector)
            self.connector!.layer.zPosition = -1

            self.drawBorder = true
            
            if direction == Direction.Up {
                self.popup!.drawUnder = false
                self.connector!.drawUnder = false
            }
        }
    }
    
    func hidePopup() {
        if self.popup {
            self.connector?.removeFromSuperview()
            self.connector = nil
            
            self.popup?.removeFromSuperview()
            self.popup = nil
            
            self.keyView.label.hidden = false
            self.keyView.attach(nil)
            
            self.keyView.drawBorder = false
            
            self.layer.zPosition = 0
        }
    }
}
