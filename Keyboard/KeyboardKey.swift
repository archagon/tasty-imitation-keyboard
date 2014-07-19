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

class KeyboardKey: UIControl {
    
    var keyView: KeyboardKeyBackground
    var popup: KeyboardKeyBackground?
    var connector: KeyboardConnector?
    
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
    
    override var enabled: Bool {
    didSet {
        self.keyView.enabled = enabled
    }
    }
    
    override var selected: Bool {
    didSet {
        self.keyView.selected = selected
    }
    }
    
    override var highlighted: Bool {
    didSet {
//        self.layer.backgroundColor = (highlighted ? UIColor.blueColor().CGColor : UIColor.redColor().CGColor)
        self.keyView.highlighted = highlighted
    }
    }
    
    init(coder aDecoder: NSCoder!) {
        self.keyView = KeyboardKeyBackground(frame: CGRectZero)
        
        super.init(coder: aDecoder)
        
        self.addSubview(self.keyView)
    }
    
    init(frame: CGRect) {
        self.keyView = KeyboardKeyBackground(frame: CGRectZero)
        
        super.init(frame: frame)
        
        self.clipsToBounds = false
        self.addSubview(self.keyView)
        
        let showOptions: UIControlEvents = .TouchDown | .TouchDragInside | .TouchDragEnter
        let hideOptions: UIControlEvents = .TouchUpInside | .TouchUpOutside | .TouchDragOutside
        self.addTarget(self, action: Selector("showPopup"), forControlEvents: showOptions)
        self.addTarget(self, action: Selector("hidePopup"), forControlEvents: hideOptions)
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
    
    override func drawRect(rect: CGRect) {
//        super.drawRect(rect)
    }
    
    func showPopup() {
        if !self.popup {
            let gap = 9

            var popupFrame = CGRectMake(0, 0, 52, 54)

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

            self.popup!.drawBorder = true
            self.keyView.drawBorder = true
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
