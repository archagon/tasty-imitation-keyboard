//
//  KeyboardLayout.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/25/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// TODO: need to rename, consolidate, and define terms
class LayoutConstants: NSObject {
    class var landscapeRatio: CGFloat { get { return 2 }}
    
    // side edges increase on 6 in portrait
    class var sideEdgesPortraitArray: [CGFloat] { get { return [3, 4] }}
    class var sideEdgesPortraitWidthThreshholds: [CGFloat] { get { return [400] }}
    class var sideEdgesLandscape: CGFloat { get { return 3 }}
    
    // top edges decrease on various devices in portrait
    class var topEdgePortraitArray: [CGFloat] { get { return [12, 10, 8] }}
    class var topEdgePortraitWidthThreshholds: [CGFloat] { get { return [350, 400] }}
    class var topEdgeLandscape: CGFloat { get { return 6 }}
    
    // keyboard area shrinks in size in landscape on 6 and 6+
    class var keyboardShrunkSizeArray: [CGFloat] { get { return [522, 524] }}
    class var keyboardShrunkSizeWidthThreshholds: [CGFloat] { get { return [700] }}
    class var keyboardShrunkSizeBaseWidthThreshhold: CGFloat { get { return 600 }}
    
    // row gaps are weird on 6 in portrait
    class var rowGapPortraitArray: [CGFloat] { get { return [15, 11, 10] }}
    class var rowGapPortraitThreshholds: [CGFloat] { get { return [350, 400] }}
    class var rowGapPortraitLastRow: CGFloat { get { return 9 }}
    class var rowGapPortraitLastRowIndex: Int { get { return 1 }}
    class var rowGapLandscape: CGFloat { get { return 7 }}
    
    // key gaps have weird and inconsistent rules
    class var keyGapPortraitNormal: CGFloat { get { return 6 }}
    class var keyGapPortraitSmall: CGFloat { get { return 5 }}
    class var keyGapPortraitNormalThreshhold: CGFloat { get { return 350 }}
    class var keyGapPortraitUncompressThreshhold: CGFloat { get { return 350 }}
    class var keyGapLandscapeNormal: CGFloat { get { return 6 }}
    class var keyGapLandscapeSmall: CGFloat { get { return 5 }}
    // TODO: 5.5 row gap on 5L
    // TODO: wider row gap on 6L
    class var keyCompressedThreshhold: Int { get { return 11 }}
    
    // rows with two special keys on the side and characters in the middle (usually 3rd row)
    // TODO: these are not pixel-perfect, but should be correct within a few pixels
    // TODO: are there any "hidden constants" that would allow us to get rid of the multiplier? see: popup dimensions
    class var flexibleEndRowTotalWidthToKeyWidthMPortrait: CGFloat { get { return 1 }}
    class var flexibleEndRowTotalWidthToKeyWidthCPortrait: CGFloat { get { return -14 }}
    class var flexibleEndRowTotalWidthToKeyWidthMLandscape: CGFloat { get { return 0.9231 }}
    class var flexibleEndRowTotalWidthToKeyWidthCLandscape: CGFloat { get { return -9.4615 }}
    
    class var lastRowKeyGapPortrait: CGFloat { get { return 6 }}
    class var lastRowKeyGapLandscapeArray: [CGFloat] { get { return [8, 7, 5] }}
    class var lastRowKeyGapLandscapeWidthThreshholds: [CGFloat] { get { return [500, 700] }}
    
    // TODO: approxmiate, but close enough
    class var lastRowPortraitFirstTwoButtonAreaWidthToKeyboardAreaWidth: CGFloat { get { return 0.24 }}
    class var lastRowLandscapeFirstTwoButtonAreaWidthToKeyboardAreaWidth: CGFloat { get { return 0.19 }}
    class var lastRowPortraitLastButtonAreaWidthToKeyboardAreaWidth: CGFloat { get { return 0.24 }}
    class var lastRowLandscapeLastButtonAreaWidthToKeyboardAreaWidth: CGFloat { get { return 0.19 }}
    
    // TODO: not exactly precise
    class var popupGap: CGFloat { get { return 8 }}
    class var popupWidthIncrement: CGFloat { get { return 26 }}
    class var popupTotalHeightArray: [CGFloat] { get { return [102, 108] }}
    class var popupTotalHeightDeviceWidthThreshholds: [CGFloat] { get { return [350] }}
    
    class func sideEdgesPortrait(width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.sideEdgesPortraitArray, threshholds: self.sideEdgesPortraitWidthThreshholds, measurement: width)
    }
    class func topEdgePortrait(width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.topEdgePortraitArray, threshholds: self.topEdgePortraitWidthThreshholds, measurement: width)
    }
    class func rowGapPortrait(width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.rowGapPortraitArray, threshholds: self.rowGapPortraitThreshholds, measurement: width)
    }
    
    class func rowGapPortraitLastRow(width: CGFloat) -> CGFloat {
        let index = self.findThreshholdIndex(self.rowGapPortraitThreshholds, measurement: width)
        if index == self.rowGapPortraitLastRowIndex {
            return self.rowGapPortraitLastRow
        }
        else {
            return self.rowGapPortraitArray[index]
        }
    }
    
    class func keyGapPortrait(width: CGFloat, rowCharacterCount: Int) -> CGFloat {
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
    class func keyGapLandscape(width: CGFloat, rowCharacterCount: Int) -> CGFloat {
        let compressed = (rowCharacterCount >= self.keyCompressedThreshhold)
        let shrunk = self.keyboardIsShrunk(width)
        if compressed || shrunk {
            return self.keyGapLandscapeSmall
        }
        else {
            return self.keyGapLandscapeNormal
        }
    }
    
    class func lastRowKeyGapLandscape(width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.lastRowKeyGapLandscapeArray, threshholds: self.lastRowKeyGapLandscapeWidthThreshholds, measurement: width)
    }
    
    class func keyboardIsShrunk(width: CGFloat) -> Bool {
        let isPad = UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
        return (isPad ? false : width >= self.keyboardShrunkSizeBaseWidthThreshhold)
    }
    class func keyboardShrunkSize(width: CGFloat) -> CGFloat {
        let isPad = UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
        if isPad {
            return width
        }
        
        if width >= self.keyboardShrunkSizeBaseWidthThreshhold {
            return self.findThreshhold(self.keyboardShrunkSizeArray, threshholds: self.keyboardShrunkSizeWidthThreshholds, measurement: width)
        }
        else {
            return width
        }
    }
    
    class func popupTotalHeight(deviceWidth: CGFloat) -> CGFloat {
        return self.findThreshhold(self.popupTotalHeightArray, threshholds: self.popupTotalHeightDeviceWidthThreshholds, measurement: deviceWidth)
    }
    
    class func findThreshhold(elements: [CGFloat], threshholds: [CGFloat], measurement: CGFloat) -> CGFloat {
        assert(elements.count == threshholds.count + 1, "elements and threshholds do not match")
        return elements[self.findThreshholdIndex(threshholds, measurement: measurement)]
    }
    class func findThreshholdIndex(threshholds: [CGFloat], measurement: CGFloat) -> Int {
        for (i, threshhold) in enumerate(reverse(threshholds)) {
            if measurement >= threshhold {
                let actualIndex = threshholds.count - i
                return actualIndex
            }
        }
        return 0
    }
}

class GlobalColors: NSObject {
    class var lightModeRegularKey: UIColor { get { return UIColor.whiteColor() }}
    class var darkModeRegularKey: UIColor { get { return UIColor.grayColor().colorWithAlphaComponent(CGFloat(0.25)) }}
    class var darkModeSolidColorRegularKey: UIColor { get { return UIColor(red: CGFloat(83)/CGFloat(255), green: CGFloat(83)/CGFloat(255), blue: CGFloat(83)/CGFloat(255), alpha: 1) }}
    class var lightModeSpecialKey: UIColor { get { return UIColor.blackColor().colorWithAlphaComponent(CGFloat(0.25)) }}
    class var lightModeSolidColorSpecialKey: UIColor { get { return UIColor(red: CGFloat(180)/CGFloat(255), green: CGFloat(188)/CGFloat(255), blue: CGFloat(201)/CGFloat(255), alpha: 1) }}
    class var darkModeSpecialKey: UIColor { get { return UIColor.blackColor().colorWithAlphaComponent(CGFloat(0.25)) }}
    class var darkModeSolidColorSpecialKey: UIColor { get { return UIColor(red: CGFloat(45)/CGFloat(255), green: CGFloat(45)/CGFloat(255), blue: CGFloat(45)/CGFloat(255), alpha: 1) }}
    class var darkModeShiftKeyDown: UIColor { get { return UIColor(red: CGFloat(214)/CGFloat(255), green: CGFloat(220)/CGFloat(255), blue: CGFloat(208)/CGFloat(255), alpha: 1) }}
    class var lightModeUnderColor: UIColor { get { return UIColor(hue: (220/360.0), saturation: 0.04, brightness: 0.56, alpha: 1) }}
    class var darkModeUnderColor: UIColor { get { return UIColor(red: CGFloat(38.6)/CGFloat(255), green: CGFloat(18)/CGFloat(255), blue: CGFloat(39.3)/CGFloat(255), alpha: 0.4) }}
    class var lightModeTextColor: UIColor { get { return UIColor.blackColor() }}
    class var darkModeTextColor: UIColor { get { return UIColor.whiteColor() }}
    class var lightModeBorderColor: UIColor { get { return UIColor(hue: (214/360.0), saturation: 0.04, brightness: 0.65, alpha: 1.0) }}
    class var darkModeBorderColor: UIColor { get { return UIColor.clearColor() }}
    
    class func regularKey(darkMode: Bool, solidColorMode: Bool) -> UIColor {
        if darkMode {
            if solidColorMode {
                return self.darkModeSolidColorRegularKey
            }
            else {
                return self.darkModeRegularKey
            }
        }
        else {
            return self.lightModeRegularKey
        }
    }
    
    class func specialKey(darkMode: Bool, solidColorMode: Bool) -> UIColor {
        if darkMode {
            if solidColorMode {
                return self.darkModeSolidColorSpecialKey
            }
            else {
                return self.darkModeSpecialKey
            }
        }
        else {
            if solidColorMode {
                return self.lightModeSolidColorSpecialKey
            }
            else {
                return self.lightModeSpecialKey
            }
        }
    }
}

//"darkShadowColor": UIColor(hue: (220/360.0), saturation: 0.04, brightness: 0.56, alpha: 1),
//"blueColor": UIColor(hue: (211/360.0), saturation: 1.0, brightness: 1.0, alpha: 1),
//"blueShadowColor": UIColor(hue: (216/360.0), saturation: 0.05, brightness: 0.43, alpha: 1),

// handles the layout for the keyboard, including key spacing and arrangement
class KeyboardLayout: NSObject, KeyboardKeyProtocol {
    
    var layoutConstants: LayoutConstants.Type
    var globalColors: GlobalColors.Type
    
    var model: Keyboard
    var superview: UIView
    var modelToView: [Key:KeyboardKey] = [:]
    var viewToModel: [KeyboardKey:Key] = [:]
    var elements: [String:UIView] = [:]
    
    var darkMode: Bool
    var solidColorMode: Bool
    var initialized: Bool
    
    required init(model: Keyboard, superview: UIView, layoutConstants: LayoutConstants.Type, globalColors: GlobalColors.Type, darkMode: Bool, solidColorMode: Bool) {
        self.layoutConstants = layoutConstants
        self.globalColors = globalColors
        
        self.initialized = false
        self.model = model
        self.superview = superview
        
        self.darkMode = darkMode
        self.solidColorMode = solidColorMode
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
    
    func setAppearanceForKey(key: KeyboardKey, model: Key, darkMode: Bool, solidColorMode: Bool) {
        if model.type == Key.KeyType.Other {
            self.setAppearanceForOtherKey(key, model: model, darkMode: darkMode, solidColorMode: solidColorMode)
        }
        
        switch model.type {
        case
        Key.KeyType.Character,
        Key.KeyType.SpecialCharacter,
        Key.KeyType.Period:
            key.color = self.self.globalColors.regularKey(darkMode, solidColorMode: solidColorMode)
            key.textColor = (darkMode ? self.globalColors.darkModeTextColor : self.globalColors.lightModeTextColor)
            if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
                key.downColor = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            }
        case
        Key.KeyType.Space:
            key.color = self.globalColors.regularKey(darkMode, solidColorMode: solidColorMode)
            key.downColor = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            key.textColor = (darkMode ? self.globalColors.darkModeTextColor : self.globalColors.lightModeTextColor)
        case
        Key.KeyType.Shift:
            key.color = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            key.downColor = (darkMode ? self.globalColors.darkModeShiftKeyDown : self.globalColors.lightModeRegularKey)
            key.textColor = self.globalColors.darkModeTextColor
            key.downTextColor = self.globalColors.lightModeTextColor
        case
        Key.KeyType.Backspace:
            key.color = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            // TODO: actually a bit different
            key.downColor = self.globalColors.regularKey(darkMode, solidColorMode: solidColorMode)
            key.textColor = self.globalColors.darkModeTextColor
            key.downTextColor = (darkMode ? nil : self.globalColors.lightModeTextColor)
        case
        Key.KeyType.ModeChange:
            key.color = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            key.textColor = (darkMode ? self.globalColors.darkModeTextColor : self.globalColors.lightModeTextColor)
        case
        Key.KeyType.Return,
        Key.KeyType.KeyboardChange:
            key.color = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            // TODO: actually a bit different
            key.downColor = self.globalColors.regularKey(darkMode, solidColorMode: solidColorMode)
            key.textColor = (darkMode ? self.globalColors.darkModeTextColor : self.globalColors.lightModeTextColor)
        default:
            break
        }
        
        key.underColor = (self.darkMode ? self.globalColors.darkModeUnderColor : self.globalColors.lightModeUnderColor)
        key.borderColor = (self.darkMode ? self.globalColors.darkModeBorderColor : self.globalColors.lightModeBorderColor)
        
        // font sizing
        switch model.type {
        case
        Key.KeyType.ModeChange,
        Key.KeyType.Space,
        Key.KeyType.Return:
            key.label.adjustsFontSizeToFitWidth = true
            key.label.font = key.label.font.fontWithSize(16)
        default:
            break
        }
        
        // shapes
        switch model.type {
        case Key.KeyType.Shift:
            let shiftShape = ShiftShape()
            key.shape = shiftShape
        case Key.KeyType.Backspace:
            let backspaceShape = BackspaceShape()
            key.shape = backspaceShape
        case Key.KeyType.KeyboardChange:
            let globeShape = GlobeShape()
            key.shape = globeShape
        default:
            break
        }
    }
    
    func setAppearanceForOtherKey(key: KeyboardKey, model: Key, darkMode: Bool, solidColorMode: Bool) { /* override this to handle special keys */ }
    
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
                            
                            var keyView = self.createKey(key, vibrancy: key.isSpecial ? specialKeyVibrancy : normalKeyVibrancy)
                            
                            let keyViewName = "key\(j)x\(i)p\(h)"
                            keyView.enabled = true
                            keyView.text = key.keyCapForCase(false)
                            keyView.delegate = self
                            
                            self.superview.addSubview(keyView)
                            
                            self.elements[keyViewName] = keyView
                            self.modelToView[key] = keyView
                            self.viewToModel[keyView] = key
                            
                            self.setAppearanceForKey(keyView, model: key, darkMode: self.darkMode, solidColorMode: self.solidColorMode)
                        }
                    }
                }
            }
        }
    }
    
    // override to create custom keys
    func createKey(model: Key, vibrancy: VibrancyType?) -> KeyboardKey {
        return KeyboardKey(vibrancy: vibrancy)
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
            return (boundsRatio >= self.layoutConstants.landscapeRatio)
        }()
        
        var sideEdges = (isLandscape ? self.layoutConstants.sideEdgesLandscape : self.layoutConstants.sideEdgesPortrait(bounds.width))
        let bottomEdge = sideEdges
        
        let normalKeyboardSize = bounds.width - CGFloat(2) * sideEdges
        let shrunkKeyboardSize = self.layoutConstants.keyboardShrunkSize(normalKeyboardSize)
        
        sideEdges += ((normalKeyboardSize - shrunkKeyboardSize) / CGFloat(2))
        
        let topEdge: CGFloat = (isLandscape ? self.layoutConstants.topEdgeLandscape : self.layoutConstants.topEdgePortrait(bounds.width))
        
        let rowGap: CGFloat = (isLandscape ? self.layoutConstants.rowGapLandscape : self.layoutConstants.rowGapPortrait(bounds.width))
        let lastRowGap: CGFloat = (isLandscape ? rowGap : self.layoutConstants.rowGapPortraitLastRow(bounds.width))
        
        let flexibleEndRowM = (isLandscape ? self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthMLandscape : self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthMPortrait)
        let flexibleEndRowC = (isLandscape ? self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthCLandscape : self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthCPortrait)
        
        let lastRowLeftSideRatio = (isLandscape ? self.layoutConstants.lastRowLandscapeFirstTwoButtonAreaWidthToKeyboardAreaWidth : self.layoutConstants.lastRowPortraitFirstTwoButtonAreaWidthToKeyboardAreaWidth)
        let lastRowRightSideRatio = (isLandscape ? self.layoutConstants.lastRowLandscapeLastButtonAreaWidthToKeyboardAreaWidth : self.layoutConstants.lastRowPortraitLastButtonAreaWidthToKeyboardAreaWidth)
        let lastRowKeyGap = (isLandscape ? self.layoutConstants.lastRowKeyGapLandscape(bounds.width) : self.layoutConstants.lastRowKeyGapPortrait)
        
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
            
            let keyGap: CGFloat = (isLandscape ? self.layoutConstants.keyGapLandscape(bounds.width, rowCharacterCount: mostKeysInRow) : self.layoutConstants.keyGapPortrait(bounds.width, rowCharacterCount: mostKeysInRow))
            
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
        return (row.count >= 1 && row[0].isCharacter)
    }
    
    func doubleSidedRowHeuristic(row: [Key]) -> Bool {
        return (row.count >= 3 && !row[0].isCharacter && row[1].isCharacter)
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
        let totalHeight = self.layoutConstants.popupTotalHeight(actualScreenWidth)
        
        let popupWidth = key.bounds.width + self.layoutConstants.popupWidthIncrement
        let popupHeight = totalHeight - self.layoutConstants.popupGap - key.bounds.height
        let popupCenterY = 0
        
        return CGRectMake((key.bounds.width - popupWidth) / CGFloat(2), -popupHeight - self.layoutConstants.popupGap, popupWidth, popupHeight)
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
            else {
                // TODO: this needs to be reset somewhere
                key.background.hideDirectionIsOpposite = false
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