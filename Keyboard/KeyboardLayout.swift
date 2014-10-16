//
//  KeyboardLayout.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/25/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// TODO: need to rename, consolidate, and define terms
struct layoutConstants {
    static let landscapeRatio: CGFloat = 2
    
    // side edges increase on 6 in portrait
    static let sideEdgesPortraitArray: [CGFloat] = [3, 4]
    static let sideEdgesPortraitWidthThreshholds: [CGFloat] = [400]
    static let sideEdgesLandscape: CGFloat = 3
    
    // top edges decrease on various devices in portrait
    static let topEdgePortraitArray: [CGFloat] = [12, 10, 8]
    static let topEdgePortraitWidthThreshholds: [CGFloat] = [350, 400]
    static let topEdgeLandscape: CGFloat = 6
    
    // keyboard area shrinks in size in landscape on 6 and 6+
    static let keyboardShrunkSizeArray: [CGFloat] = [522, 524]
    static let keyboardShrunkSizeWidthThreshholds: [CGFloat] = [700]
    static let keyboardShrunkSizeBaseWidthThreshhold: CGFloat = 600
    
    // row gaps are weird on 6 in portrait
    static let rowGapPortraitArray: [CGFloat] = [15, 11, 10]
    static let rowGapPortraitThreshholds: [CGFloat] = [350, 400]
    static let rowGapPortraitLastRow: CGFloat = 9
    static let rowGapPortraitLastRowIndex: Int = 1
    static let rowGapLandscape: CGFloat = 7
    
    // key gaps have weird and inconsistent rules
    static let keyGapPortraitNormal: CGFloat = 6
    static let keyGapPortraitSmall: CGFloat = 5
    static let keyGapPortraitNormalThreshhold: CGFloat = 350
    static let keyGapPortraitUncompressThreshhold: CGFloat = 350
    static let keyGapLandscapeNormal: CGFloat = 6
    static let keyGapLandscapeSmall: CGFloat = 5
    // TODO: 5.5 row gap on 5L
    // TODO: wider row gap on 6L
    static let keyCompressedThreshhold: Int = 11
    
    // rows with two special keys on the side and characters in the middle (usually 3rd row)
    // TODO: these are not pixel-perfect, but should be correct within a few pixels
    // TODO: are there any "hidden constants" that would allow us to get rid of the multiplier? see: popup dimensions
    static let flexibleEndRowTotalWidthToKeyWidthMPortrait: CGFloat = 1
    static let flexibleEndRowTotalWidthToKeyWidthCPortrait: CGFloat = -14
    static let flexibleEndRowTotalWidthToKeyWidthMLandscape: CGFloat = 0.9231
    static let flexibleEndRowTotalWidthToKeyWidthCLandscape: CGFloat = -9.4615
    
    static let lastRowKeyGapPortrait: CGFloat = 6
    static let lastRowKeyGapLandscapeArray: [CGFloat] = [8, 7, 5]
    static let lastRowKeyGapLandscapeWidthThreshholds: [CGFloat] = [500, 700]
    
    // TODO: approxmiate, but close enough
    static let lastRowPortraitFirstTwoButtonAreaWidthToKeyboardAreaWidth: CGFloat = 0.24
    static let lastRowLandscapeFirstTwoButtonAreaWidthToKeyboardAreaWidth: CGFloat = 0.19
    static let lastRowPortraitLastButtonAreaWidthToKeyboardAreaWidth: CGFloat = 0.24
    static let lastRowLandscapeLastButtonAreaWidthToKeyboardAreaWidth: CGFloat = 0.19
    
    static let popupGap: CGFloat = 8 // TODO: not exactly precise
    static let popupWidthIncrement: CGFloat = 26
    static let popupTotalHeightArray: [CGFloat] = [102, 108]
    static let popupTotalHeightDeviceWidthThreshholds: [CGFloat] = [350]
    
    static func sideEdgesPortrait(width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.sideEdgesPortraitArray, threshholds: self.sideEdgesPortraitWidthThreshholds, measurement: width)
    }
    static func topEdgePortrait(width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.topEdgePortraitArray, threshholds: self.topEdgePortraitWidthThreshholds, measurement: width)
    }
    static func rowGapPortrait(width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.rowGapPortraitArray, threshholds: self.rowGapPortraitThreshholds, measurement: width)
    }
    
    static func rowGapPortraitLastRow(width: CGFloat) -> CGFloat {
        let index = self.findThreshholdIndex(self.rowGapPortraitThreshholds, measurement: width)
        if index == self.rowGapPortraitLastRowIndex {
            return self.rowGapPortraitLastRow
        }
        else {
            return self.rowGapPortraitArray[index]
        }
    }
    
    static func keyGapPortrait(width: CGFloat, rowCharacterCount: Int) -> CGFloat {
        let compressed = (rowCharacterCount >= self.keyCompressedThreshhold)
        if compressed {
            if width >= self.keyGapPortraitUncompressThreshhold {
                return self.keyGapPortraitNormal
            }
            else {
                return self.keyGapPortraitSmall
            }
        }
        else {
            return self.keyGapPortraitNormal
        }
    }
    static func keyGapLandscape(width: CGFloat, rowCharacterCount: Int) -> CGFloat {
        let compressed = (rowCharacterCount >= self.keyCompressedThreshhold)
        let shrunk = self.keyboardIsShrunk(width)
        if compressed || shrunk {
            return self.keyGapLandscapeSmall
        }
        else {
            return self.keyGapLandscapeNormal
        }
    }
    
    static func lastRowKeyGapLandscape(width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.lastRowKeyGapLandscapeArray, threshholds: self.lastRowKeyGapLandscapeWidthThreshholds, measurement: width)
    }
    
    static func keyboardIsShrunk(width: CGFloat) -> Bool {
        return width >= self.keyboardShrunkSizeBaseWidthThreshhold
    }
    static func keyboardShrunkSize(width: CGFloat) -> CGFloat {
        if width >= self.keyboardShrunkSizeBaseWidthThreshhold {
            return self.findThreshhold(self.keyboardShrunkSizeArray, threshholds: self.keyboardShrunkSizeWidthThreshholds, measurement: width)
        }
        else {
            return width
        }
    }
    
    static func popupTotalHeight(deviceWidth: CGFloat) -> CGFloat {
        return self.findThreshhold(self.popupTotalHeightArray, threshholds: self.popupTotalHeightDeviceWidthThreshholds, measurement: deviceWidth)
    }
    
    static func findThreshhold(elements: [CGFloat], threshholds: [CGFloat], measurement: CGFloat) -> CGFloat {
        assert(elements.count == threshholds.count + 1, "elements and threshholds do not match")
        return elements[self.findThreshholdIndex(threshholds, measurement: measurement)]
    }
    static func findThreshholdIndex(threshholds: [CGFloat], measurement: CGFloat) -> Int {
        for (i, threshhold) in enumerate(reverse(threshholds)) {
            if measurement >= threshhold {
                let actualIndex = threshholds.count - i
                return actualIndex
            }
        }
        return 0
    }
}

struct globalColors {
    static var lightModeRegularKey: UIColor = UIColor.whiteColor()
    static var lightModeSpecialKey: UIColor = UIColor(hue: (217/360.0), saturation: 0.09, brightness: 0.75, alpha: 1)
    static var darkModeRegularKey: UIColor = UIColor.grayColor().colorWithAlphaComponent(CGFloat(0.25))
    static var darkModeSpecialKey: UIColor = UIColor.blackColor().colorWithAlphaComponent(CGFloat(0.25))
    static var lightModeUnderColor: UIColor = UIColor(hue: (220/360.0), saturation: 0.04, brightness: 0.56, alpha: 1)
    static var darkModeUnderColor: UIColor = UIColor(red: CGFloat(38.6)/CGFloat(255), green: CGFloat(18)/CGFloat(255), blue: CGFloat(39.3)/CGFloat(255), alpha: 0.4)
    static var lightModeTextColor: UIColor = UIColor.blackColor()
    static var darkModeTextColor: UIColor = UIColor.whiteColor()
    static var borderColor: UIColor = UIColor(hue: (214/360.0), saturation: 0.04, brightness: 0.65, alpha: 1.0)
}

//"darkShadowColor": UIColor(hue: (220/360.0), saturation: 0.04, brightness: 0.56, alpha: 1),
//"blueColor": UIColor(hue: (211/360.0), saturation: 1.0, brightness: 1.0, alpha: 1),
//"blueShadowColor": UIColor(hue: (216/360.0), saturation: 0.05, brightness: 0.43, alpha: 1),

// handles the layout for the keyboard, including key spacing and arrangement
class KeyboardLayout: KeyboardKeyProtocol {
    
    var model: Keyboard
    var superview: UIView
    var modelToView: [Key:KeyboardKey] = [:]
    var viewToModel: [KeyboardKey:Key] = [:]
    var elements: [String:UIView] = [:]
    
    var darkMode: Bool
    var initialized: Bool
    
    init(model: Keyboard, superview: UIView, darkMode: Bool) {
        self.initialized = false
        self.model = model
        self.superview = superview
        self.darkMode = darkMode
    }
    
    func initialize() {
        assert(!self.initialized, "already initialized")
        
        self.elements["superview"] = self.superview
        self.createViews(self.model)
        
        self.initialized = true
    }
    
    func viewForKey(model: Key) -> KeyboardKey? {
        return self.modelToView[model]
    }
    
    func keyForView(key: KeyboardKey) -> Key? {
        return self.viewToModel[key]
    }
    
    func setColorsForKey(key: KeyboardKey, model: Key, darkMode: Bool) {
        switch model.type {
        case
        Key.KeyType.Character,
        Key.KeyType.SpecialCharacter,
        Key.KeyType.Period:
            key.color = (self.darkMode ? globalColors.darkModeRegularKey : globalColors.lightModeRegularKey)
            key.textColor = (self.darkMode ? globalColors.darkModeTextColor : globalColors.lightModeTextColor)
        case
        Key.KeyType.Space:
            key.color = (self.darkMode ? globalColors.darkModeRegularKey : globalColors.lightModeRegularKey)
            key.downColor = (self.darkMode ? UIColor.purpleColor() : globalColors.lightModeSpecialKey)
            key.textColor = (self.darkMode ? globalColors.darkModeTextColor : globalColors.lightModeTextColor)
        case
        Key.KeyType.Shift,
        Key.KeyType.Backspace:
            key.color = (self.darkMode ? globalColors.darkModeSpecialKey : globalColors.lightModeSpecialKey)
            key.downColor = (self.darkMode ? UIColor.purpleColor() : globalColors.lightModeRegularKey)
            key.textColor = globalColors.darkModeTextColor
            key.downTextColor = globalColors.lightModeTextColor
        case
        Key.KeyType.ModeChange:
            key.color = (self.darkMode ? globalColors.darkModeSpecialKey : globalColors.lightModeSpecialKey)
            key.textColor = (self.darkMode ? globalColors.darkModeTextColor : globalColors.lightModeTextColor)
        case
        Key.KeyType.Return,
        Key.KeyType.KeyboardChange:
            key.color = (self.darkMode ? globalColors.darkModeSpecialKey : globalColors.lightModeSpecialKey)
            key.downColor = (self.darkMode ? UIColor.purpleColor() : globalColors.lightModeRegularKey)
            key.textColor = (self.darkMode ? globalColors.darkModeTextColor : globalColors.lightModeTextColor)
        }
        
        key.underColor = (self.darkMode ? globalColors.darkModeUnderColor : globalColors.lightModeUnderColor)
        key.borderColor = (self.darkMode ? globalColors.borderColor : globalColors.borderColor)
    }
    
    func createViews(keyboard: Keyboard) {
        let specialKeyVibrancy: VibrancyType? = (self.darkMode ? VibrancyType.DarkSpecial : VibrancyType.LightSpecial)
        let normalKeyVibrancy: VibrancyType? = (self.darkMode ? VibrancyType.DarkRegular : nil)
        
        for (h, page) in enumerate(keyboard.pages) {
            let numRows = page.rows.count
            
            for i in 0...numRows {
                
                if (i < numRows) {
                    let numKeys = page.rows[i].count
                    
                    for j in 0...numKeys {
                        
                        if (j < numKeys) {
                            var key = page.rows[i][j]
                            
                            var keyView = KeyboardKey(vibrancy: (key.type.specialButton() ? specialKeyVibrancy : normalKeyVibrancy))
                            let keyViewName = "key\(j)x\(i)p\(h)"
                            keyView.enabled = true
                            keyView.text = key.keyCapForCase(false)
                            keyView.delegate = self
                            
                            self.superview.addSubview(keyView)
                            
                            self.elements[keyViewName] = keyView
                            self.modelToView[key] = keyView
                            self.viewToModel[keyView] = key
                            
                            setColorsForKey(keyView, model: key, darkMode: self.darkMode)
                            
                            // font sizing
                            switch key.type {
                            case
                            Key.KeyType.ModeChange,
                            Key.KeyType.Space,
                            Key.KeyType.Return:
                                keyView.label.adjustsFontSizeToFitWidth = false
                                keyView.label.minimumScaleFactor = 0.1
                                keyView.label.font = keyView.label.font.fontWithSize(16)
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
    
    //////////////////////
    // LAYOUT FUNCTIONS //
    //////////////////////
    
    // TODO: temp
    func layoutTemp() {
        self.layoutKeys(self.model, views: self.modelToView, bounds: self.superview.bounds)
    }
    
    func rounded(measurement: CGFloat) -> CGFloat {
        return round(measurement * UIScreen.mainScreen().scale) / UIScreen.mainScreen().scale
    }
    
    func layoutKeys(model: Keyboard, views: [Key:KeyboardKey], bounds: CGRect) {
        if bounds.height == 0 || bounds.width == 0 {
            return
        }
        
        let isLandscape: Bool = {
            let boundsRatio = bounds.width / bounds.height
            return (boundsRatio >= layoutConstants.landscapeRatio)
        }()
        
        var sideEdges = (isLandscape ? layoutConstants.sideEdgesLandscape : layoutConstants.sideEdgesPortrait(bounds.width))
        let bottomEdge = sideEdges
        
        let normalKeyboardSize = bounds.width - CGFloat(2) * sideEdges
        let shrunkKeyboardSize = layoutConstants.keyboardShrunkSize(normalKeyboardSize)
        
        sideEdges += ((normalKeyboardSize - shrunkKeyboardSize) / CGFloat(2))
        
        let topEdge: CGFloat = (isLandscape ? layoutConstants.topEdgeLandscape : layoutConstants.topEdgePortrait(bounds.width))
        
        let rowGap: CGFloat = (isLandscape ? layoutConstants.rowGapLandscape : layoutConstants.rowGapPortrait(bounds.width))
        let lastRowGap: CGFloat = (isLandscape ? rowGap : layoutConstants.rowGapPortraitLastRow(bounds.width))
        
        let flexibleEndRowM = (isLandscape ? layoutConstants.flexibleEndRowTotalWidthToKeyWidthMLandscape : layoutConstants.flexibleEndRowTotalWidthToKeyWidthMPortrait)
        let flexibleEndRowC = (isLandscape ? layoutConstants.flexibleEndRowTotalWidthToKeyWidthCLandscape : layoutConstants.flexibleEndRowTotalWidthToKeyWidthCPortrait)
        
        let lastRowLeftSideRatio = (isLandscape ? layoutConstants.lastRowLandscapeFirstTwoButtonAreaWidthToKeyboardAreaWidth : layoutConstants.lastRowPortraitFirstTwoButtonAreaWidthToKeyboardAreaWidth)
        let lastRowRightSideRatio = (isLandscape ? layoutConstants.lastRowLandscapeLastButtonAreaWidthToKeyboardAreaWidth : layoutConstants.lastRowPortraitLastButtonAreaWidthToKeyboardAreaWidth)
        let lastRowKeyGap = (isLandscape ? layoutConstants.lastRowKeyGapLandscape(bounds.width) : layoutConstants.lastRowKeyGapPortrait)
        
        let mostKeysInRow: Int = {
            var currentMax: Int = 0
            for page in model.pages {
                for (i, row) in enumerate(page.rows) {
                    currentMax = max(currentMax, row.count)
                }
            }
            return currentMax
        }()
        
        let charactersInDoubleSidedRowOnFirstPage: Int = {
            var currentMax: Int = 0
            for (i, row) in enumerate(model.pages[0].rows) {
                if self.doubleSidedRowHeuristic(row) {
                    currentMax = max(currentMax, row.count - 2)
                }
            }
            return currentMax
        }()
        
        for page in model.pages {
            let numRows = page.rows.count
            
            let rowGapTotal = CGFloat(numRows - 1 - 1) * rowGap + lastRowGap
            
            let keyGap: CGFloat = (isLandscape ? layoutConstants.keyGapLandscape(bounds.width, rowCharacterCount: mostKeysInRow) : layoutConstants.keyGapPortrait(bounds.width, rowCharacterCount: mostKeysInRow))
            
            let keyHeight: CGFloat = {
                let totalGaps = bottomEdge + topEdge + rowGapTotal
                var returnHeight = (bounds.height - totalGaps) / CGFloat(numRows)
                return self.rounded(returnHeight)
            }()
            
            let letterKeyWidth: CGFloat = {
                let totalGaps = (sideEdges * CGFloat(2)) + (keyGap * CGFloat(mostKeysInRow - 1))
                var returnWidth = (bounds.width - totalGaps) / CGFloat(mostKeysInRow)
                return self.rounded(returnWidth)
            }()
            
            for (r, row) in enumerate(page.rows) {
                let rowGapCurrentTotal = (r == page.rows.count - 1 ? rowGapTotal : CGFloat(r) * rowGap)
                let frame = CGRectMake(rounded(sideEdges), rounded(topEdge + (CGFloat(r) * keyHeight) + rowGapCurrentTotal), rounded(bounds.width - CGFloat(2) * sideEdges), rounded(keyHeight))
                
                // basic character row: only typable characters
                if self.characterRowHeuristic(row) {
                    self.layoutCharacterRow(row, modelToView: self.modelToView, keyWidth: letterKeyWidth, gapWidth: keyGap, frame: frame)
                }
                    
                // character row with side buttons: shift, backspace, etc.
                else if self.doubleSidedRowHeuristic(row) {
                    self.layoutCharacterWithSidesRow(row, modelToView: self.modelToView, keyWidth: letterKeyWidth, gapWidth: keyGap, mostCharactersInRowInAllPages: charactersInDoubleSidedRowOnFirstPage, m: flexibleEndRowM, c: flexibleEndRowC, frame: frame)
                }
                    
                // bottom row with things like space, return, etc.
                else {
                    self.layoutSpecialKeysRow(row, modelToView: self.modelToView, gapWidth: lastRowKeyGap, leftSideRatio: lastRowLeftSideRatio, rightSideRatio: lastRowRightSideRatio, frame: frame)
                }
            }
        }
    }
    
    func characterRowHeuristic(row: [Key]) -> Bool {
        return (row.count >= 1 && row[0].type == Key.KeyType.Character)
    }
    
    func doubleSidedRowHeuristic(row: [Key]) -> Bool {
        return (row.count >= 3 && row[0].type != Key.KeyType.Character && row[1].type == Key.KeyType.Character)
    }
    
    func layoutCharacterRow(row: [Key], modelToView: [Key:KeyboardKey], keyWidth: CGFloat, gapWidth: CGFloat, frame: CGRect) {
        let keySpace = CGFloat(row.count) * keyWidth + CGFloat(row.count - 1) * gapWidth
        let sideSpace = (frame.width - keySpace) / CGFloat(2)
        
        var currentOrigin = frame.origin.x + sideSpace
        for (k, key) in enumerate(row) {
            if let view = modelToView[key] {
                view.frame = CGRectMake(rounded(currentOrigin), frame.origin.y, keyWidth, frame.height)
                currentOrigin += (keyWidth + gapWidth)
            }
            else {
                assert(false, "view missing for model")
            }
        }
    }
    
    // TODO: pass in actual widths instead
    func layoutCharacterWithSidesRow(row: [Key], modelToView: [Key:KeyboardKey], keyWidth: CGFloat, gapWidth: CGFloat, mostCharactersInRowInAllPages: Int, m: CGFloat, c: CGFloat, frame: CGRect) {
        let keySpace = CGFloat(mostCharactersInRowInAllPages) * keyWidth + CGFloat(mostCharactersInRowInAllPages - 1) * gapWidth
        let numCharacters = row.count - 2
        let actualKeyWidth = (keySpace - CGFloat(numCharacters - 1) * gapWidth) / CGFloat(numCharacters)
        let sideSpace = (frame.width - keySpace) / CGFloat(2)
        
        var specialCharacterWidth = sideSpace * m + c
        specialCharacterWidth = max(specialCharacterWidth, keyWidth)
        specialCharacterWidth = rounded(specialCharacterWidth)
        let specialCharacterGap = sideSpace - specialCharacterWidth
        
        var currentOrigin = frame.origin.x
        for (k, key) in enumerate(row) {
            if let view = modelToView[key] {
                if k == 0 {
                    view.frame = CGRectMake(rounded(currentOrigin), frame.origin.y, specialCharacterWidth, frame.height)
                    currentOrigin += (specialCharacterWidth + specialCharacterGap)
                }
                else if k == row.count - 1 {
                    currentOrigin += specialCharacterGap
                    view.frame = CGRectMake(rounded(currentOrigin), frame.origin.y, specialCharacterWidth, frame.height)
                    currentOrigin += specialCharacterWidth
                }
                else {
                    view.frame = CGRectMake(rounded(currentOrigin), frame.origin.y, actualKeyWidth, frame.height)
                    if k == row.count - 2 {
                        currentOrigin += (actualKeyWidth)
                    }
                    else {
                        currentOrigin += (actualKeyWidth + gapWidth)
                    }
                }
            }
            else {
                assert(false, "view missing for model")
            }
        }
    }
    
    func layoutSpecialKeysRow(row: [Key], modelToView: [Key:KeyboardKey], gapWidth: CGFloat, leftSideRatio: CGFloat, rightSideRatio: CGFloat, frame: CGRect) {
        var keysBeforeSpace = 0
        var keysAfterSpace = 0
        var reachedSpace = false
        for (k, key) in enumerate(row) {
            if key.type == Key.KeyType.Space {
                reachedSpace = true
            }
            else {
                if !reachedSpace {
                    keysBeforeSpace += 1
                }
                else {
                    keysAfterSpace += 1
                }
            }
        }
        
        assert(keysBeforeSpace == 2, "invalid number of keys before space (only default 2 currently supported)")
        assert(keysAfterSpace == 1, "invalid number of keys after space (only default 1 currently supported)")
        
        let leftSideAreaWidth = frame.width * leftSideRatio
        let rightSideAreaWidth = frame.width * rightSideRatio
        var leftButtonWidth = (leftSideAreaWidth - (gapWidth * CGFloat(keysBeforeSpace - 1))) / CGFloat(keysBeforeSpace)
        leftButtonWidth = rounded(leftButtonWidth)
        var rightButtonWidth = (rightSideAreaWidth - (gapWidth * CGFloat(keysAfterSpace - 1))) / CGFloat(keysAfterSpace)
        rightButtonWidth = rounded(rightButtonWidth)
        var spaceWidth = frame.width - leftSideAreaWidth - rightSideAreaWidth - gapWidth * CGFloat(2)
        spaceWidth = rounded(spaceWidth)
        
        var currentOrigin = frame.origin.x
        var beforeSpace: Bool = true
        for (k, key) in enumerate(row) {
            if let view = modelToView[key] {
                if key.type == Key.KeyType.Space {
                    view.frame = CGRectMake(rounded(currentOrigin), frame.origin.y, spaceWidth, frame.height)
                    currentOrigin += (spaceWidth + gapWidth)
                    beforeSpace = false
                }
                else if beforeSpace {
                    view.frame = CGRectMake(rounded(currentOrigin), frame.origin.y, leftButtonWidth, frame.height)
                    currentOrigin += (leftButtonWidth + gapWidth)
                }
                else {
                    view.frame = CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth, frame.height)
                    currentOrigin += (rightButtonWidth + gapWidth)
                }
            }
            else {
                assert(false, "view missing for model")
            }
        }
    }
    
    ////////////////
    // END LAYOUT //
    ////////////////
    
    func frameForPopup(key: KeyboardKey, direction: Direction) -> CGRect {
        let actualScreenWidth = (UIScreen.mainScreen().nativeBounds.size.width / UIScreen.mainScreen().nativeScale)
        let totalHeight = layoutConstants.popupTotalHeight(actualScreenWidth)
        
        let popupWidth = key.bounds.width + layoutConstants.popupWidthIncrement
        let popupHeight = totalHeight - layoutConstants.popupGap - key.bounds.height
        let popupCenterY = 0
        
        return CGRectMake((key.bounds.width - popupWidth) / CGFloat(2), -popupHeight - layoutConstants.popupGap, popupWidth, popupHeight)
    }
    
    func willShowPopup(key: KeyboardKey, direction: Direction) {
        // TODO: actual numbers, not standins
        if let popup = key.popup {
            // TODO: total hack
            let actualSuperview = (self.superview.superview != nil ? self.superview.superview! : self.superview)
            
            var localFrame = actualSuperview.convertRect(popup.frame, fromView: popup.superview)
            
            if localFrame.origin.y < 3 {
                localFrame.origin.y = 3
                
                key.background.attached = Direction.Down
                key.connector?.startDir = Direction.Down
                key.background.hideDirectionIsOpposite = true
            }
            
            if localFrame.origin.x < 3 {
                localFrame.origin.x = key.frame.origin.x
            }
            
            if localFrame.origin.x + localFrame.width > superview.bounds.width - 3 {
                localFrame.origin.x = key.frame.origin.x + key.frame.width - localFrame.width
            }
            
            popup.frame = actualSuperview.convertRect(localFrame, toView: popup.superview)
        }
    }
    
    func willHidePopup(key: KeyboardKey) {
    }
}