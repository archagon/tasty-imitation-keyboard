//
//  KeyboardLayout.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/25/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

var DEBUG_SHOW_SPACERS = false

// TODO: create class from layout dictionary?

let globalLayout: [String:Double] = [
    "leftGap": 3,
    "rightGap": 3,
    "topBanner": 0,
    "topGap": 12,
    "bottomGap": 3,
    "keyWidthRatio": (26 / 320.0),
    "keyHeightRatio": (39 / 216.0),
    "landscapeKeyWidthRatio": (52 / 568.0),
    "landscapeKeyHeightRatio": (33 / 162.0),
    "popupKeyHeight": 53,
    "keyGap": 6, // 5 for russian, though still 6 on lower row
    "shiftAndBackspaceMaxWidth": 36,
    "specialKeyWidth": 34,
    "doneKeyWidth": 50,
    //    "spaceWidth": 138,
    "debugWidth": (DEBUG_SHOW_SPACERS ? 2 : 0)
]

// 216; 162

let globalColors: [String:UIColor] = [
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
    
    dynamic var colors: [String:UIColor] {
        get {
            return globalColors
        }
    }
    dynamic var layout: [String:Double] {
        get {
            return globalLayout
        }
    }
    
    private var model: Keyboard
    private var superview: UIView
    var modelToView: [Key:KeyboardKey] = [:]
    var viewToModel: [KeyboardKey:Key] = [:]
    private var elements: [String:UIView] = [:]
    
    var allConstraints: [String] = []
    var allConstraintObjects: [NSLayoutConstraint] = []
    
    private var initialized: Bool
    
    private var keyWidthConstraint: NSLayoutConstraint!
    private var keyHeightConstraint: NSLayoutConstraint!
    
    init(model: Keyboard, superview: UIView) {
        self.initialized = false
        self.model = model
        self.superview = superview
    }
    
    func initialize() {
        assert(!self.initialized, "already initialized")
        
        self.elements["superview"] = self.superview
        self.createViews(self.model)
        self.setupConstraints()
        
        self.initialized = true
    }
    
    func setupConstraints() {
        // TODO: autolayout class that can optionally "bake" values?
        self.addEdgeConstraints()
        self.createRowGapConstraints(self.model)
        self.createKeyGapConstraints(self.model)
        self.createKeyConstraints(self.model)
        
        var generatedConstraints: [AnyObject] = []
        let dictMetrics: [NSObject: AnyObject] = self.layout
        let dictElements: [NSObject: AnyObject] = self.elements
        
        for constraint in self.allConstraints {
            let constraints = NSLayoutConstraint.constraintsWithVisualFormat(
                constraint,
                options: NSLayoutFormatOptions(0),
                metrics: dictMetrics,
                views: dictElements)
            generatedConstraints += constraints
        }
        self.superview.addConstraints(generatedConstraints)
        self.allConstraintObjects += (generatedConstraints as [NSLayoutConstraint])
    }
    
    func updateForOrientation(portrait: Bool) {
        assert(self.initialized, "not initialized")
        
        var widthConstraint: NSLayoutConstraint = self.keyWidthConstraint
        var heightConstraint: NSLayoutConstraint = self.keyHeightConstraint
        
        if portrait {
            self.updateConstraintMultiplier(&widthConstraint, multiplier: CGFloat(layout["keyWidthRatio"]!))
            self.updateConstraintMultiplier(&heightConstraint, multiplier: CGFloat(layout["keyHeightRatio"]!))
        }
        else {
            self.updateConstraintMultiplier(&widthConstraint, multiplier: CGFloat(layout["landscapeKeyWidthRatio"]!))
            self.updateConstraintMultiplier(&heightConstraint, multiplier: CGFloat(layout["landscapeKeyHeightRatio"]!))
        }
        
        self.keyWidthConstraint = widthConstraint
        self.keyHeightConstraint = heightConstraint
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
    These are all labeled "rowGap<y>p<n>", where 0 <= y <= row count and n is the page number.
    
    Similarly, there are invisible spacer gaps between every key.
    There are also invisible gaps at the start and end of every row.
    These are labeled "keyGap<x>x<y>p<n>, where 0 <= x <= key count and y <= 0 < row count and n is the page number.
    
    The keys are labeled "key<x>x<y>p<n>".
    */
    
    private func updateConstraintMultiplier(inout constraint: NSLayoutConstraint, multiplier: CGFloat) {
        // TODO: generalize
        constraint.secondItem?.removeConstraint(constraint)
//        constraint.secondItem?.removeConstraint(constraint)
        
        let constraintIndex = find(self.allConstraintObjects, constraint)
        if constraintIndex != nil { self.allConstraintObjects.removeAtIndex(constraintIndex!) }
        
        let newConstraint = NSLayoutConstraint(
            item: constraint.firstItem,
            attribute: constraint.firstAttribute,
            relatedBy: constraint.relation,
            toItem: constraint.secondItem,
            attribute: constraint.secondAttribute,
            multiplier: multiplier,
            constant: constraint.constant)
        newConstraint.priority = constraint.priority
        
        constraint.secondItem?.addConstraint(newConstraint)
        
        constraint = newConstraint
    }
    
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
        for (h, page) in enumerate(keyboard.pages) {
            let numRows = page.rows.count
            
            for i in 0...numRows {
                var rowGap = Spacer(color: ((i == 0 || i == numRows) ? UIColor.purpleColor() : UIColor.yellowColor()))
                let rowGapName = "rowGap\(i)p\(h)"
                rowGap.setTranslatesAutoresizingMaskIntoConstraints(false)
                self.elements[rowGapName] = rowGap
                self.superview.addSubview(rowGap)
                
                if (i < numRows) {
                    let numKeys = page.rows[i].count
                    
                    for j in 0...numKeys {
                        var keyGap = Spacer(color: UIColor.blueColor())
                        let keyGapName = "keyGap\(j)x\(i)p\(h)"
                        keyGap.setTranslatesAutoresizingMaskIntoConstraints(false)
                        
                        self.elements[keyGapName] = keyGap
                        self.superview.addSubview(keyGap)
                        
                        if (j < numKeys) {
                            var key = page.rows[i][j]
                            
                            var keyView = KeyboardKey(frame: CGRectZero, model: key) // TODO:
                            let keyViewName = "key\(j)x\(i)p\(h)"
                            keyView.enabled = true
                            keyView.setTranslatesAutoresizingMaskIntoConstraints(false)
                            keyView.text = key.lowercaseKeyCap
                            
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
    }
    
    private func centerItems(item1: UIView, item2: UIView, vertical: Bool) {
        let constraint = NSLayoutConstraint(
            item: item1,
            attribute: (vertical ? NSLayoutAttribute.CenterX : NSLayoutAttribute.CenterY),
            relatedBy: NSLayoutRelation.Equal,
            toItem: item2,
            attribute: (vertical ? NSLayoutAttribute.CenterX : NSLayoutAttribute.CenterY),
            multiplier: 1,
            constant: 0)
        self.superview.addConstraint(constraint)
        self.allConstraintObjects.append(constraint)
    }
    
    private func addGapPair(nameFormat: String, page: Int, row: Int?, startIndex: Int, endIndex: Int, leftAnchor: String?, rightAnchor: String?, vertical: Bool, width: String?) {
        var allConstraints: [String] = []
        let rowConstraint = (row == nil)
        
        var leftGapName = (rowConstraint ? String(format: nameFormat, startIndex, page) : String(format: nameFormat, startIndex, row!, page))
        var rightGapName = (rowConstraint ? String(format: nameFormat, endIndex, page) : String(format: nameFormat, endIndex, row!, page))
        
        var verticalFlag = (vertical ? "V:" : "")
        var inverseVerticalFlag = (!vertical ? "V:" : "")
        
        // anchoring
        
        if leftAnchor != nil {
            allConstraints.append("\(verticalFlag)[\(leftAnchor!)][\(leftGapName)]")
        }
        
        if rightAnchor != nil {
            allConstraints.append("\(verticalFlag)[\(rightGapName)][\(rightAnchor!)]")
        }
        
        // size and centering
        
        if width != nil {
            allConstraints.append("\(verticalFlag)[\(leftGapName)(\(width!))]")
        }
        
        allConstraints.append("\(verticalFlag)[\(rightGapName)(\(leftGapName))]")
        
        allConstraints.append("\(inverseVerticalFlag)[\(leftGapName)(debugWidth)]")
        allConstraints.append("\(inverseVerticalFlag)[\(rightGapName)(debugWidth)]")
        
        if vertical {
            centerItems(self.elements[leftGapName]!, item2: self.elements["superview"]!, vertical: true)
            centerItems(self.elements[rightGapName]!, item2: self.elements["superview"]!, vertical: true)
        }
        else {
            assert(rowConstraint == false)
            centerItems(self.elements[leftGapName]!, item2: self.elements["key\(0)x\(row!)p\(page)"]!, vertical: false)
            centerItems(self.elements[rightGapName]!, item2: self.elements["key\(0)x\(row!)p\(page)"]!, vertical: false)
        }
        
        self.allConstraints += allConstraints
    }
    
    private func addGapsInRange(nameFormat: String, page: Int, row: Int?, startIndex: Int, endIndex: Int, vertical: Bool, width: String?) {
        var allConstraints: [String] = []
        let rowConstraint = (row == nil)
        
        var firstGapName = (rowConstraint ? String(format: nameFormat, startIndex, page) : String(format: nameFormat, startIndex, row!, page))
        
        var verticalFlag = (vertical ? "V:" : "")
        var inverseVerticalFlag = (!vertical ? "V:" : "")
        
        if width != nil {
            allConstraints.append("\(verticalFlag)[\(firstGapName)(\(width!))]")
        }
        
        for i in startIndex...endIndex {
            var gapName = (rowConstraint ? String(format: nameFormat, i, page) : String(format: nameFormat, i, row!, page))
            
            // size and centering
            
            if i > 0 {
                allConstraints.append("\(verticalFlag)[\(gapName)(\(firstGapName))]")
            }
            
            allConstraints.append("\(inverseVerticalFlag)[\(gapName)(debugWidth)]")
            
            if vertical {
                centerItems(self.elements[gapName]!, item2: self.elements["superview"]!, vertical: true)
            }
            else {
                assert(rowConstraint == false)
                centerItems(self.elements[gapName]!, item2: self.elements["key\(0)x\(row!)p\(page)"]!, vertical: false)
            }
        }
        
        self.allConstraints += allConstraints
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
        
        let total: CGFloat = CGFloat(layout["topBanner"]! + layout["topGap"]!)
        let constraints = [
            // left/right spacers
            "|[leftSpacer(leftGap)]",
            "[rightSpacer(rightGap)]|",
            "V:[leftSpacer(debugWidth)]",
            "V:[rightSpacer(debugWidth)]",
            
            // top/bottom spacers
            "V:|[topSpacer(\(total))]",
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
            self.allConstraintObjects += (generatedConstraints as [NSLayoutConstraint])
        }
        
        // centering constraints
        for (name, spacer) in spacers {
            if (name.hasPrefix("left") || name.hasPrefix("right")) {
                let constraint = NSLayoutConstraint(
                    item: spacer,
                    attribute: NSLayoutAttribute.CenterY,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.superview,
                    attribute: NSLayoutAttribute.CenterY,
                    multiplier: 1,
                    constant: 0)
                self.superview.addConstraint(constraint)
                self.allConstraintObjects.append(constraint)
            }
            else if (name.hasPrefix("top") || name.hasPrefix("bottom")) {
                let constraint = NSLayoutConstraint(
                    item: spacer,
                    attribute: NSLayoutAttribute.CenterX,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.superview,
                    attribute: NSLayoutAttribute.CenterX,
                    multiplier: 1,
                    constant: 0)
                self.superview.addConstraint(constraint)
                self.allConstraintObjects.append(constraint)
            }
        }
        
        return
    }
    
    private func createRowGapConstraints(keyboard: Keyboard) {
        for (h, page) in enumerate(keyboard.pages) {
            self.addGapPair(
                "rowGap%dp%d",
                page: h,
                row: nil,
                startIndex: 0,
                endIndex: page.rows.count,
                leftAnchor: "topSpacer",
                rightAnchor: "bottomSpacer",
                vertical: true,
                width: "0")
            
            if page.rows.count >= 2 {
                self.addGapsInRange("rowGap%dp%d",
                    page: h,
                    row: nil,
                    startIndex: 1,
                    endIndex: page.rows.count - 1,
                    vertical: true,
                    width: ">=5@50")
            }
        }
    }
    
    // TODO: make this a single constraint string??
    private func createKeyGapConstraints(keyboard: Keyboard) {
        for (h, page) in enumerate(keyboard.pages) {
            for i in 0..<page.rows.count {
                // TODO: both of these should be determined based on the model data, not the row #
                let isSideButtonRow = (i == 2)
                let isEquallySpacedRow = (i == 3)
                let rowsCount = page.rows[i].count
                
                if isSideButtonRow {
                    addGapPair(
                        "keyGap%dx%dp%d",
                        page: h,
                        row: i,
                        startIndex: 0,
                        endIndex: rowsCount,
                        leftAnchor: "leftSpacer",
                        rightAnchor: "rightSpacer",
                        vertical: false,
                        width: "0")
                    addGapPair(
                        "keyGap%dx%dp%d",
                        page: h,
                        row: i,
                        startIndex: 1,
                        endIndex: rowsCount - 1,
                        leftAnchor: nil,
                        rightAnchor: nil,
                        vertical: false,
                        width: nil)
                    let keyGap = layout["keyGap"]!
                    addGapsInRange(
                        "keyGap%dx%dp%d",
                        page: h,
                        row: i,
                        startIndex: 2,
                        endIndex: rowsCount - 2,
                        vertical: false,
                        width: "\(keyGap)")
                }
                else if isEquallySpacedRow {
                    addGapPair(
                        "keyGap%dx%dp%d",
                        page: h,
                        row: i,
                        startIndex: 0,
                        endIndex: page.rows[i].count,
                        leftAnchor: "leftSpacer",
                        rightAnchor: "rightSpacer",
                        vertical: false,
                        width: "0")
                    addGapsInRange(
                        "keyGap%dx%dp%d",
                        page: h,
                        row: i,
                        startIndex: 1,
                        endIndex: rowsCount - 1,
                        vertical: false,
                        width: "7") // TODO:
                }
                else {
                    addGapPair(
                        "keyGap%dx%dp%d",
                        page: h,
                        row: i,
                        startIndex: 0,
                        endIndex: rowsCount,
                        leftAnchor: "leftSpacer",
                        rightAnchor: "rightSpacer",
                        vertical: false,
                        width: nil)
                    let keyGap = layout["keyGap"]!
                    addGapsInRange(
                        "keyGap%dx%dp%d",
                        page: h,
                        row: i,
                        startIndex: 1,
                        endIndex: rowsCount - 1,
                        vertical: false,
                        width: "\(keyGap)")
                }
            }
        }
    }
    
    private func createKeyConstraints(keyboard: Keyboard) {
        var allConstraints: [String] = []
        
        let hasPeriod = false
        let canonicalKey = elements["key0x0p0"]
        var canonicalSpecialSameWidth: String? = nil
        
        for (h, page) in enumerate(keyboard.pages) {
            // setup special widths
            for i in 0..<page.rows.count {
                for j in 0..<page.rows[i].count {
                    let keyModel = page.rows[i][j]
                    let keyName = "key\(j)x\(i)p\(h)"
                    
                    if keyModel.type == Key.KeyType.ModeChange
                        || keyModel.type == Key.KeyType.KeyboardChange
                        || keyModel.type == Key.KeyType.Period {
                            if canonicalSpecialSameWidth == nil {
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
                                self.allConstraintObjects.append(widthConstraint)
                            } else {
                                allConstraints.append("[\(keyName)(\(canonicalSpecialSameWidth!))]")
                            }
                    }
                }
            }
            
            // setup return key
            for i in 0..<page.rows.count {
                for j in 0..<page.rows[i].count {
                    let keyModel = page.rows[i][j]
                    let keyName = "key\(j)x\(i)p\(h)"
                    
                    if keyModel.type == Key.KeyType.Return {
                        assert(canonicalSpecialSameWidth != nil, "canonical special key not found")
                        let widthConstraint = NSLayoutConstraint(
                            item: self.elements[keyName]!,
                            attribute: NSLayoutAttribute.Width,
                            relatedBy: NSLayoutRelation.Equal,
                            toItem: self.elements[canonicalSpecialSameWidth!]!,
                            attribute: NSLayoutAttribute.Width,
                            multiplier: CGFloat(2.0625),
                            constant: CGFloat(3.875))
                        self.superview.addConstraint(widthConstraint)
                        self.allConstraintObjects.append(widthConstraint)
                    }
                }
            }

            for i in 0..<page.rows.count {
                let canonicalRowKey = elements["key0x\(i)p\(h)"]
                
                for j in 0..<page.rows[i].count {
                    let keyModel = page.rows[i][j]
                    
                    let keyName = "key\(j)x\(i)p\(h)"
                    let key = self.elements[keyName]
                    
                    let isCanonicalKey = (key == canonicalKey) // TODO:
                    let isCanonicalRowKey = (key == canonicalRowKey) // TODO:
                    
                    allConstraints.append("[keyGap\(j)x\(i)p\(h)][\(keyName)][keyGap\(j+1)x\(i)p\(h)]")

                    // only the canonical key has a constant width
                    if isCanonicalKey {
    //                    let keyWidth = layout["keyWidth"]!
    //                    
    //                    allConstraints += "[\(keyName)(\(keyWidth)@19)]"
    //                    allConstraints += "[\(keyName)(\(keyWidth*2)@20)]"
    //                    allConstraints += "V:[\(keyName)(<=keyHeight@100,>=5@100)]"
                            
                        let widthConstraint = NSLayoutConstraint(
                            item: key!,
                            attribute: NSLayoutAttribute.Width,
                            relatedBy: NSLayoutRelation.Equal,
                            toItem: elements["superview"]!,
                            attribute: NSLayoutAttribute.Width,
                            multiplier: CGFloat(layout["keyWidthRatio"]!),
                            constant: 0)
                        widthConstraint.priority = 1000
                        
                        let heightConstraint = NSLayoutConstraint(
                            item: key!,
                            attribute: NSLayoutAttribute.Height,
                            relatedBy: NSLayoutRelation.Equal,
                            toItem: elements["superview"]!,
                            attribute: NSLayoutAttribute.Height,
                            multiplier: CGFloat(layout["keyHeightRatio"]!),
                            constant: 0)
                        heightConstraint.priority = 1000
                        
                        elements["superview"]?.addConstraint(widthConstraint)
                        elements["superview"]?.addConstraint(heightConstraint)
                        self.allConstraintObjects.append(widthConstraint)
                        self.allConstraintObjects.append(heightConstraint)
                        
                        self.keyWidthConstraint = widthConstraint
                        self.keyHeightConstraint = heightConstraint
                    }
                    else {
                        // all keys are the same height
                        allConstraints.append("V:[\(keyName)(key0x0p0)]")
                        
                        switch keyModel.type {
                        case Key.KeyType.Character:
                            var constraint0 = NSLayoutConstraint(
                                item: key!,
                                attribute: NSLayoutAttribute.Width,
                                relatedBy: NSLayoutRelation.Equal,
                                toItem: canonicalKey,
                                attribute: NSLayoutAttribute.Width,
                                multiplier: 1,
                                constant: 0)
                            self.superview.addConstraint(constraint0)
                            self.allConstraintObjects.append(constraint0)
                        case Key.KeyType.Shift, Key.KeyType.Backspace:
                            let shiftAndBackspaceMaxWidth = layout["shiftAndBackspaceMaxWidth"]!
                            var constraint = NSLayoutConstraint(
                                item: key!,
                                attribute: NSLayoutAttribute.Width,
                                relatedBy: NSLayoutRelation.Equal,
                                toItem: elements["superview"],
                                attribute: NSLayoutAttribute.Width,
                                multiplier: CGFloat(layout["keyWidthRatio"]! * (shiftAndBackspaceMaxWidth / 26)), // TODO:
                                constant: 0)
                            self.superview.addConstraint(constraint)
                            self.allConstraintObjects.append(constraint)
                        default:
                            break
                        }
                    }
                    
                    if isCanonicalRowKey {
                        allConstraints.append("V:[rowGap\(i)p\(h)][\(keyName)][rowGap\(i+1)p\(h)]")
                    }
                    else {
                        self.centerItems(key!, item2: canonicalRowKey!, vertical: false)
                    }
                }
            }
        }
        
        self.allConstraints += allConstraints
    }

    private class Spacer: UIView {
        
        override class func requiresConstraintBasedLayout() -> Bool {
            return true
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.hidden = true
            self.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.userInteractionEnabled = false
        }
        
        override convenience init() {
            self.init(frame: CGRectZero)
        }
        
        convenience init(color: UIColor) {
            self.init()
            
            if DEBUG_SHOW_SPACERS {
                self.layer.backgroundColor = color.CGColor
                self.hidden = false
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("NSCoding not supported")
        }
    }
}