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

struct layoutConstants {
//    let sideEdgesNormal: CGFloat = 3
//    let sideEdgesLarge: CGFloat = 4
//    let sideEdgesLargeThreshhold: CGFloat =
//    let topEdgePortraitNormal: CGFloat = 12
//    let topEdgePortraitSmall: CGFloat = 10
//    let topEdgePortraitSmallest: CGFloat = 8
//    let topEdgeLandscapeNormal: CGFloat = 6
//    let topEdgeLarge: CGFloat = 12
    
    static let landscapeRatio: CGFloat = 2
    
    static let sideEdges: CGFloat = 3
    static let topEdgePortrait: CGFloat = 10
    static let topEdgeLandscape: CGFloat = 6
    
    static let rowGapsPortrait: CGFloat = 15
    static let rowGapsLandscape: CGFloat = 7
    
    static let keyGaps: CGFloat = 6
    static let keyGapsSmall: CGFloat = 5
    static let keyGapsSmallThreshhold: CGFloat = 10
}




let globalLayout: [String:Double] = [
    "leftGap": 3,
    "rightGap": 3,
    "topGap": 12,
    "bottomGap": 3,
    "keyWidthRatio": Double((26.0 / 320.0)), //QQQ: this was messing up code completion... don't ask
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
func layoutMetric(name: String) -> CGFloat { return CGFloat(globalLayout[name]!) }

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

// handles the layout for the keyboard, including key spacing and arrangement
class KeyboardLayout: KeyboardKeyProtocol {
    
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
    
    var model: Keyboard
    var superview: UIView
    var modelToView: [Key:KeyboardKey] = [:]
    var viewToModel: [KeyboardKey:Key] = [:]
    var elements: [String:UIView] = [:]
    
    var initialized: Bool
    
    var topBanner: CGFloat = 0 {
        didSet {
//            self.setTopBannerSpace(topBanner)
        }
    }
    var topSpacerConstraint: NSLayoutConstraint?
    
    var banner: BannerView?
    
    init(model: Keyboard, superview: UIView, topBanner: CGFloat, banner: BannerView) {
        self.initialized = false
        self.model = model
        self.superview = superview
        self.topBanner = topBanner
        self.banner = banner
    }
    
    func initialize() {
        assert(!self.initialized, "already initialized")
        
        self.elements["superview"] = self.superview
        self.createViews(self.model)
//        self.setupConstraints()
        
        self.initialized = true
    }
    
    func setupConstraints() {
//        // TODO: autolayout class that can optionally "bake" values?
//        self.addEdgeConstraints()
//        self.createRowGapConstraints(self.model)
//        self.createKeyGapConstraints(self.model)
//        self.createKeyConstraints(self.model)
//        
//        var generatedConstraints: [AnyObject] = []
//        let dictMetrics: [NSObject: AnyObject] = self.layout
//        let dictElements: [NSObject: AnyObject] = self.elements
//        
//        for constraint in self.allConstraints {
//            let constraints = NSLayoutConstraint.constraintsWithVisualFormat(
//                constraint,
//                options: NSLayoutFormatOptions(0),
//                metrics: dictMetrics,
//                views: dictElements)
//            generatedConstraints += constraints
//        }
//        self.superview.addConstraints(generatedConstraints)
//        self.allConstraintObjects += (generatedConstraints as [NSLayoutConstraint])
    }
    
//    func updateForOrientation(portrait: Bool) {
//        assert(self.initialized, "not initialized")
//        
//        var widthConstraint: NSLayoutConstraint = self.keyWidthConstraint
//        var heightConstraint: NSLayoutConstraint = self.keyHeightConstraint
//        
//        if portrait {
//            self.updateConstraintMultiplier(&widthConstraint, multiplier: CGFloat(layout["keyWidthRatio"]!))
//            self.updateConstraintMultiplier(&heightConstraint, multiplier: CGFloat(layout["keyHeightRatio"]!))
//        }
//        else {
//            self.updateConstraintMultiplier(&widthConstraint, multiplier: CGFloat(layout["landscapeKeyWidthRatio"]!))
//            self.updateConstraintMultiplier(&heightConstraint, multiplier: CGFloat(layout["landscapeKeyHeightRatio"]!))
//        }
//        
//        self.keyWidthConstraint = widthConstraint
//        self.keyHeightConstraint = heightConstraint
//    }
    
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
    
//    private func updateConstraintMultiplier(inout constraint: NSLayoutConstraint, multiplier: CGFloat) {
//        // TODO: generalize
//        constraint.secondItem?.removeConstraint(constraint)
////        constraint.secondItem?.removeConstraint(constraint)
//        
//        let constraintIndex = find(self.allConstraintObjects, constraint)
//        if constraintIndex != nil { self.allConstraintObjects.removeAtIndex(constraintIndex!) }
//        
//        let newConstraint = NSLayoutConstraint(
//            item: constraint.firstItem,
//            attribute: constraint.firstAttribute,
//            relatedBy: constraint.relation,
//            toItem: constraint.secondItem,
//            attribute: constraint.secondAttribute,
//            multiplier: multiplier,
//            constant: constraint.constant)
//        newConstraint.priority = constraint.priority
//        
//        constraint.secondItem?.addConstraint(newConstraint)
//        
//        constraint = newConstraint
//    }
    
    func setColorsForKey(key: KeyboardKey, model: Key) {
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
    
    func createViews(keyboard: Keyboard) {
        for (h, page) in enumerate(keyboard.pages) {
            let numRows = page.rows.count
            
            for i in 0...numRows {
//                var rowGap = Spacer(color: ((i == 0 || i == numRows) ? UIColor.purpleColor() : UIColor.yellowColor()))
//                let rowGapName = "rowGap\(i)p\(h)"
//                rowGap.setTranslatesAutoresizingMaskIntoConstraints(false)
//                self.elements[rowGapName] = rowGap
//                self.superview.addSubview(rowGap)
                
                if (i < numRows) {
                    let numKeys = page.rows[i].count
                    
                    for j in 0...numKeys {
//                        var keyGap = Spacer(color: UIColor.blueColor())
//                        let keyGapName = "keyGap\(j)x\(i)p\(h)"
//                        keyGap.setTranslatesAutoresizingMaskIntoConstraints(false)
//                        self.elements[keyGapName] = keyGap
//                        self.superview.addSubview(keyGap)
                        
                        if (j < numKeys) {
                            var key = page.rows[i][j]
                            
                            var keyView = KeyboardKey(frame: CGRectZero) // TODO:
                            let keyViewName = "key\(j)x\(i)p\(h)"
                            keyView.enabled = true
//                            keyView.setTranslatesAutoresizingMaskIntoConstraints(false)
                            keyView.text = key.keyCapForCase(false)
                            keyView.delegate = self
                            
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
                            
                            // shapes
                            switch key.type {
                            case Key.KeyType.Shift:
                                let shiftShape = ShiftShape()
                                keyView.shape = shiftShape
                            case Key.KeyType.Backspace:
                                let backspaceShape = BackspaceShape()
                                keyView.shape = backspaceShape
                            case Key.KeyType.KeyboardChange:
                                let globeShape = GlobeShape()
                                keyView.shape = globeShape
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
    }
    
    // TODO: temp
    func layoutTemp() {
        self.layoutKeys(self.model, views: self.modelToView, bounds: self.superview.bounds)
    }
    
    func layoutKeys(model: Keyboard, views: [Key:KeyboardKey], bounds: CGRect) {
        let isLandscape: Bool = {
            let boundsRatio = bounds.width / bounds.height
            return (boundsRatio >= layoutConstants.landscapeRatio)
        }()
        
        for page in model.pages {
            let numRows = page.rows.count
            
            let mostKeysInRow: Int = {
                var currentMax: Int = 0
                for (i, row) in enumerate(page.rows) {
                    currentMax = max(currentMax, row.count)
                }
                return currentMax
            }()
            
            // measurement
            let sideEdges = layoutConstants.sideEdges

            // measurement
            let topEdge: CGFloat = ((isLandscape ? layoutConstants.topEdgeLandscape : layoutConstants.topEdgePortrait) + self.topBanner)
            
            // measurement
            let rowGaps: CGFloat = (isLandscape ? layoutConstants.rowGapsLandscape : layoutConstants.rowGapsPortrait)
            
            // measurement
            let keyGaps: CGFloat = {
                let pastThreshhold = (CGFloat(mostKeysInRow) >= layoutConstants.keyGapsSmallThreshhold)
                return (pastThreshhold ? layoutConstants.keyGapsSmall : layoutConstants.keyGaps)
            }()
            
            // measurement
            let keyHeight: CGFloat = {
                let totalGaps = sideEdges + topEdge + (rowGaps * CGFloat(numRows - 1))
                return (bounds.height - totalGaps) / CGFloat(numRows)
            }()
            
            // measurement
            let letterKeyWidth: CGFloat = {
                let totalGaps = (sideEdges * CGFloat(2)) + (keyGaps * CGFloat(mostKeysInRow - 1))
                return (bounds.width - totalGaps) / CGFloat(mostKeysInRow)
            }()
            
            for (r, row) in enumerate(page.rows) {
                let numKeysInRow = row.count
                
                // running offsets from both sides
                var offsets: (left: CGFloat, right: CGFloat) = (sideEdges, bounds.width - sideEdges)
                
                // if we're processing a span of character keys, this has the start and end indices of the range
                var inCharacterRange: Bool = false
                
                for (k, key) in enumerate(row) {
                    
                    // character range state processing
                    if !inCharacterRange {
                        if key.type == Key.KeyType.Character {
                            var endIndex = 0
                            
                            for (var k2: Int = k; k2 < row.count ; k2 += 1) {
                                let key2 = row[k2]
                                if key2.type == Key.KeyType.Character {
                                    endIndex = k2
                                }
                                else {
                                    break
                                }
                            }
                            
                            // ASSUMPTION: only one span per row
                            let numberOfCharactersInSpan = (endIndex + 1) - k
                            let sizeOfSpan = CGFloat(numberOfCharactersInSpan) * letterKeyWidth + CGFloat(numberOfCharactersInSpan - 1) * keyGaps
                            let sizeDiff = ((offsets.right - offsets.left) - sizeOfSpan) / CGFloat(2)
                            
//                            assert(sizeDiff > 0, "character row does not fit in layout")
                            
                            offsets.left += sizeDiff
                            offsets.right -= sizeDiff
                        }
                    }
                    else {
                        if key.type != Key.KeyType.Character {
                            inCharacterRange = false
                        }
                    }
                    
                    var view = views[key]
                    
                    let verticalOffset = topEdge + CGFloat(r) * (keyHeight + rowGaps)
                    let horizontalOffset = offsets.left

                    view?.frame = CGRectMake(horizontalOffset, verticalOffset, letterKeyWidth, keyHeight)
                    
                    offsets.left += (letterKeyWidth + keyGaps)
                }
            }
        }
    }
    
//    * capture keys in containers corresponding to their units
//    * units don't necessairly correspond to specific views
//    * for example:
//        * top: [left spacer][shift][space][key row][space][backspace][right spacer]
//        * key row: [key][gap][key][gap]...
//    
//    promises
//    for key in row {
//        if key == special {
//            promise(key.width = flexispecial)
//        }
//        else if key == character {
//            row = capture()
//            measure(row)
//            promise(key.surroundings == equal)
//        }
//    }
//    resolve(promises)
//    
    // at this point, we have "gaps" (flexi specials, surrounding gaps) that need to be resolved
    
    
    
    
//    private func addGapPair(nameFormat: String, page: Int, row: Int?, startIndex: Int, endIndex: Int, leftAnchor: String?, rightAnchor: String?, vertical: Bool, width: String?) {
//        var allConstraints: [String] = []
//        let rowConstraint = (row == nil)
//        
//        var leftGapName = (rowConstraint ? String(format: nameFormat, startIndex, page) : String(format: nameFormat, startIndex, row!, page))
//        var rightGapName = (rowConstraint ? String(format: nameFormat, endIndex, page) : String(format: nameFormat, endIndex, row!, page))
//        
//        var verticalFlag = (vertical ? "V:" : "")
//        var inverseVerticalFlag = (!vertical ? "V:" : "")
//        
//        // anchoring
//        
//        if leftAnchor != nil {
//            allConstraints.append("\(verticalFlag)[\(leftAnchor!)][\(leftGapName)]")
//        }
//        
//        if rightAnchor != nil {
//            allConstraints.append("\(verticalFlag)[\(rightGapName)][\(rightAnchor!)]")
//        }
//        
//        // size and centering
//        
//        if width != nil {
//            allConstraints.append("\(verticalFlag)[\(leftGapName)(\(width!))]")
//        }
//        
//        allConstraints.append("\(verticalFlag)[\(rightGapName)(\(leftGapName))]")
//        
//        allConstraints.append("\(inverseVerticalFlag)[\(leftGapName)(debugWidth)]")
//        allConstraints.append("\(inverseVerticalFlag)[\(rightGapName)(debugWidth)]")
//        
//        if vertical {
//            centerItems(self.elements[leftGapName]!, item2: self.elements["superview"]!, vertical: true)
//            centerItems(self.elements[rightGapName]!, item2: self.elements["superview"]!, vertical: true)
//        }
//        else {
//            assert(rowConstraint == false)
//            centerItems(self.elements[leftGapName]!, item2: self.elements["key\(0)x\(row!)p\(page)"]!, vertical: false)
//            centerItems(self.elements[rightGapName]!, item2: self.elements["key\(0)x\(row!)p\(page)"]!, vertical: false)
//        }
//        
//        self.allConstraints += allConstraints
//    }
    
//    private func addGapsInRange(nameFormat: String, page: Int, row: Int?, startIndex: Int, endIndex: Int, vertical: Bool, width: String?) {
//        var allConstraints: [String] = []
//        let rowConstraint = (row == nil)
//        
//        var firstGapName = (rowConstraint ? String(format: nameFormat, startIndex, page) : String(format: nameFormat, startIndex, row!, page))
//        
//        var verticalFlag = (vertical ? "V:" : "")
//        var inverseVerticalFlag = (!vertical ? "V:" : "")
//        
//        if width != nil {
//            allConstraints.append("\(verticalFlag)[\(firstGapName)(\(width!))]")
//        }
//        
//        for i in startIndex...endIndex {
//            var gapName = (rowConstraint ? String(format: nameFormat, i, page) : String(format: nameFormat, i, row!, page))
//            
//            // size and centering
//            
//            if i > 0 {
//                allConstraints.append("\(verticalFlag)[\(gapName)(\(firstGapName))]")
//            }
//            
//            allConstraints.append("\(inverseVerticalFlag)[\(gapName)(debugWidth)]")
//            
//            if vertical {
//                centerItems(self.elements[gapName]!, item2: self.elements["superview"]!, vertical: true)
//            }
//            else {
//                assert(rowConstraint == false)
//                centerItems(self.elements[gapName]!, item2: self.elements["key\(0)x\(row!)p\(page)"]!, vertical: false)
//            }
//        }
//        
//        self.allConstraints += allConstraints
//    }
    
//    private func addEdgeConstraints() {
//        let spacers = [
//            "leftSpacer": Spacer(color: UIColor.redColor()),
//            "rightSpacer": Spacer(color: UIColor.redColor()),
//            "topSpacer": Spacer(color: UIColor.redColor()),
//            "bottomSpacer": Spacer(color: UIColor.redColor()),
//            "banner": self.banner!
//        ]
//        
//        // basic setup
//        for (name, spacer) in spacers {
//            spacer.setTranslatesAutoresizingMaskIntoConstraints(false)
//            self.elements[name] = spacer
//            self.superview.addSubview(spacer)
//        }
//        
//        let constraints = [
//            // left/right spacers
//            "|[leftSpacer(leftGap)]",
//            "[rightSpacer(rightGap)]|",
//            "V:[leftSpacer(debugWidth)]",
//            "V:[rightSpacer(debugWidth)]",
//            
//            // banner
//            "|[banner]|",
//            
//            // top/bottom spacers
//            "V:|[banner][topSpacer(topGap)]", //height set below
//            "V:[bottomSpacer(bottomGap)]|",
//            "[topSpacer(debugWidth)]",
//            "[bottomSpacer(debugWidth)]"]
//        
//        // edge constraints
//        for constraint in constraints {
//            let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
//                constraint,
//                options: NSLayoutFormatOptions(0),
//                metrics: layout,
//                views: elements)
//            self.superview.addConstraints(generatedConstraints)
//            self.allConstraintObjects += (generatedConstraints as [NSLayoutConstraint])
//        }
//        
//        // top spacer constraint
//        let topSpacerConstraint = NSLayoutConstraint(
//            item: self.banner!,
//            attribute: NSLayoutAttribute.Height,
//            relatedBy: NSLayoutRelation.Equal,
//            toItem: nil,
//            attribute: NSLayoutAttribute.NotAnAttribute,
//            multiplier: 1,
//            constant: CGFloat(self.topBanner))
//        self.topSpacerConstraint = topSpacerConstraint
//        self.superview.addConstraint(topSpacerConstraint)
//        self.allConstraintObjects.append(topSpacerConstraint)
//        
//        // centering constraints
//        for (name, spacer) in spacers {
//            if (name.hasPrefix("left") || name.hasPrefix("right")) {
//                let constraint = NSLayoutConstraint(
//                    item: spacer,
//                    attribute: NSLayoutAttribute.CenterY,
//                    relatedBy: NSLayoutRelation.Equal,
//                    toItem: self.superview,
//                    attribute: NSLayoutAttribute.CenterY,
//                    multiplier: 1,
//                    constant: 0)
//                self.superview.addConstraint(constraint)
//                self.allConstraintObjects.append(constraint)
//            }
//            else if (name.hasPrefix("top") || name.hasPrefix("bottom")) {
//                let constraint = NSLayoutConstraint(
//                    item: spacer,
//                    attribute: NSLayoutAttribute.CenterX,
//                    relatedBy: NSLayoutRelation.Equal,
//                    toItem: self.superview,
//                    attribute: NSLayoutAttribute.CenterX,
//                    multiplier: 1,
//                    constant: 0)
//                self.superview.addConstraint(constraint)
//                self.allConstraintObjects.append(constraint)
//            }
//        }
//        
//        return
//    }
    
//    func setTopBannerSpace(space: CGFloat) {
//        self.topSpacerConstraint?.constant = space
//    }
    
//    private func createRowGapConstraints(keyboard: Keyboard) {
//        for (h, page) in enumerate(keyboard.pages) {
//            self.addGapPair(
//                "rowGap%dp%d",
//                page: h,
//                row: nil,
//                startIndex: 0,
//                endIndex: page.rows.count,
//                leftAnchor: "topSpacer",
//                rightAnchor: "bottomSpacer",
//                vertical: true,
//                width: "0")
//            
//            if page.rows.count >= 2 {
//                self.addGapsInRange("rowGap%dp%d",
//                    page: h,
//                    row: nil,
//                    startIndex: 1,
//                    endIndex: page.rows.count - 1,
//                    vertical: true,
//                    width: ">=5@50")
//            }
//        }
//    }
    
//    // TODO: make this a single constraint string??
//    private func createKeyGapConstraints(keyboard: Keyboard) {
//        for (h, page) in enumerate(keyboard.pages) {
//            for i in 0..<page.rows.count {
//                // TODO: both of these should be determined based on the model data, not the row #
//                let isSideButtonRow = (i == 2)
//                let isEquallySpacedRow = (i == 3)
//                let rowsCount = page.rows[i].count
//                
//                if isSideButtonRow {
//                    addGapPair(
//                        "keyGap%dx%dp%d",
//                        page: h,
//                        row: i,
//                        startIndex: 0,
//                        endIndex: rowsCount,
//                        leftAnchor: "leftSpacer",
//                        rightAnchor: "rightSpacer",
//                        vertical: false,
//                        width: "0")
//                    addGapPair(
//                        "keyGap%dx%dp%d",
//                        page: h,
//                        row: i,
//                        startIndex: 1,
//                        endIndex: rowsCount - 1,
//                        leftAnchor: nil,
//                        rightAnchor: nil,
//                        vertical: false,
//                        width: nil)
//                    let keyGap = layout["keyGap"]!
//                    addGapsInRange(
//                        "keyGap%dx%dp%d",
//                        page: h,
//                        row: i,
//                        startIndex: 2,
//                        endIndex: rowsCount - 2,
//                        vertical: false,
//                        width: "\(keyGap)")
//                }
//                else if isEquallySpacedRow {
//                    addGapPair(
//                        "keyGap%dx%dp%d",
//                        page: h,
//                        row: i,
//                        startIndex: 0,
//                        endIndex: page.rows[i].count,
//                        leftAnchor: "leftSpacer",
//                        rightAnchor: "rightSpacer",
//                        vertical: false,
//                        width: "0")
//                    addGapsInRange(
//                        "keyGap%dx%dp%d",
//                        page: h,
//                        row: i,
//                        startIndex: 1,
//                        endIndex: rowsCount - 1,
//                        vertical: false,
//                        width: "7") // TODO:
//                }
//                else {
//                    addGapPair(
//                        "keyGap%dx%dp%d",
//                        page: h,
//                        row: i,
//                        startIndex: 0,
//                        endIndex: rowsCount,
//                        leftAnchor: "leftSpacer",
//                        rightAnchor: "rightSpacer",
//                        vertical: false,
//                        width: nil)
//                    let keyGap = layout["keyGap"]!
//                    addGapsInRange(
//                        "keyGap%dx%dp%d",
//                        page: h,
//                        row: i,
//                        startIndex: 1,
//                        endIndex: rowsCount - 1,
//                        vertical: false,
//                        width: "\(keyGap)")
//                }
//            }
//        }
//    }
    
//    private func createKeyConstraints(keyboard: Keyboard) {
//        var allConstraints: [String] = []
//        
//        let hasPeriod = false
//        let canonicalKey = elements["key0x0p0"]
//        var canonicalSpecialSameWidth: String? = nil
//        
//        for (h, page) in enumerate(keyboard.pages) {
//            // setup special widths
//            for i in 0..<page.rows.count {
//                for j in 0..<page.rows[i].count {
//                    let keyModel = page.rows[i][j]
//                    let keyName = "key\(j)x\(i)p\(h)"
//                    
//                    if keyModel.type == Key.KeyType.ModeChange
//                        || keyModel.type == Key.KeyType.KeyboardChange
//                        || keyModel.type == Key.KeyType.Period {
//                            if canonicalSpecialSameWidth == nil {
//                                canonicalSpecialSameWidth = keyName
//                                let widthConstraint = NSLayoutConstraint(
//                                    item: self.elements[keyName]!,
//                                    attribute: NSLayoutAttribute.Width,
//                                    relatedBy: NSLayoutRelation.Equal,
//                                    toItem: self.elements["superview"]!,
//                                    attribute: NSLayoutAttribute.Width,
//                                    multiplier: CGFloat(0.0645),
//                                    constant: CGFloat(13.37))
//                                self.superview.addConstraint(widthConstraint)
//                                self.allConstraintObjects.append(widthConstraint)
//                            } else {
//                                allConstraints.append("[\(keyName)(\(canonicalSpecialSameWidth!))]")
//                            }
//                    }
//                }
//            }
//            
//            // setup return key
//            for i in 0..<page.rows.count {
//                for j in 0..<page.rows[i].count {
//                    let keyModel = page.rows[i][j]
//                    let keyName = "key\(j)x\(i)p\(h)"
//                    
//                    if keyModel.type == Key.KeyType.Return {
//                        assert(canonicalSpecialSameWidth != nil, "canonical special key not found")
//                        let widthConstraint = NSLayoutConstraint(
//                            item: self.elements[keyName]!,
//                            attribute: NSLayoutAttribute.Width,
//                            relatedBy: NSLayoutRelation.Equal,
//                            toItem: self.elements[canonicalSpecialSameWidth!]!,
//                            attribute: NSLayoutAttribute.Width,
//                            multiplier: CGFloat(2.0625),
//                            constant: CGFloat(3.875))
//                        self.superview.addConstraint(widthConstraint)
//                        self.allConstraintObjects.append(widthConstraint)
//                    }
//                }
//            }
//
//            for i in 0..<page.rows.count {
//                let canonicalRowKey = elements["key0x\(i)p\(h)"]
//                
//                for j in 0..<page.rows[i].count {
//                    let keyModel = page.rows[i][j]
//                    
//                    let keyName = "key\(j)x\(i)p\(h)"
//                    let key = self.elements[keyName]
//                    
//                    let isCanonicalKey = (key == canonicalKey) // TODO:
//                    let isCanonicalRowKey = (key == canonicalRowKey) // TODO:
//                    
//                    allConstraints.append("[keyGap\(j)x\(i)p\(h)][\(keyName)][keyGap\(j+1)x\(i)p\(h)]")
//
//                    // only the canonical key has a constant width
//                    if isCanonicalKey {
//    //                    let keyWidth = layout["keyWidth"]!
//    //                    
//    //                    allConstraints += "[\(keyName)(\(keyWidth)@19)]"
//    //                    allConstraints += "[\(keyName)(\(keyWidth*2)@20)]"
//    //                    allConstraints += "V:[\(keyName)(<=keyHeight@100,>=5@100)]"
//                            
//                        let widthConstraint = NSLayoutConstraint(
//                            item: key!,
//                            attribute: NSLayoutAttribute.Width,
//                            relatedBy: NSLayoutRelation.Equal,
//                            toItem: elements["superview"]!,
//                            attribute: NSLayoutAttribute.Width,
//                            multiplier: CGFloat(layout["keyWidthRatio"]!),
//                            constant: 0)
//                        widthConstraint.priority = 1000
//                        
//                        let heightConstraint = NSLayoutConstraint(
//                            item: key!,
//                            attribute: NSLayoutAttribute.Height,
//                            relatedBy: NSLayoutRelation.Equal,
//                            toItem: elements["superview"]!,
//                            attribute: NSLayoutAttribute.Height,
//                            multiplier: CGFloat(layout["keyHeightRatio"]!),
//                            constant: 0)
//                        heightConstraint.priority = 1000
//                        
//                        elements["superview"]?.addConstraint(widthConstraint)
//                        elements["superview"]?.addConstraint(heightConstraint)
//                        self.allConstraintObjects.append(widthConstraint)
//                        self.allConstraintObjects.append(heightConstraint)
//                        
//                        self.keyWidthConstraint = widthConstraint
//                        self.keyHeightConstraint = heightConstraint
//                    }
//                    else {
//                        // all keys are the same height
//                        allConstraints.append("V:[\(keyName)(key0x0p0)]")
//                        
//                        switch keyModel.type {
//                        case Key.KeyType.Character:
//                            var constraint0 = NSLayoutConstraint(
//                                item: key!,
//                                attribute: NSLayoutAttribute.Width,
//                                relatedBy: NSLayoutRelation.Equal,
//                                toItem: canonicalKey,
//                                attribute: NSLayoutAttribute.Width,
//                                multiplier: 1,
//                                constant: 0)
//                            self.superview.addConstraint(constraint0)
//                            self.allConstraintObjects.append(constraint0)
//                        case Key.KeyType.Shift, Key.KeyType.Backspace:
//                            let shiftAndBackspaceMaxWidth = layout["shiftAndBackspaceMaxWidth"]!
//                            var constraint = NSLayoutConstraint(
//                                item: key!,
//                                attribute: NSLayoutAttribute.Width,
//                                relatedBy: NSLayoutRelation.Equal,
//                                toItem: elements["superview"],
//                                attribute: NSLayoutAttribute.Width,
//                                multiplier: CGFloat(layout["keyWidthRatio"]! * (shiftAndBackspaceMaxWidth / 26)), // TODO:
//                                constant: 0)
//                            self.superview.addConstraint(constraint)
//                            self.allConstraintObjects.append(constraint)
//                        default:
//                            break
//                        }
//                    }
//                    
//                    if isCanonicalRowKey {
//                        allConstraints.append("V:[rowGap\(i)p\(h)][\(keyName)][rowGap\(i+1)p\(h)]")
//                    }
//                    else {
//                        self.centerItems(key!, item2: canonicalRowKey!, vertical: false)
//                    }
//                }
//            }
//        }
//        
//        self.allConstraints += allConstraints
//    }
    
    // TODO: superview constraints not part of allConstraints array, and also allConstraints does not work recursively
//    var extraConstraints: [(UIView, [NSLayoutConstraint])] = []
    func willShowPopup(key: KeyboardKey, direction: Direction) {
//        if let popup = key.popup {
//            let directionToAttribute = [
//                Direction.Up: NSLayoutAttribute.Top,
//                Direction.Down: NSLayoutAttribute.Bottom,
//                Direction.Left: NSLayoutAttribute.Left,
//                Direction.Right: NSLayoutAttribute.Right,
//            ]
//            
//            for (view, constraintArray) in self.extraConstraints {
//                if key == view {
//                    for constraint in constraintArray {
//                        self.superview.removeConstraint(constraint)
//                    }
//                }
//            }
//            
//            var extraConstraints: [NSLayoutConstraint] = []
//            
//            var cantTouchTopConstraint = NSLayoutConstraint(
//                item: popup,
//                attribute: directionToAttribute[direction]!,
//                relatedBy: (direction == Direction.Right ? NSLayoutRelation.LessThanOrEqual : NSLayoutRelation.GreaterThanOrEqual),
//                toItem: self.superview,
//                attribute: directionToAttribute[direction]!,
//                multiplier: 1,
//                constant: 2) // TODO: layout
//            cantTouchTopConstraint.priority = 1000
//            self.superview.addConstraint(cantTouchTopConstraint)
//            extraConstraints.append(cantTouchTopConstraint)
////            self.allConstraintObjects.append(cantTouchTopConstraint)
//            
//            if direction.horizontal() {
//                var cantTouchTopConstraint = NSLayoutConstraint(
//                    item: popup,
//                    attribute: directionToAttribute[Direction.Up]!,
//                    relatedBy: NSLayoutRelation.GreaterThanOrEqual,
//                    toItem: self.superview,
//                    attribute: directionToAttribute[Direction.Up]!,
//                    multiplier: 1,
//                    constant: 5) // TODO: layout
//                cantTouchTopConstraint.priority = 1000
//                self.superview.addConstraint(cantTouchTopConstraint)
//                extraConstraints.append(cantTouchTopConstraint)
////                self.allConstraintObjects.append(cantTouchTopConstraint)
//            }
//            else {
//                var cantTouchSideConstraint = NSLayoutConstraint(
//                    item: self.superview,
//                    attribute: directionToAttribute[Direction.Right]!,
//                    relatedBy: NSLayoutRelation.GreaterThanOrEqual,
//                    toItem: popup,
//                    attribute: directionToAttribute[Direction.Right]!,
//                    multiplier: 1,
//                    constant: 3) // TODO: layout
//                cantTouchSideConstraint.priority = 1000
//                var cantTouchSideConstraint2 = NSLayoutConstraint(
//                    item: self.superview,
//                    attribute: directionToAttribute[Direction.Left]!,
//                    relatedBy: NSLayoutRelation.LessThanOrEqual,
//                    toItem: popup,
//                    attribute: directionToAttribute[Direction.Left]!,
//                    multiplier: 1,
//                    constant: -3) // TODO: layout
//                cantTouchSideConstraint2.priority = 1000
//                
//                self.superview.addConstraint(cantTouchSideConstraint)
//                self.superview.addConstraint(cantTouchSideConstraint2)
//                extraConstraints.append(cantTouchSideConstraint)
//                extraConstraints.append(cantTouchSideConstraint2)
////                self.allConstraintObjects.append(cantTouchSideConstraint)
////                self.allConstraintObjects.append(cantTouchSideConstraint2)
//            }
//            
//            self.extraConstraints.append((key, extraConstraints) as (UIView, [NSLayoutConstraint]))
//        }
    }
    
    func willHidePopup(key: KeyboardKey) {
//        for (view, constraintArray) in self.extraConstraints {
//            if key == view {
//                for constraint in constraintArray {
//                    self.superview.removeConstraint(constraint)
//                }
//            }
//        }
    }

//    private class Spacer: UIView {
//        
//        override class func requiresConstraintBasedLayout() -> Bool {
//            return true
//        }
//        
//        override init(frame: CGRect) {
//            super.init(frame: frame)
//            
//            self.hidden = true
//            self.setTranslatesAutoresizingMaskIntoConstraints(false)
//            self.userInteractionEnabled = false
//        }
//        
//        override convenience init() {
//            self.init(frame: CGRectZero)
//        }
//        
//        convenience init(color: UIColor) {
//            self.init()
//            
//            if DEBUG_SHOW_SPACERS {
//                self.layer.backgroundColor = color.CGColor
//                self.hidden = false
//            }
//        }
//        
//        required init(coder: NSCoder) {
//            fatalError("NSCoding not supported")
//        }
//    }
}