//
//  KeyboardLayout.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/25/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

var DEBUG_SHOW_SPACERS = false

let layout: [String:Double] = [
    "leftGap": 3,
    "rightGap": 3,
    "topGap": 9,
    "bottomGap": 7,
    "keyWidth": 26,
    "keyHeight": 39,
    "popupKeyHeight": 53,
    "keyGap": 6, // 5 for russian, though still 6 on lower row
    "shiftAndBackspaceMaxWidth": 36,
    "specialKeyWidth": 34,
    "doneKeyWidth": 50,
    //    "spaceWidth": 138,
    "debugWidth": (DEBUG_SHOW_SPACERS ? 2 : 0)
]

let colors: [String:UIColor] = [
    "lightColor": UIColor.whiteColor(),
    "lightShadowColor": UIColor(hue: (220/360.0), saturation: 0.04, brightness: 0.56, alpha: 1),
    "lightTextColor": UIColor.blackColor(),
    "darkColor": UIColor(hue: (217/360.0), saturation: 0.09, brightness: 0.75, alpha: 1),
    "darkShadowColor": UIColor(hue: (220/360.0), saturation: 0.04, brightness: 0.56, alpha: 1),
    "darkTextColor": UIColor.whiteColor(),
    "blueColor": UIColor(hue: (211/360.0), saturation: 1.0, brightness: 1.0, alpha: 1),
    "blueShadowColor": UIColor(hue: (216/360.0), saturation: 0.05, brightness: 0.43, alpha: 1),
    "borderColor": UIColor(hue: (214/360.0), saturation: 0.04, brightness: 0.65, alpha: 1.0)
]

// shift/backspace: 72x78, but shrinks to 48x78
// lower row: 68x78, 100x78, 276

class KeyboardLayout {
    
    private var model: Keyboard
    private var superview: UIView
    private var modelToView: [Key:KeyboardKey] = [:]
    private var viewToModel: [KeyboardKey:Key] = [:]
    private var elements: [String:UIView] = [:]
    
    init(model: Keyboard, superview: UIView) {
        self.model = model
        self.superview = superview
    }
    
    func initialize() {
        self.elements["superview"] = self.superview
        
        self.createViews(self.model)
        
        // TODO: autolayout class that can optionally "bake" values?
        self.addEdgeConstraints()
        self.createRowGapConstraints(self.model)
        self.createKeyGapConstraints(self.model)
        self.createKeyConstraints(self.model)
    }
    
    func viewForKey(model: Key) -> KeyboardKey? {
        return self.modelToView[model]
    }
    
    func keyForView(key: KeyboardKey) -> Key? {
        return self.viewToModel[key]
    }
    
    /*
    Everything here relies on a simple naming convention.
    
    The rows of the keyboard have invisible spacer rows between them.
    There are also invisible spacer rows on the top and bottom of the keyboard.
    These are all labeled "rowGap<y>", where 0 <= y <= row count.
    
    Similarly, there are invisible spacer gaps between every key.
    There are also invisible gaps at the start and end of every row.
    These are labeled "keyGap<x>x<y>, where 0 <= x <= key count and y <= 0 < row count.
    
    The keys are labeled "key<x>x<y>".
    */
    
    private func setColorsForKey(key: KeyboardKey, model: Key) {
        switch model.type {
        case
        Key.KeyType.Character,
        Key.KeyType.SpecialCharacter,
        Key.KeyType.Period:
            key.color = colors["lightColor"]!
            key.underColor = colors["lightShadowColor"]!
            key.borderColor = colors["borderColor"]!
            key.textColor = colors["lightTextColor"]!
        case
        Key.KeyType.Space:
            key.color = colors["lightColor"]!
            key.underColor = colors["lightShadowColor"]!
            key.borderColor = colors["borderColor"]!
            key.textColor = colors["lightTextColor"]!
            key.downColor = colors["darkColor"]!
        case
        Key.KeyType.Shift,
        Key.KeyType.Backspace:
            key.color = colors["darkColor"]!
            key.underColor = colors["darkShadowColor"]!
            key.borderColor = colors["borderColor"]!
            key.textColor = colors["darkTextColor"]!
            key.downColor = colors["lightColor"]!
            key.downUnderColor = colors["lightShadowColor"]!
            key.downTextColor = colors["lightTextColor"]!
        case
        Key.KeyType.ModeChange:
            key.color = colors["darkColor"]!
            key.underColor = colors["darkShadowColor"]!
            key.borderColor = colors["borderColor"]!
            key.textColor = colors["lightTextColor"]!
        case
        Key.KeyType.Return,
        Key.KeyType.KeyboardChange:
            key.color = colors["darkColor"]!
            key.underColor = colors["darkShadowColor"]!
            key.borderColor = colors["borderColor"]!
            key.textColor = colors["lightTextColor"]!
            key.downColor = colors["lightColor"]!
            key.downUnderColor = colors["lightShadowColor"]!
        }
    }
    
    private func createViews(keyboard: Keyboard) {
        let numRows = keyboard.rows.count
        
        for i in 0...numRows {
            var rowGap = Spacer(color: ((i == 0 || i == numRows) ? UIColor.purpleColor() : UIColor.yellowColor()))
            let rowGapName = "rowGap\(i)"
            rowGap.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.elements[rowGapName] = rowGap
            self.superview.addSubview(rowGap)
            
            if (i < numRows) {
                let numKeys = keyboard.rows[i].count
                
                for j in 0...numKeys {
                    var keyGap = Spacer(color: UIColor.blueColor())
                    let keyGapName = "keyGap\(j)x\(i)"
                    keyGap.setTranslatesAutoresizingMaskIntoConstraints(false)
                    
                    self.elements[keyGapName] = keyGap
                    self.superview.addSubview(keyGap)
                    
                    if (j < numKeys) {
                        var key = keyboard.rows[i][j]
                        
                        var keyView = KeyboardKey(frame: CGRectZero, model: key) // TODO:
                        let keyViewName = "key\(j)x\(i)"
                        keyView.enabled = true
                        keyView.setTranslatesAutoresizingMaskIntoConstraints(false)
                        keyView.text = key.keyCap
                        
                        self.superview.addSubview(keyView)
                        
                        self.elements[keyViewName] = keyView
                        self.modelToView[key] = keyView
                        self.viewToModel[keyView] = key
                        
                        setColorsForKey(keyView, model: key)
                        
                        // font sizing
                        switch key.type {
                        case
                        Key.KeyType.ModeChange,
                        Key.KeyType.Space,
                        Key.KeyType.Return:
                            keyView.keyView.label.adjustsFontSizeToFitWidth = false
                            keyView.keyView.label.minimumScaleFactor = 0.1
                            keyView.keyView.label.font = keyView.keyView.label.font.fontWithSize(16)
                        default:
                            break
                        }
                    }
                }
            }
        }
    }
    
    private func centerItems(item1: UIView, item2: UIView, vertical: Bool) {
        self.superview.addConstraint(NSLayoutConstraint(
            item: item1,
            attribute: (vertical ? NSLayoutAttribute.CenterX : NSLayoutAttribute.CenterY),
            relatedBy: NSLayoutRelation.Equal,
            toItem: item2,
            attribute: (vertical ? NSLayoutAttribute.CenterX : NSLayoutAttribute.CenterY),
            multiplier: 1,
            constant: 0))
    }
    
    private func addGapPair(nameFormat: String, row: Int, startIndex: Int, endIndex: Int, leftAnchor: String?, rightAnchor: String?, vertical: Bool, width: String?) {
        var allConstraints: Array<String> = []
        
        var leftGapName = String(format: nameFormat, startIndex, row)
        var rightGapName = String(format: nameFormat, endIndex, row)
        
        var verticalFlag = (vertical ? "V:" : "")
        var inverseVerticalFlag = (!vertical ? "V:" : "")
        
        // anchoring
        
        if leftAnchor {
            allConstraints += "\(verticalFlag)[\(leftAnchor!)][\(leftGapName)]"
        }
        
        if rightAnchor {
            allConstraints += "\(verticalFlag)[\(rightGapName)][\(rightAnchor!)]"
        }
        
        // size and centering
        
        if width {
            allConstraints += "\(verticalFlag)[\(leftGapName)(\(width!))]"
        }
        
        allConstraints += "\(verticalFlag)[\(rightGapName)(\(leftGapName))]"
        
        allConstraints += "\(inverseVerticalFlag)[\(leftGapName)(debugWidth)]"
        allConstraints += "\(inverseVerticalFlag)[\(rightGapName)(debugWidth)]"
        
        if vertical {
            centerItems(self.elements[leftGapName]!, item2: self.elements["superview"]!, vertical: true)
            centerItems(self.elements[rightGapName]!, item2: self.elements["superview"]!, vertical: true)
        }
        else {
            centerItems(self.elements[leftGapName]!, item2: self.elements["key\(0)x\(row)"]!, vertical: false)
            centerItems(self.elements[rightGapName]!, item2: self.elements["key\(0)x\(row)"]!, vertical: false)
        }
        
        for constraint in allConstraints {
            let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                constraint,
                options: NSLayoutFormatOptions(0),
                metrics: layout,
                views: elements)
            self.superview.addConstraints(generatedConstraints)
        }
    }
    
    private func addGapsInRange(nameFormat: String, row: Int, startIndex: Int, endIndex: Int, vertical: Bool, width: String?) {
        var allConstraints: Array<String> = []
        
        var firstGapName = String(format: nameFormat, startIndex, row)
        
        var verticalFlag = (vertical ? "V:" : "")
        var inverseVerticalFlag = (!vertical ? "V:" : "")
        
        if width {
            allConstraints +=  "\(verticalFlag)[\(firstGapName)(\(width!))]"
        }
        
        for i in startIndex...endIndex {
            var gapName = String(format: nameFormat, i, row)
            
            // size and centering
            
            if i > 0 {
                allConstraints += "\(verticalFlag)[\(gapName)(\(firstGapName))]"
            }
            
            allConstraints += "\(inverseVerticalFlag)[\(gapName)(debugWidth)]"
            
            if vertical {
                centerItems(self.elements[gapName]!, item2: self.elements["superview"]!, vertical: true)
            }
            else {
                centerItems(self.elements[gapName]!, item2: self.elements["key\(0)x\(row)"]!, vertical: false)
            }
        }
        
        for constraint in allConstraints {
            let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                constraint,
                options: NSLayoutFormatOptions(0),
                metrics: layout,
                views: elements)
            self.superview.addConstraints(generatedConstraints)
        }
    }
    
    private func addEdgeConstraints() {
        let spacers = [
            "leftSpacer": Spacer(color: UIColor.redColor()),
            "rightSpacer": Spacer(color: UIColor.redColor()),
            "topSpacer": Spacer(color: UIColor.redColor()),
            "bottomSpacer": Spacer(color: UIColor.redColor())]
        
        // basic setup
        for (name, spacer) in spacers {
            spacer.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.elements[name] = spacer
            self.superview.addSubview(spacer)
        }
        
        let constraints = [
            // left/right spacers
            "|[leftSpacer(leftGap)]",
            "[rightSpacer(rightGap)]|",
            "V:[leftSpacer(debugWidth)]",
            "V:[rightSpacer(debugWidth)]",
            
            // top/bottom spacers
            "V:|[topSpacer(topGap)]",
            "V:[bottomSpacer(bottomGap)]|",
            "[topSpacer(debugWidth)]",
            "[bottomSpacer(debugWidth)]"]
        
        // edge constraints
        for constraint in constraints {
            let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                constraint,
                options: NSLayoutFormatOptions(0),
                metrics: layout,
                views: elements)
            self.superview.addConstraints(generatedConstraints)
        }
        
        // centering constraints
        for (name, spacer) in spacers {
            if (name.hasPrefix("left") || name.hasPrefix("right")) {
                self.superview.addConstraint(NSLayoutConstraint(
                    item: spacer,
                    attribute: NSLayoutAttribute.CenterY,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.superview,
                    attribute: NSLayoutAttribute.CenterY,
                    multiplier: 1,
                    constant: 0))
            }
            else if (name.hasPrefix("top") || name.hasPrefix("bottom")) {
                self.superview.addConstraint(NSLayoutConstraint(
                    item: spacer,
                    attribute: NSLayoutAttribute.CenterX,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.superview,
                    attribute: NSLayoutAttribute.CenterX,
                    multiplier: 1,
                    constant: 0))
            }
        }
    }
    
    private func createRowGapConstraints(keyboard: Keyboard) {
        self.addGapPair(
            "rowGap%d",
            row: 0,
            startIndex: 0,
            endIndex: keyboard.rows.count,
            leftAnchor: "topSpacer",
            rightAnchor: "bottomSpacer",
            vertical: true,
            width: "0")
        self.addGapsInRange("rowGap%d",
            row: 0,
            startIndex: 1,
            endIndex: keyboard.rows.count - 1,
            vertical: true,
            width: ">=5@50")
    }
    
    // TODO: make this a single constraint string??
    private func createKeyGapConstraints(keyboard: Keyboard) {
        for i in 0..<keyboard.rows.count {
            // TODO: both of these should be determined based on the model data, not the row #
            let isSideButtonRow = (i == 2)
            let isEquallySpacedRow = (i == 3)
            let rowsCount = keyboard.rows[i].count
            
            if isSideButtonRow {
                addGapPair(
                    "keyGap%dx%d",
                    row: i,
                    startIndex: 0,
                    endIndex: rowsCount,
                    leftAnchor: "leftSpacer",
                    rightAnchor: "rightSpacer",
                    vertical: false,
                    width: "0")
                addGapPair(
                    "keyGap%dx%d",
                    row: i,
                    startIndex: 1,
                    endIndex: rowsCount - 1,
                    leftAnchor: nil,
                    rightAnchor: nil,
                    vertical: false,
                    width: nil)
                let keyGap = layout["keyGap"]!
                addGapsInRange(
                    "keyGap%dx%d",
                    row: i,
                    startIndex: 2,
                    endIndex: rowsCount - 2,
                    vertical: false,
                    width: "\(keyGap)")
            }
            else if isEquallySpacedRow {
                addGapPair(
                    "keyGap%dx%d",
                    row: i,
                    startIndex: 0,
                    endIndex: keyboard.rows[i].count,
                    leftAnchor: "leftSpacer",
                    rightAnchor: "rightSpacer",
                    vertical: false,
                    width: "0")
                addGapsInRange(
                    "keyGap%dx%d",
                    row: i,
                    startIndex: 1,
                    endIndex: rowsCount - 1,
                    vertical: false,
                    width: "7") // TODO:
            }
            else {
                addGapPair(
                    "keyGap%dx%d",
                    row: i,
                    startIndex: 0,
                    endIndex: rowsCount,
                    leftAnchor: "leftSpacer",
                    rightAnchor: "rightSpacer",
                    vertical: false,
                    width: nil)
                let keyGap = layout["keyGap"]!
                addGapsInRange(
                    "keyGap%dx%d",
                    row: i,
                    startIndex: 1,
                    endIndex: rowsCount - 1,
                    vertical: false,
                    width: "\(keyGap)")
            }
        }
    }
    
    private func createKeyConstraints(keyboard: Keyboard) {
        var allConstraints: Array<String> = []
        
        let hasPeriod = false
        let canonicalKey = elements["key0x0"]
        var canonicalSpecialSameWidth: String? = nil
        
        // setup special widths
        for i in 0..<keyboard.rows.count {
            for j in 0..<keyboard.rows[i].count {
                let keyModel = keyboard.rows[i][j]
                let keyName = "key\(j)x\(i)"
                
                if keyModel.type == Key.KeyType.ModeChange
                    || keyModel.type == Key.KeyType.KeyboardChange
                    || keyModel.type == Key.KeyType.Period {
                        if !canonicalSpecialSameWidth {
                            canonicalSpecialSameWidth = keyName
                            let widthConstraint = NSLayoutConstraint(
                                item: self.elements[keyName]!,
                                attribute: NSLayoutAttribute.Width,
                                relatedBy: NSLayoutRelation.Equal,
                                toItem: self.elements["superview"]!,
                                attribute: NSLayoutAttribute.Width,
                                multiplier: CGFloat(0.0645),
                                constant: CGFloat(13.37))
                            self.superview.addConstraint(widthConstraint)
                        } else {
                            allConstraints += "[\(keyName)(\(canonicalSpecialSameWidth!))]"
                        }
                }
            }
        }
        
        // setup return key
        for i in 0..<keyboard.rows.count {
            for j in 0..<keyboard.rows[i].count {
                let keyModel = keyboard.rows[i][j]
                let keyName = "key\(j)x\(i)"
                
                if keyModel.type == Key.KeyType.Return {
                    assert(canonicalSpecialSameWidth, "canonical special key not found")
                    let widthConstraint = NSLayoutConstraint(
                        item: self.elements[keyName]!,
                        attribute: NSLayoutAttribute.Width,
                        relatedBy: NSLayoutRelation.Equal,
                        toItem: self.elements[canonicalSpecialSameWidth!]!,
                        attribute: NSLayoutAttribute.Width,
                        multiplier: CGFloat(2.0625),
                        constant: CGFloat(3.875))
                    self.superview.addConstraint(widthConstraint)
                }
            }
        }
        
        for i in 0..<keyboard.rows.count {
            let canonicalRowKey = elements["key0x\(i)"]
            
            for j in 0..<keyboard.rows[i].count {
                let keyModel = keyboard.rows[i][j]
                
                let keyName = "key\(j)x\(i)"
                let key = self.elements[keyName]
                
                let isCanonicalKey = (key == canonicalKey) // TODO:
                let isCanonicalRowKey = (key == canonicalRowKey) // TODO:
                
                allConstraints += "[keyGap\(j)x\(i)][\(keyName)][keyGap\(j+1)x\(i)]"
                
                // only the canonical key has a constant width
                if isCanonicalKey {
                    let keyWidth = layout["keyWidth"]!
                    allConstraints += "[\(keyName)(\(keyWidth)@19)]"
                    allConstraints += "[\(keyName)(\(keyWidth*2)@20)]"
                    allConstraints += "V:[\(keyName)(<=keyHeight@100,>=5@100)]"
                }
                else {
                    // all keys are the same height
                    allConstraints += "V:[\(keyName)(key0x0)]"
                    
                    switch keyModel.type {
                    case Key.KeyType.Character:
                        var constraint0 = NSLayoutConstraint(
                            item: key,
                            attribute: NSLayoutAttribute.Width,
                            relatedBy: NSLayoutRelation.Equal,
                            toItem: canonicalKey,
                            attribute: NSLayoutAttribute.Width,
                            multiplier: 1,
                            constant: 0)
                        self.superview.addConstraint(constraint0)
                    case Key.KeyType.Shift, Key.KeyType.Backspace:
                        let shiftAndBackspaceMaxWidth = layout["shiftAndBackspaceMaxWidth"]!
                        let keyWidth = layout["keyWidth"]!
                        var constraint = NSLayoutConstraint(
                            item: key,
                            attribute: NSLayoutAttribute.Width,
                            relatedBy: NSLayoutRelation.Equal,
                            toItem: canonicalKey,
                            attribute: NSLayoutAttribute.Width,
                            multiplier: CGFloat(shiftAndBackspaceMaxWidth/keyWidth),
                            constant: 0)
                        self.superview.addConstraint(constraint)
                    default:
                        break
                    }
                }
                
                if isCanonicalRowKey {
                    allConstraints += "V:[rowGap\(i)][\(keyName)][rowGap\(i+1)]"
                }
                else {
                    self.centerItems(key!, item2: canonicalRowKey!, vertical: false)
                }
            }
        }
        
        for constraint in allConstraints {
            let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                constraint,
                options: NSLayoutFormatOptions(0),
                metrics: layout,
                views: elements)
            self.superview.addConstraints(generatedConstraints)
        }
    }

    private class Spacer: UIView {
        init(frame: CGRect) {
            super.init(frame: frame)
            
            self.hidden = true
            self.userInteractionEnabled = false
        }
        convenience init() {
            return self.init(frame: CGRectZero)
        }
        convenience init(color: UIColor) {
            self.init()
            
            if DEBUG_SHOW_SPACERS {
                self.layer.backgroundColor = color.CGColor
                self.hidden = false
            }
        }
        //    override class func requiresConstraintBasedLayout() -> Bool {
        //        return true
        //    }
    }
}