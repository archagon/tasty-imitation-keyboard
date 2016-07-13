//
//  KeyboardLayout.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/25/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
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
    class var keyboardShrunkSizeArray: [CGFloat] { get { return [660, 524] }}
    class var keyboardShrunkSizeWidthThreshholds: [CGFloat] { get { return [700] }}
    class var keyboardShrunkSizeBaseWidthThreshhold: CGFloat { get { return 740 }}
    
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
    class var keyGapLandscapeNormal: CGFloat { get { return 10 }}
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
    class var flexibleEndRowMinimumStandardCharacterWidth: CGFloat { get { return 7 }}
    
    class var lastRowKeyGapPortrait: CGFloat { get { return 6 }}
    class var lastRowKeyGapLandscapeArray: [CGFloat] { get { return [8, 7, 5] }}
    class var lastRowKeyGapLandscapeWidthThreshholds: [CGFloat] { get { return [500, 700] }}
    
    // TODO: approxmiate, but close enough
    class var lastRowPortraitFirstTwoButtonAreaWidthToKeyboardAreaWidth: CGFloat { get { return 0.24 }}
    class var lastRowLandscapeFirstTwoButtonAreaWidthToKeyboardAreaWidth: CGFloat { get { return 0.19 }}
    class var lastRowPortraitLastButtonAreaWidthToKeyboardAreaWidth: CGFloat { get { return 0.24 }}
    class var lastRowLandscapeLastButtonAreaWidthToKeyboardAreaWidth: CGFloat { get { return 0.19 }}
    class var micButtonPortraitWidthRatioToOtherSpecialButtons: CGFloat { get { return 0.765 }}
    
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
        for (i, threshhold) in Array(threshholds.reverse()).enumerate() {
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
    class var darkModeRegularKey: UIColor { get { return UIColor.whiteColor().colorWithAlphaComponent(CGFloat(0.3)) }}
    class var darkModeSolidColorRegularKey: UIColor { get { return UIColor(red: CGFloat(83)/CGFloat(255), green: CGFloat(83)/CGFloat(255), blue: CGFloat(83)/CGFloat(255), alpha: 1) }}
    class var lightModeSpecialKey: UIColor { get { return GlobalColors.lightModeSolidColorSpecialKey }}
    class var lightModeSolidColorSpecialKey: UIColor { get { return UIColor(red: CGFloat(177)/CGFloat(255), green: CGFloat(177)/CGFloat(255), blue: CGFloat(177)/CGFloat(255), alpha: 1) }}
    class var darkModeSpecialKey: UIColor { get { return UIColor.grayColor().colorWithAlphaComponent(CGFloat(0.3)) }}
    class var darkModeSolidColorSpecialKey: UIColor { get { return UIColor(red: CGFloat(45)/CGFloat(255), green: CGFloat(45)/CGFloat(255), blue: CGFloat(45)/CGFloat(255), alpha: 1) }}
    class var darkModeShiftKeyDown: UIColor { get { return UIColor(red: CGFloat(214)/CGFloat(255), green: CGFloat(220)/CGFloat(255), blue: CGFloat(208)/CGFloat(255), alpha: 1) }}
    class var lightModePopup: UIColor { get { return GlobalColors.lightModeRegularKey }}
    class var darkModePopup: UIColor { get { return UIColor.grayColor() }}
    class var darkModeSolidColorPopup: UIColor { get { return GlobalColors.darkModeSolidColorRegularKey }}
    
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
    
    class func popup(darkMode: Bool, solidColorMode: Bool) -> UIColor {
        if darkMode {
            if solidColorMode {
                return self.darkModeSolidColorPopup
            }
            else {
                return self.darkModePopup
            }
        }
        else {
            return self.lightModePopup
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

extension CGRect: Hashable {
    public var hashValue: Int {
        get {
            return (origin.x.hashValue ^ origin.y.hashValue ^ size.width.hashValue ^ size.height.hashValue)
        }
    }
}

extension CGSize: Hashable {
    public var hashValue: Int {
        get {
            return (width.hashValue ^ height.hashValue)
        }
    }
}

// handles the layout for the keyboard, including key spacing and arrangement
class KeyboardLayout: NSObject, KeyboardKeyProtocol {
    
    class var shouldPoolKeys: Bool { get { return true }}
    
    var layoutConstants: LayoutConstants.Type
    var globalColors: GlobalColors.Type
    
    unowned var model: Keyboard
    unowned var superview: UIView
    var modelToView: [Key:KeyboardKey] = [:]
    var viewToModel: [KeyboardKey:Key] = [:]
    
    var keyPool: [KeyboardKey] = []
    var nonPooledMap: [String:KeyboardKey] = [:]
    var sizeToKeyMap: [CGSize:[KeyboardKey]] = [:]
    var shapePool: [String:Shape] = [:]
    
    var darkMode: Bool
    var solidColorMode: Bool
    var initialized: Bool
    
    required init(model: Keyboard, superview: UIView, layoutConstants: LayoutConstants.Type, globalColors: GlobalColors.Type, darkMode: Bool, solidColorMode: Bool)
    {
        self.layoutConstants = layoutConstants
        self.globalColors = globalColors
        
        self.initialized = false
        self.model = model
        self.superview = superview
        
        self.darkMode = darkMode
        self.solidColorMode = solidColorMode
    }
    
    // TODO: remove this method
    func initialize()
    {
        assert(!self.initialized, "already initialized")
        self.initialized = true
    }
    
    func viewForKey(model: Key) -> KeyboardKey? {
        return self.modelToView[model]
    }
    
    func keyForView(key: KeyboardKey) -> Key? {
        return self.viewToModel[key]
    }
    
    //////////////////////////////////////////////
    // CALL THESE FOR LAYOUT/APPEARANCE CHANGES //
    //////////////////////////////////////////////
    
    func layoutKeys(pageNum: Int, uppercase: Bool, characterUppercase: Bool, shiftState: ShiftState) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // pre-allocate all keys if no cache
        if !self.dynamicType.shouldPoolKeys {
            if self.keyPool.isEmpty {
                for p in 0..<self.model.pages.count {
                    self.positionKeys(p)
                }
                self.updateKeyAppearance()
                self.updateKeyCaps(true, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: shiftState)
            }
        }
        
        self.positionKeys(pageNum)
        
        // reset state
        for (p, page) in self.model.pages.enumerate() {
            for (_, row) in page.rows.enumerate() {
                for (_, key) in row.enumerate() {
                    if let keyView = self.modelToView[key] {
                        keyView.hidePopup()
                        
                        //keyView.hideLongPress()
                        keyView.highlighted = false
                        keyView.hidden = (p != pageNum)
                    }
                }
            }
        }
        
        if self.dynamicType.shouldPoolKeys {
            self.updateKeyAppearance()
            self.updateKeyCaps(true, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: shiftState)
        }
        
        CATransaction.commit()
    }
    
    func positionKeys(pageNum: Int) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let setupKey = { (view: KeyboardKey, model: Key, frame: CGRect) -> Void in
            view.frame = frame
            self.modelToView[model] = view
            self.viewToModel[view] = model
        }
        
        if var keyMap = self.generateKeyFrames(self.model, bounds: self.superview.bounds, page: pageNum) {
            if self.dynamicType.shouldPoolKeys {
                self.modelToView.removeAll(keepCapacity: true)
                self.viewToModel.removeAll(keepCapacity: true)
                
                self.resetKeyPool()
                
                var foundCachedKeys = [Key]()
                
                // pass 1: reuse any keys that match the required size
                for (key, frame) in keyMap {
                    if let keyView = self.pooledKey(key: key, model: self.model, frame: frame) {
                        foundCachedKeys.append(key)
                        setupKey(keyView, key, frame)
                    }
                }
                
               let _ = foundCachedKeys.map {
                    keyMap.removeValueForKey($0)
                }
                
                // pass 2: fill in the blanks
                for (key, frame) in keyMap {
                    let keyView = self.generateKey()
                    setupKey(keyView, key, frame)
                }
            }
            else {
                for (key, frame) in keyMap {
                    if let keyView = self.pooledKey(key: key, model: self.model, frame: frame) {
                        setupKey(keyView, key, frame)
                    }
                }
            }
        }
        
        CATransaction.commit()
    }
    
    func updateKeyAppearance() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        for (key, view) in self.modelToView {
            self.setAppearanceForKey(view, model: key, darkMode: self.darkMode, solidColorMode: self.solidColorMode)
        }
        
        CATransaction.commit()
    }
    
    // on fullReset, we update the keys with shapes, images, etc. as if from scratch; otherwise, just update the text
    // WARNING: if key cache is disabled, DO NOT CALL WITH fullReset MORE THAN ONCE
    func updateKeyCaps(fullReset: Bool, uppercase: Bool, characterUppercase: Bool, shiftState: ShiftState) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if fullReset {
            for (_, key) in self.modelToView {
                key.shape = nil
                
                if let imageKey = key as? ImageKey { // TODO:
                    imageKey.image = nil
                }
            }
        }
        
        for (model, key) in self.modelToView {
            self.updateKeyCap(key, model: model, fullReset: fullReset, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: shiftState)
        }
        
        CATransaction.commit()
    }
    
    func updateKeyCap(key: KeyboardKey, model: Key, fullReset: Bool, uppercase: Bool, characterUppercase: Bool, shiftState: ShiftState) {
        if fullReset {
            // font size
            switch model.type {
            case
            Key.KeyType.ModeChange,
            Key.KeyType.Space,
            Key.KeyType.Return:
                key.label.adjustsFontSizeToFitWidth = true
                key.label.font = key.label.font.fontWithSize(16)
            default:
                key.label.font = key.label.font.fontWithSize(22)
            }
            
            // label inset
            switch model.type {
            case
            Key.KeyType.ModeChange:
                key.labelInset = 3
            default:
                key.labelInset = 0
            }
            
            // shapes
            switch model.type {
            case Key.KeyType.Shift:
                if key.shape == nil {
                    let shiftShape = self.getShape(ShiftShape)
                    key.shape = shiftShape
                }
            case Key.KeyType.Backspace:
                if key.shape == nil {
                    let backspaceShape = self.getShape(BackspaceShape)
                    key.shape = backspaceShape
                }
            case Key.KeyType.KeyboardChange:
                if key.shape == nil {
                    let globeShape = self.getShape(GlobeShape)
                    key.shape = globeShape
                }
            default:
                break
            }
            
            // images
            if model.type == Key.KeyType.Settings {
                if let imageKey = key as? ImageKey {
                    if imageKey.image == nil {
                        let gearImage = UIImage(named: "gear")
                        let settingsImageView = UIImageView(image: gearImage)
                        imageKey.image = settingsImageView
                    }
                }
            }
        }
        
        if model.type == Key.KeyType.Shift {
            if key.shape == nil {
                let shiftShape = self.getShape(ShiftShape)
                key.shape = shiftShape
            }
            
            switch shiftState {
            case .Disabled:
                key.highlighted = false
            case .Enabled:
                key.highlighted = true
            case .Locked:
                key.highlighted = true
            }
            
            (key.shape as? ShiftShape)?.withLock = (shiftState == .Locked)
        }
        
        self.updateKeyCapText(key, model: model, uppercase: uppercase, characterUppercase: characterUppercase)
    }
    
    func updateKeyCapText(key: KeyboardKey, model: Key, uppercase: Bool, characterUppercase: Bool) {
        if model.type == .Character {
            key.text = model.keyCapForCase(characterUppercase)
        }
        else {
            key.text = model.keyCapForCase(uppercase)
        }
    }
    
    ///////////////
    // END CALLS //
    ///////////////
    
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
            if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
                key.downColor = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            }
            else {
                key.downColor = nil
            }
            key.textColor = (darkMode ? self.globalColors.darkModeTextColor : self.globalColors.lightModeTextColor)
            key.downTextColor = nil
        case
        Key.KeyType.Space:
            key.color = self.globalColors.regularKey(darkMode, solidColorMode: solidColorMode)
            //key.downColor = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            
            key.downColor = UIColor(red:0.68, green:0.71, blue:0.74, alpha:1)
            
            key.textColor = (darkMode ? self.globalColors.darkModeTextColor : self.globalColors.lightModeTextColor)
            key.downTextColor = nil
        case
        Key.KeyType.Shift:
           // key.color = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            
            key.color = UIColor(red:0.68, green:0.71, blue:0.74, alpha:1)
            
            key.downColor = (darkMode ? self.globalColors.darkModeShiftKeyDown : self.globalColors.lightModeRegularKey)
            key.textColor = self.globalColors.darkModeTextColor
            key.downTextColor = self.globalColors.lightModeTextColor
        case
        Key.KeyType.Backspace:
            //key.color = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            
            key.color = UIColor(red:0.68, green:0.71, blue:0.74, alpha:1)
            
            // TODO: actually a bit different
            key.downColor = self.globalColors.regularKey(darkMode, solidColorMode: solidColorMode)
            key.textColor = self.globalColors.darkModeTextColor
            key.downTextColor = (darkMode ? nil : self.globalColors.lightModeTextColor)
        case
        Key.KeyType.ModeChange:
            //key.color = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            
            key.color = UIColor(red:0.68, green:0.71, blue:0.74, alpha:1)
            
            key.downColor = nil
            key.textColor = (darkMode ? self.globalColors.darkModeTextColor : self.globalColors.lightModeTextColor)
            key.downTextColor = nil
        case
        Key.KeyType.Return,
        Key.KeyType.KeyboardChange,
        Key.KeyType.Settings:
            //key.color = self.globalColors.specialKey(darkMode, solidColorMode: solidColorMode)
            
            key.color = UIColor(red:0.68, green:0.71, blue:0.74, alpha:1)
            
            // TODO: actually a bit different
            key.downColor = self.globalColors.regularKey(darkMode, solidColorMode: solidColorMode)
            key.textColor = (darkMode ? self.globalColors.darkModeTextColor : self.globalColors.lightModeTextColor)
            key.downTextColor = nil
        default:
            break
        }
        
        key.popupColor = self.globalColors.popup(darkMode, solidColorMode: solidColorMode)
        key.underColor = (self.darkMode ? self.globalColors.darkModeUnderColor : self.globalColors.lightModeUnderColor)
        key.borderColor = (self.darkMode ? self.globalColors.darkModeBorderColor : self.globalColors.lightModeBorderColor)
    }
    
    func setAppearanceForOtherKey(key: KeyboardKey, model: Key, darkMode: Bool, solidColorMode: Bool) { /* override this to handle special keys */ }
    
    // TODO: avoid array copies
    // TODO: sizes stored not rounded?
    
    ///////////////////////////
    // KEY POOLING FUNCTIONS //
    ///////////////////////////
    
    // if pool is disabled, always returns a unique key view for the corresponding key model
    func pooledKey(key aKey: Key, model: Keyboard, frame: CGRect) -> KeyboardKey? {
        if !self.dynamicType.shouldPoolKeys {
            var p: Int!
            var r: Int!
            var k: Int!
            
            // TODO: O(N^2) in terms of total # of keys since pooledKey is called for each key, but probably doesn't matter
            var foundKey: Bool = false
            for (pp, page) in model.pages.enumerate() {
                for (rr, row) in page.rows.enumerate() {
                    for (kk, key) in row.enumerate() {
                        if key == aKey {
                            p = pp
                            r = rr
                            k = kk
                            foundKey = true
                        }
                        if foundKey {
                            break
                        }
                    }
                    if foundKey {
                        break
                    }
                }
                if foundKey {
                    break
                }
            }
            
            let id = "p\(p)r\(r)k\(k)"
            if let key = self.nonPooledMap[id] {
                return key
            }
            else {
                let key = generateKey()
                self.nonPooledMap[id] = key
                return key
            }
        }
        else {
            if var keyArray = self.sizeToKeyMap[frame.size] {
                if let key = keyArray.last {
                    if keyArray.count == 1 {
                        self.sizeToKeyMap.removeValueForKey(frame.size)
                    }
                    else {
                        keyArray.removeLast()
                        self.sizeToKeyMap[frame.size] = keyArray
                    }
                    return key
                }
                else {
                    return nil
                }
                
            }
            else {
                return nil
            }
        }
    }
    
    func createNewKey() -> KeyboardKey {
        return ImageKey(vibrancy: nil)
    }
    
    // if pool is disabled, always generates a new key
    func generateKey() -> KeyboardKey {
        let createAndSetupNewKey = { () -> KeyboardKey in
            let keyView = self.createNewKey()
            
            keyView.enabled = true
            keyView.delegate = self
            
            self.superview.addSubview(keyView)
            
            self.keyPool.append(keyView)
            
            return keyView
        }
        
        if self.dynamicType.shouldPoolKeys {
            if !self.sizeToKeyMap.isEmpty {
                var (size, keyArray) = self.sizeToKeyMap[self.sizeToKeyMap.startIndex]
                
                if let key = keyArray.last {
                    if keyArray.count == 1 {
                        self.sizeToKeyMap.removeValueForKey(size)
                    }
                    else {
                        keyArray.removeLast()
                        self.sizeToKeyMap[size] = keyArray
                    }
                    
                    return key
                }
                else {
                    return createAndSetupNewKey()
                }
            }
            else {
                return createAndSetupNewKey()
            }
        }
        else {
            return createAndSetupNewKey()
        }
    }
    
    // if pool is disabled, doesn't do anything
    func resetKeyPool() {
        if self.dynamicType.shouldPoolKeys {
            self.sizeToKeyMap.removeAll(keepCapacity: true)
            
            for key in self.keyPool {
                if var keyArray = self.sizeToKeyMap[key.frame.size] {
                    keyArray.append(key)
                    self.sizeToKeyMap[key.frame.size] = keyArray
                }
                else {
                    var keyArray = [KeyboardKey]()
                    keyArray.append(key)
                    self.sizeToKeyMap[key.frame.size] = keyArray
                }
                key.hidden = true
            }
        }
    }
    
    // TODO: no support for more than one of the same shape
    // if pool disabled, always returns new shape
    func getShape(shapeClass: Shape.Type) -> Shape {
        let className = NSStringFromClass(shapeClass)
        
        if self.dynamicType.shouldPoolKeys {
            if let shape = self.shapePool[className] {
                return shape
            }
            else {
                let shape = shapeClass.init(frame: CGRectZero)
                self.shapePool[className] = shape
                return shape
            }
        }
        else {
            return shapeClass.init(frame: CGRectZero)
        }
    }
    
    //////////////////////
    // LAYOUT FUNCTIONS //
    //////////////////////
    
    func rounded(measurement: CGFloat) -> CGFloat {
        return round(measurement * UIScreen.mainScreen().scale) / UIScreen.mainScreen().scale
    }
    
    func generateKeyFrames(model: Keyboard, bounds: CGRect, page pageToLayout: Int) -> [Key:CGRect]? {
        if bounds.height == 0 || bounds.width == 0 {
            return nil
        }
        
        var keyMap = [Key:CGRect]()
        
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
        
        //let flexibleEndRowM = (isLandscape ? self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthMLandscape : self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthMPortrait)
        //let flexibleEndRowC = (isLandscape ? self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthCLandscape : self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthCPortrait)
        
        let lastRowLeftSideRatio = (isLandscape ? self.layoutConstants.lastRowLandscapeFirstTwoButtonAreaWidthToKeyboardAreaWidth : self.layoutConstants.lastRowPortraitFirstTwoButtonAreaWidthToKeyboardAreaWidth)
        let lastRowRightSideRatio = (isLandscape ? self.layoutConstants.lastRowLandscapeLastButtonAreaWidthToKeyboardAreaWidth : self.layoutConstants.lastRowPortraitLastButtonAreaWidthToKeyboardAreaWidth)
        let lastRowKeyGap = (isLandscape ? self.layoutConstants.lastRowKeyGapLandscape(bounds.width) : self.layoutConstants.lastRowKeyGapPortrait)
        
        for (p, page) in model.pages.enumerate() {
            if p != pageToLayout {
                continue
            }
            
            let numRows = page.rows.count
            
            let mostKeysInRow: Int = {
                var currentMax: Int = 0
                for (_, row) in page.rows.enumerate() {
                    currentMax = max(currentMax, row.count)
                }
                return currentMax
            }()
            
            let rowGapTotal = CGFloat(numRows - 1 - 1) * rowGap + lastRowGap
            
            let keyGap: CGFloat = (isLandscape ? self.layoutConstants.keyGapLandscape(bounds.width, rowCharacterCount: mostKeysInRow) : self.layoutConstants.keyGapPortrait(bounds.width, rowCharacterCount: mostKeysInRow))
            
            let keyHeight: CGFloat = {
                let totalGaps = bottomEdge + topEdge + rowGapTotal
                let returnHeight = (bounds.height - totalGaps) / CGFloat(numRows)
                return self.rounded(returnHeight)
                }()
            
            let letterKeyWidth: CGFloat = {
                let totalGaps = (sideEdges * CGFloat(2)) + (keyGap * CGFloat(mostKeysInRow - 1))
                let returnWidth = (bounds.width - totalGaps) / CGFloat(mostKeysInRow)
                return self.rounded(returnWidth)
                }()
            
            let processRow = { (row: [Key], frames: [CGRect], inout map: [Key:CGRect]) -> Void in
                assert(row.count == frames.count, "row and frames don't match")
                for (k, key) in row.enumerate() {
                    map[key] = frames[k]
                }
            }
            
            for (r, row) in page.rows.enumerate() {
                let rowGapCurrentTotal = (r == page.rows.count - 1 ? rowGapTotal : CGFloat(r) * rowGap)
                let frame = CGRectMake(rounded(sideEdges), rounded(topEdge + (CGFloat(r) * keyHeight) + rowGapCurrentTotal), rounded(bounds.width - CGFloat(2) * sideEdges), rounded(keyHeight))
                
                var frames: [CGRect]!
                
                // basic character row: only typable characters
                if self.characterRowHeuristic(row) {
                    frames = self.layoutCharacterRow(row, keyWidth: letterKeyWidth, gapWidth: keyGap, frame: frame)
                }
                    
                    // character row with side buttons: shift, backspace, etc.
                else if self.doubleSidedRowHeuristic(row) {
                    frames = self.layoutCharacterWithSidesRow(row, frame: frame, isLandscape: isLandscape, keyWidth: letterKeyWidth, keyGap: keyGap)
                }
                    
                    // bottom row with things like space, return, etc.
                else {
                    frames = self.layoutSpecialKeysRow(row, keyWidth: letterKeyWidth, gapWidth: lastRowKeyGap, leftSideRatio: lastRowLeftSideRatio, rightSideRatio: lastRowRightSideRatio, micButtonRatio: self.layoutConstants.micButtonPortraitWidthRatioToOtherSpecialButtons, isLandscape: isLandscape, frame: frame)
                }
                
                processRow(row, frames, &keyMap)
            }
        }
        
        return keyMap
    }
    
    func characterRowHeuristic(row: [Key]) -> Bool {
        return (row.count >= 1 && row[0].isCharacter)
    }
    
    func doubleSidedRowHeuristic(row: [Key]) -> Bool {
        return (row.count >= 3 && !row[0].isCharacter && row[1].isCharacter)
    }
    
    func layoutCharacterRow(row: [Key], keyWidth: CGFloat, gapWidth: CGFloat, frame: CGRect) -> [CGRect] {
        var frames = [CGRect]()
        
        let keySpace = CGFloat(row.count) * keyWidth + CGFloat(row.count - 1) * gapWidth
        var actualGapWidth = gapWidth
        var sideSpace = (frame.width - keySpace) / CGFloat(2)
        
        // TODO: port this to the other layout functions
        // avoiding rounding errors
        if sideSpace < 0 {
            sideSpace = 0
            actualGapWidth = (frame.width - (CGFloat(row.count) * keyWidth)) / CGFloat(row.count - 1)
        }
        
        var currentOrigin = frame.origin.x + sideSpace
        
        for (_, _) in row.enumerate() {
            let roundedOrigin = rounded(currentOrigin)
            
            // avoiding rounding errors
            if roundedOrigin + keyWidth > frame.origin.x + frame.width {
                frames.append(CGRectMake(rounded(frame.origin.x + frame.width - keyWidth), frame.origin.y, keyWidth, frame.height))
            }
            else {
                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, keyWidth, frame.height))
            }
            
            currentOrigin += (keyWidth + actualGapWidth)
        }
        
        return frames
    }
    
    // TODO: pass in actual widths instead
    func layoutCharacterWithSidesRow(row: [Key], frame: CGRect, isLandscape: Bool, keyWidth: CGFloat, keyGap: CGFloat) -> [CGRect] {
        var frames = [CGRect]()

        let standardFullKeyCount = Int(self.layoutConstants.keyCompressedThreshhold) - 1
        let standardGap = (isLandscape ? self.layoutConstants.keyGapLandscape : self.layoutConstants.keyGapPortrait)(frame.width, rowCharacterCount: standardFullKeyCount)
        let sideEdges = (isLandscape ? self.layoutConstants.sideEdgesLandscape : self.layoutConstants.sideEdgesPortrait(frame.width))
        var standardKeyWidth = (frame.width - sideEdges - (standardGap * CGFloat(standardFullKeyCount - 1)) - sideEdges)
        standardKeyWidth /= CGFloat(standardFullKeyCount)
        let standardKeyCount = self.layoutConstants.flexibleEndRowMinimumStandardCharacterWidth
        
        let standardWidth = CGFloat(standardKeyWidth * standardKeyCount + standardGap * (standardKeyCount - 1))
        let currentWidth = CGFloat(row.count - 2) * keyWidth + CGFloat(row.count - 3) * keyGap
        
        let isStandardWidth = (currentWidth < standardWidth)
        let actualWidth = (isStandardWidth ? standardWidth : currentWidth)
        let actualGap = (isStandardWidth ? standardGap : keyGap)
        let actualKeyWidth = (actualWidth - CGFloat(row.count - 3) * actualGap) / CGFloat(row.count - 2)
        
        let sideSpace = (frame.width - actualWidth) / CGFloat(2)
        
        let m = (isLandscape ? self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthMLandscape : self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthMPortrait)
        let c = (isLandscape ? self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthCLandscape : self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthCPortrait)
        
        var specialCharacterWidth = sideSpace * m + c
        specialCharacterWidth = max(specialCharacterWidth, keyWidth)
        specialCharacterWidth = rounded(specialCharacterWidth)
        let specialCharacterGap = sideSpace - specialCharacterWidth
        
        var currentOrigin = frame.origin.x
        for (k, _) in row.enumerate() {
            if k == 0 {
                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, specialCharacterWidth, frame.height))
                currentOrigin += (specialCharacterWidth + specialCharacterGap)
            }
            else if k == row.count - 1 {
                currentOrigin += specialCharacterGap
                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, specialCharacterWidth, frame.height))
                currentOrigin += specialCharacterWidth
            }
            else {
                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, actualKeyWidth, frame.height))
                if k == row.count - 2 {
                    currentOrigin += (actualKeyWidth)
                }
                else {
                    currentOrigin += (actualKeyWidth + keyGap)
                }
            }
        }

        return frames
    }
    
    func layoutSpecialKeysRow(row: [Key], keyWidth: CGFloat, gapWidth: CGFloat, leftSideRatio: CGFloat, rightSideRatio: CGFloat, micButtonRatio: CGFloat, isLandscape: Bool, frame: CGRect) -> [CGRect] {
        var frames = [CGRect]()
        
        var keysBeforeSpace = 0
        var keysAfterSpace = 0
        var reachedSpace = false
        for (_, key) in row.enumerate() {
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
        
//        assert(keysBeforeSpace <= 3, "invalid number of keys before space (only max 3 currently supported)")
//        assert(keysAfterSpace == 1, "invalid number of keys after space (only default 1 currently supported)")
		
        let hasButtonInMicButtonPosition = (keysBeforeSpace == 3)
		
		let hasButtonInDotButtonPosition = (keysAfterSpace == 2)
		
		let hasButtonInAtButtonPosition = (keysAfterSpace == 3)
        
        var leftSideAreaWidth = frame.width * leftSideRatio
        let rightSideAreaWidth = frame.width * rightSideRatio
        var leftButtonWidth = (leftSideAreaWidth - (gapWidth * CGFloat(2 - 1))) / CGFloat(2)
        leftButtonWidth = rounded(leftButtonWidth)
        var rightButtonWidth = (rightSideAreaWidth - (gapWidth * CGFloat(keysAfterSpace - 1))) / CGFloat(keysAfterSpace)
        rightButtonWidth = rounded(rightButtonWidth)
        
        let micButtonWidth = (isLandscape ? leftButtonWidth : leftButtonWidth * micButtonRatio)
		
		let dotButtonWidth = (isLandscape ? rightButtonWidth : leftButtonWidth * micButtonRatio)
		
		let atButtonWidth = (isLandscape ? rightButtonWidth : leftButtonWidth * micButtonRatio)
		
        // special case for mic button
        if hasButtonInMicButtonPosition {
            leftSideAreaWidth = leftSideAreaWidth + gapWidth + micButtonWidth
        }
        
        var spaceWidth = frame.width - leftSideAreaWidth - rightSideAreaWidth - gapWidth * CGFloat(2)
		
        spaceWidth = rounded(spaceWidth)
		
		if hasButtonInDotButtonPosition
		{
			spaceWidth -= 20
		}
		
		if hasButtonInAtButtonPosition
		{
			spaceWidth -= 40
		}
		
        var currentOrigin = frame.origin.x
        var beforeSpace: Bool = true
        for (k, key) in row.enumerate() {
            if key.type == Key.KeyType.Space {
				
                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, spaceWidth , frame.height))
                currentOrigin += (spaceWidth + gapWidth)
                beforeSpace = false
            }
            else if beforeSpace {
                if hasButtonInMicButtonPosition && k == 2 { //mic button position
                    frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, micButtonWidth, frame.height))
                    currentOrigin += (micButtonWidth + gapWidth)
                }
                else {
					
                    frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, leftButtonWidth, frame.height))
                    currentOrigin += (leftButtonWidth + gapWidth)
                    
                }
            }
            else
			{
				if hasButtonInDotButtonPosition && k == 4
				{
					frames.append(CGRectMake(rounded(currentOrigin),
                        frame.origin.y,
                        dotButtonWidth,
                        frame.height))
                    
					currentOrigin += (dotButtonWidth + gapWidth)
				}
                else if hasButtonInDotButtonPosition && k == 5
                {
                    
                    if(isLandscape == true)
                    {
                        if(UIScreen.mainScreen().bounds.width == 736 && rightButtonWidth >= 67) // 6plus original
                        {
                            frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.29, frame.height))
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }
                        else if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
                        {
                            if(rightButtonWidth == 70)
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.3, frame.height))

                            }
                            else // rightButtonWidth = 94 (ipad landscape)
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.22, frame.height))
                            }
                            
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }
                        else if(UIScreen.mainScreen().bounds.width == 736 && rightButtonWidth >= 41) //6plus without splash
                        {
                            frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.5, frame.height))
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }
                        else if(UIScreen.mainScreen().bounds.width == 667 && rightButtonWidth == 41) //6 without splash
                        {
                            frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.47, frame.height))
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }
                        else if(UIScreen.mainScreen().bounds.width == 667 && rightButtonWidth >= 59) //6 original
                        {
                            frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.32, frame.height))
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }
                        else if(UIScreen.mainScreen().bounds.width == 480 && rightButtonWidth >= 41) //6 original
                        {
                            frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.48, frame.height))
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }
                        else
                        {
                            frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.4, frame.height))
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }
                    }
                    else
                    {
                        if(UIScreen.mainScreen().bounds.width == 414 && rightButtonWidth >= 45)
                        {
                            frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.65, frame.height))
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }
                        else if(UIScreen.mainScreen().bounds.width == 414 && rightButtonWidth >= 28)
                        {
                            frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.8, frame.height))
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }
                        else if(UIScreen.mainScreen().bounds.width == 375 && rightButtonWidth >= 41)
                        {
                            frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.7, frame.height))
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }
                        else if(UIScreen.mainScreen().bounds.width == 375 && rightButtonWidth >= 25)
                        {
                            frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.8, frame.height))
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }
                        else
                        {
                            frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.82, frame.height))
                            currentOrigin += (rightButtonWidth + gapWidth)
                        }

                    }
                    
                }
				else if hasButtonInAtButtonPosition
				{
					if k == 4
					{
						frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, atButtonWidth, frame.height))
						currentOrigin += (atButtonWidth + gapWidth)
					}
					else if k == 5
					{
						frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, dotButtonWidth, frame.height))
						currentOrigin += (dotButtonWidth + gapWidth)
					}
                    else if k == 6
                    {
                        // intro button constarints for iPhone 6 and 6plus
                        
                        if(isLandscape)
                        {
                            if(UIScreen.mainScreen().bounds.width == 736 && rightButtonWidth == 43)
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.9, frame.height))
                                currentOrigin += (rightButtonWidth + gapWidth)
                            }
                            else if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
                            {
                                if(rightButtonWidth == 45)
                                {
                                    frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.88, frame.height))
                                }
                                else // ipad landscape
                                {
                                    frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 1.68, frame.height))
                                }
                                
                            }
                            else if(UIScreen.mainScreen().bounds.width == 736 && rightButtonWidth >= 21)
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 2.6, frame.height))
                                currentOrigin += (rightButtonWidth + gapWidth)
                            }
                            else if(UIScreen.mainScreen().bounds.width == 667 && rightButtonWidth == 37)
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 2.1, frame.height))
                                currentOrigin += (rightButtonWidth + gapWidth)
                            }
                            else if(UIScreen.mainScreen().bounds.width == 667 && rightButtonWidth >= 24)
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 2.65, frame.height))
                                currentOrigin += (rightButtonWidth + gapWidth)
                            }
                            else if(UIScreen.mainScreen().bounds.width == 480 && rightButtonWidth >= 24)
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 2.67, frame.height))
                                currentOrigin += (rightButtonWidth + gapWidth)
                            }

                            else
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth*2.3, frame.height))
                                currentOrigin += (rightButtonWidth + gapWidth)
                            }

                        }
                        else
                        {
                            if(UIScreen.mainScreen().bounds.width == 414 && rightButtonWidth == 21)
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 2.4, frame.height))
                                currentOrigin += (rightButtonWidth + gapWidth)
                            }
                            else if(UIScreen.mainScreen().bounds.width == 414 && rightButtonWidth >= 28)
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 2.0, frame.height))
                                currentOrigin += (rightButtonWidth + gapWidth)
                            }
                            else if(UIScreen.mainScreen().bounds.width == 375 && rightButtonWidth == 21)
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 2.4, frame.height))
                                currentOrigin += (rightButtonWidth + gapWidth)
                            }
                            else if(UIScreen.mainScreen().bounds.width == 375 && rightButtonWidth >= 25)
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth * 2.1, frame.height))
                                currentOrigin += (rightButtonWidth + gapWidth)
                            }
                            else
                            {
                                frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth*2.4, frame.height))
                                currentOrigin += (rightButtonWidth + gapWidth)
                            }

                        }
                        
           
                    }
					else
					{
						let widthTotal = UIScreen.mainScreen().bounds.width
						
						let widthOfSpace = widthTotal - rounded(currentOrigin) - (gapWidth/2)
						
						frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, widthOfSpace, frame.height))
						currentOrigin += (rightButtonWidth + gapWidth)
                        
                    }
					
				}
				else
				{
					if hasButtonInDotButtonPosition
					{
						let widthTotal = UIScreen.mainScreen().bounds.width
						
						let widthOfSpace = widthTotal - rounded(currentOrigin) - (gapWidth/2)
						
						frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, widthOfSpace, frame.height))
						currentOrigin += (rightButtonWidth + gapWidth)
					}
					else if hasButtonInAtButtonPosition
					{
						let widthTotal = UIScreen.mainScreen().bounds.width
						
						let widthOfSpace = widthTotal - rounded(currentOrigin) - (gapWidth/2)
						
						frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, widthOfSpace, frame.height))
						currentOrigin += (rightButtonWidth + gapWidth)
					}
					else
					{
						frames.append(CGRectMake(rounded(currentOrigin), frame.origin.y, rightButtonWidth, frame.height))
						currentOrigin += (rightButtonWidth + gapWidth)
					}
					
				}
				
				
            }
        }

        return frames
    }
    
    ////////////////
    // END LAYOUT //
    ////////////////
    
    func frameForPopup(key: KeyboardKey, direction: Direction) -> CGRect {
        let actualScreenWidth = (UIScreen.mainScreen().nativeBounds.size.width / UIScreen.mainScreen().nativeScale)
        let totalHeight = self.layoutConstants.popupTotalHeight(actualScreenWidth)
        
        let popupWidth = key.bounds.width + self.layoutConstants.popupWidthIncrement
        let popupHeight = totalHeight - self.layoutConstants.popupGap - key.bounds.height
        //let popupCenterY = 0
        
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
