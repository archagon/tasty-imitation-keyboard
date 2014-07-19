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

let debugHorizontal = false

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
        
        self.color = UIColor.whiteColor()
        self.underColor = UIColor.grayColor()
        self.borderColor = UIColor.blackColor()
        self.drawUnder = true
        self.drawBorder = false
        self.textColor = UIColor.blackColor()
        
        super.init(frame: frame)
        
        self.clipsToBounds = false
        self.addSubview(self.keyView)
        
        let showOptions: UIControlEvents = .TouchDown | .TouchDragInside | .TouchDragEnter
        let hideOptions: UIControlEvents = .TouchUpInside | .TouchUpOutside | .TouchDragOutside
        
        if model.type == Key.KeyType.Character || model.type == Key.KeyType.Period {
            self.addTarget(self, action: Selector("showPopup"), forControlEvents: showOptions)
            self.addTarget(self, action: Selector("hidePopup"), forControlEvents: hideOptions)
        }
    }
    
//    override func sizeThatFits(size: CGSize) -> CGSize {
//        return super.sizeThatFits(size)
//    }
    
    override func layoutSubviews() {
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
    
    override func drawRect(rect: CGRect) {
//        super.drawRect(rect)
    }
    
    func showPopup() {
        if !self.popup {
            let gap = 9

            var popupFrame = CGRectMake(0, 0, 52, 52)

            if !debugHorizontal {
                popupFrame.origin = CGPointMake(
                    (self.bounds.size.width - popupFrame.size.width)/2.0,
                    -popupFrame.size.height - CGFloat(gap))
            }
            else {
                popupFrame.origin = CGPointMake(
                    self.bounds.size.width + CGFloat(Double(gap) / 2.0),
                    (self.bounds.size.height - popupFrame.size.height)/2.0)
            }
            
            self.layer.zPosition = 1000
            
            self.popup = KeyboardKeyBackground(frame: popupFrame)
            self.popup!.cornerRadius = 9.0
            self.addSubview(self.popup)
            
            self.popup!.text = self.keyView.text
            self.keyView.label.hidden = true
            self.popup!.label.font = self.popup!.label.font.fontWithSize(22 * 2.0)
            
            if !debugHorizontal {
                self.popup!.attach(Direction.Down)
                self.keyView.attach(Direction.Up)
            }
            else {
                self.popup!.attach(Direction.Left)
                self.keyView.attach(Direction.Right)
            }
            
            let kv = self.keyView
            let p = self.popup!

            if !debugHorizontal {
                self.connector = KeyboardConnector(start: kv, end: p, startConnectable: kv, endConnectable: p, startDirection: .Up, endDirection: .Down)
            }
            else {
                self.connector = KeyboardConnector(start: kv, end: p, startConnectable: kv, endConnectable: p, startDirection: .Right, endDirection: .Left)
            }
            self.addSubview(self.connector)
            self.connector!.layer.zPosition = -1

            self.drawBorder = true
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
