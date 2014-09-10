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
    
    var popupDirection: Direction
    var ambiguityTimer: NSTimer! // QQQ:
    var constraintStore: [(UIView, NSLayoutConstraint)] = [] // QQQ:
    
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
        self.popupDirection = Direction.Up
        
        super.init(frame: frame)
        
        self.clipsToBounds = false
        self.keyView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(self.keyView)
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.keyView, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.keyView, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.keyView, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self.keyView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0))
        
        self.ambiguityTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "timerLoop", userInfo: nil, repeats: true)
        
//        self.holder0.contentView.addSubview(self.holder)
//        self.holder0.clipsToBounds = false
//        self.holder0.contentView.clipsToBounds = false
//        self.addSubview(self.holder0)
//        self.holder.contentView.addSubview(self.keyView)
//        self.holder.clipsToBounds = false
//        self.holder.contentView.clipsToBounds = false
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
//    override func sizeThatFits(size: CGSize) -> CGSize {
//        return super.sizeThatFits(size)
//    }
    
//    override func updateConstraints() {
//        
//    }

    func timerLoop() {
        if self.popup != nil && self.popup!.hasAmbiguousLayout() {
            NSLog("exercising ambiguity...")
            self.popup!.exerciseAmbiguityInLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.popup != nil {
            self.popupDirection = Direction.Up
            self.setupPopupConstraints(self.popupDirection)
            self.configurePopup(self.popupDirection)
            super.layoutSubviews()
            
            var upperLeftCorner = self.popup!.frame.origin
            var popupPosition = self.superview!.convertPoint(upperLeftCorner, fromView: self) // TODO: hack
            
//            if popupPosition.y < 0 {
            if self.popup!.bounds.height < 10 {
                if self.frame.origin.x < self.superview!.bounds.width/2 { // TODO: hack
                    self.popupDirection = Direction.Right
                }
                else {
                    self.popupDirection = Direction.Left
                }
                self.setupPopupConstraints(self.popupDirection)
                self.configurePopup(self.popupDirection)
                super.layoutSubviews()
            }
        }
        
//        self.holder.frame = self.bounds
//        self.holder0.frame = self.bounds
        
        self.redrawText()
    }
    
    func redrawText() {
//        self.keyView.frame = self.bounds
//        self.button.frame = self.bounds
//        
//        self.button.setTitle(self.text, forState: UIControlState.Normal)
        
        self.keyView.text = ((self.text != nil) ? self.text : "")
    }
    
    // TODO: StyleKit?
    func updateColors() {
        var keyboardViews: [KeyboardView] = [self.keyView]
        if self.popup != nil { keyboardViews.append(self.popup!) }
        if self.connector != nil { keyboardViews.append(self.connector!) }
        
        var switchColors = self.highlighted || self.selected
        
        for kv in keyboardViews {
            var keyboardView = kv
            keyboardView.color = (switchColors && self.downColor != nil ? self.downColor! : self.color)
            keyboardView.underColor = (switchColors && self.downUnderColor != nil ? self.downUnderColor! : self.underColor)
            keyboardView.borderColor = (switchColors && self.downBorderColor != nil ? self.downBorderColor! : self.borderColor)
            keyboardView.drawUnder = self.drawUnder
            keyboardView.drawBorder = self.drawBorder
        }
        
        self.keyView.label.textColor = (switchColors && self.downTextColor != nil ? self.downTextColor! : self.textColor)
        if self.popup != nil {
            self.popup!.label.textColor = (switchColors && self.downTextColor != nil ? self.downTextColor! : self.textColor)
        }
    }
    
    func setupPopupConstraints(dir: Direction) {
        // TODO: superview optional
        
        assert(self.popup != nil, "popup not found")
        
        for (view, constraint) in self.constraintStore {
            view.removeConstraint(constraint)
        }
        self.constraintStore = []
        
        let gap: CGFloat = 8
        let gapMinimum: CGFloat = 3
       
        // size ratios
        
        // TODO: fix for direction
        
        var widthConstraint = NSLayoutConstraint(
            item: self.popup!,
            attribute: NSLayoutAttribute.Width,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.keyView,
            attribute: NSLayoutAttribute.Width,
            multiplier: 1,
            constant: 26)
        self.constraintStore.append((self, widthConstraint) as (UIView, NSLayoutConstraint))
        
        // TODO: is this order right???
        var heightConstraint = NSLayoutConstraint(
            item: self.popup!,
            attribute: NSLayoutAttribute.Height,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.keyView,
            attribute: NSLayoutAttribute.Height,
            multiplier: -1,
            constant: 94)
        heightConstraint.priority = 750
        self.constraintStore.append((self, heightConstraint) as (UIView, NSLayoutConstraint))
        
        // gap from key
        
        let directionToAttribute = [
            Direction.Up: NSLayoutAttribute.Top,
            Direction.Down: NSLayoutAttribute.Bottom,
            Direction.Left: NSLayoutAttribute.Left,
            Direction.Right: NSLayoutAttribute.Right,
        ]
        
        var gapConstraint = NSLayoutConstraint(
            item: self.keyView,
            attribute: directionToAttribute[dir]!,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.popup,
            attribute: directionToAttribute[dir.opposite()]!,
            multiplier: 1,
            constant: gap)
        gapConstraint.priority = 700
        self.constraintStore.append((self, gapConstraint) as (UIView, NSLayoutConstraint))
        
        var gapMinConstraint = NSLayoutConstraint(
            item: self.keyView,
            attribute: directionToAttribute[dir]!,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.popup,
            attribute: directionToAttribute[dir.opposite()]!,
            multiplier: 1,
            constant: (dir.horizontal() ? -1 : 1) * gapMinimum)
        gapMinConstraint.priority = 1000
        self.constraintStore.append((self, gapMinConstraint) as (UIView, NSLayoutConstraint))
        
        // can't touch top
        
        var cantTouchTopConstraint = NSLayoutConstraint(
            item: self.popup!,
            attribute: directionToAttribute[dir]!,
            relatedBy: (dir == Direction.Right ? NSLayoutRelation.LessThanOrEqual : NSLayoutRelation.GreaterThanOrEqual),
            toItem: self.superview,
            attribute: directionToAttribute[dir]!,
            multiplier: 1,
            constant: 2) // TODO: layout
        cantTouchTopConstraint.priority = 1000
        self.constraintStore.append((self.superview!, cantTouchTopConstraint) as (UIView, NSLayoutConstraint))
        
        if dir.horizontal() {
            var cantTouchTopConstraint = NSLayoutConstraint(
                item: self.popup!,
                attribute: directionToAttribute[Direction.Up]!,
                relatedBy: NSLayoutRelation.GreaterThanOrEqual,
                toItem: self.superview,
                attribute: directionToAttribute[Direction.Up]!,
                multiplier: 1,
                constant: 5) // TODO: layout
            cantTouchTopConstraint.priority = 1000
            self.constraintStore.append((self.superview!, cantTouchTopConstraint) as (UIView, NSLayoutConstraint))
        }
        else {
            var cantTouchSideConstraint = NSLayoutConstraint(
                item: self.superview!,
                attribute: directionToAttribute[Direction.Right]!,
                relatedBy: NSLayoutRelation.GreaterThanOrEqual,
                toItem: self.popup,
                attribute: directionToAttribute[Direction.Right]!,
                multiplier: 1,
                constant: 17) // TODO: layout
            cantTouchSideConstraint.priority = 1000
            var cantTouchSideConstraint2 = NSLayoutConstraint(
                item: self.superview!,
                attribute: directionToAttribute[Direction.Left]!,
                relatedBy: NSLayoutRelation.LessThanOrEqual,
                toItem: self.popup,
                attribute: directionToAttribute[Direction.Left]!,
                multiplier: 1,
                constant: 17) // TODO: layout
            cantTouchSideConstraint2.priority = 1000
            self.constraintStore.append((self.superview!, cantTouchSideConstraint) as (UIView, NSLayoutConstraint))
            self.constraintStore.append((self.superview!, cantTouchSideConstraint2) as (UIView, NSLayoutConstraint))
        }
        
        // centering
        
        var centerConstraint = NSLayoutConstraint(
            item: self.keyView,
            attribute: (dir.horizontal() ? NSLayoutAttribute.CenterY : NSLayoutAttribute.CenterX),
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.popup,
            attribute: (dir.horizontal() ? NSLayoutAttribute.CenterY : NSLayoutAttribute.CenterX),
            multiplier: 1,
            constant: 0)
        centerConstraint.priority = 500
        self.constraintStore.append((self, centerConstraint) as (UIView, NSLayoutConstraint))
        
        for (view, constraint) in self.constraintStore {
            view.addConstraint(constraint)
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
            self.popup!.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.popup!.cornerRadius = 9.0
            self.addSubview(self.popup!)
            
            self.popup!.text = self.keyView.text
            self.keyView.label.hidden = true
            self.popup!.label.font = self.popup!.label.font.fontWithSize(22 * 2.0)
        }
    }
    
    func hidePopup() {
        if self.popup != nil {
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
