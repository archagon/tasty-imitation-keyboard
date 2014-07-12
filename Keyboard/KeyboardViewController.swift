//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit
//import KeyboardFramework

let layout = [
    "leftGap": 3,
    "rightGap": 3,
    "topGap": 9,
    "bottomGap": 7,
    "keyWidth": 26,
    "keyHeight": 39,
    "keyGap": 6, // 5 for russian, though still 6 on lower row
    "shiftAndBackspaceMaxWidth": 36,
    "specialKeyWidth": 34,
    "doneKeyWidth": 50,
    "spaceWidth": 138,
    "debugWidth": 2
]

// shift/backspace: 72x78, but shrinks to 48x78
// lower row: 68x78, 100x78, 276

class KeyboardViewController: UIInputViewController {
    
    var elements: Dictionary<String, UIView>
    var keyboard: Keyboard
    var keyViewToKey: Dictionary<KeyboardKey, Key>

    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.elements = Dictionary<String, UIView>()
        self.keyboard = defaultKeyboard()
        self.keyViewToKey = Dictionary<KeyboardKey, Key>()
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.elements["superview"] = self.view
        createViews(keyboard)
        
        addEdgeConstraints()
        
        createRowGapConstraints(keyboard)
        createKeyGapConstraints(keyboard)
        createKeyConstraints(keyboard)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func addEdgeConstraints() {
        let spacers = [
            "leftSpacer": Spacer(color: UIColor.redColor()),
            "rightSpacer": Spacer(color: UIColor.redColor()),
            "topSpacer": Spacer(color: UIColor.redColor()),
            "bottomSpacer": Spacer(color: UIColor.redColor())]
        
        // basic setup
        for (name, spacer) in spacers {
            spacer.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.elements[name] = spacer
            self.view.addSubview(spacer)
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
            self.view.addConstraints(generatedConstraints)
        }
        
        // centering constraints
        for (name, spacer) in spacers {
            if (name.hasPrefix("left") || name.hasPrefix("right")) {
                self.view.addConstraint(NSLayoutConstraint(
                    item: spacer,
                    attribute: NSLayoutAttribute.CenterY,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.view,
                    attribute: NSLayoutAttribute.CenterY,
                    multiplier: 1,
                    constant: 0))
            }
            else if (name.hasPrefix("top") || name.hasPrefix("bottom")) {
                self.view.addConstraint(NSLayoutConstraint(
                    item: spacer,
                    attribute: NSLayoutAttribute.CenterX,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.view,
                    attribute: NSLayoutAttribute.CenterX,
                    multiplier: 1,
                    constant: 0))
            }
        }
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
    
    func createViews(keyboard: Keyboard) {
        let numRows = keyboard.rows.count
        
        for i in 0...numRows {
            var rowGap = Spacer(color: ((i == 0 || i == numRows) ? UIColor.purpleColor() : UIColor.yellowColor()))
            let rowGapName = "rowGap\(i)"
            rowGap.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.elements[rowGapName] = rowGap
            self.view.addSubview(rowGap)
            
            if (i < numRows) {
                let numKeys = keyboard.rows[i].count
                
                for j in 0...numKeys {
                    var keyGap = Spacer(color: UIColor.blueColor())
                    let keyGapName = "keyGap\(j)x\(i)"
                    keyGap.setTranslatesAutoresizingMaskIntoConstraints(false)
                    self.elements[keyGapName] = keyGap
                    self.view.addSubview(keyGap)
                    
                    if (j < numKeys) {
                        var key = keyboard.rows[i][j]
                        
                        var keyView = KeyboardKey(frame: CGRectZero) // TODO:
                        let keyViewName = "key\(j)x\(i)"
                        keyView.enabled = true
                        keyView.setTranslatesAutoresizingMaskIntoConstraints(false)
                        keyView.text = key.keyCap
                        self.elements[keyViewName] = keyView
                        self.view.addSubview(keyView)
                        
                        self.keyViewToKey[keyView] = key
                        
                        if key.type == Key.KeyType.KeyboardChange {
                            keyView.addTarget(self, action: "advanceToNextInputMode", forControlEvents: .TouchUpInside)
                        }
                        
                        if key.outputText {
                            keyView.addTarget(self, action: "keyPressed:", forControlEvents: .TouchUpInside)
                        }
                        
                        if key.type == Key.KeyType.Backspace {
                            keyView.addTarget(self, action: "backspacePressed:", forControlEvents: .TouchUpInside)
                        }
                        
                        //        self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), forState: .Normal)
                        //        self.nextKeyboardButton.sizeToFit()
                    }
                }
            }
        }
    }
    
    func createRowGapConstraints(keyboard: Keyboard) {
        var allConstraints: Array<String> = []
        
        var canonicalMarginGap: String? = nil
        var canonicalRowGap: String? = nil
        
        for i in 0...keyboard.rows.count {
            let rowGapName = "rowGap\(i)"
            let rowGap = self.elements[rowGapName]
            
            let isTopMarginGap = (i == 0)
            let isBottomMarginGap = (i == keyboard.rows.count)
            
            if isTopMarginGap {
                canonicalMarginGap = rowGapName
                allConstraints += "V:[topSpacer][\(rowGapName)(0)]"
            }
            else if isBottomMarginGap {
                allConstraints += "V:[key\(0)x\(i-1)][\(rowGapName)(\(canonicalMarginGap))][bottomSpacer]"
            }
            else {
                if !canonicalRowGap {
                    allConstraints += "V:[key\(0)x\(i-1)][\(rowGapName)]"
                    canonicalRowGap = rowGapName
                }
                else {
                    allConstraints += "V:[key\(0)x\(i-1)][\(rowGapName)(\(canonicalRowGap))]"
                }
            }
            
            // each row has the same width
            allConstraints += "[\(rowGapName)(debugWidth)]"
            
            // and the same centering
            self.view.addConstraint(NSLayoutConstraint(
                item: rowGap,
                attribute: NSLayoutAttribute.CenterX,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.view,
                attribute: NSLayoutAttribute.CenterX,
                multiplier: 1,
                constant: 0))
        }
        
        for constraint in allConstraints {
            let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                constraint,
                options: NSLayoutFormatOptions(0),
                metrics: layout,
                views: elements)
            self.view.addConstraints(generatedConstraints)
        }
    }
    
    func centerItems(item1: UIView, item2: UIView) {
        self.view.addConstraint(NSLayoutConstraint(
            item: item1,
            attribute: NSLayoutAttribute.CenterY,
            relatedBy: NSLayoutRelation.Equal,
            toItem: item2,
            attribute: NSLayoutAttribute.CenterY,
            multiplier: 1,
            constant: 0))
    }
    
    func addFlexibleGapPair(nameFormat: String, row: Int, startIndex: Int, endIndex: Int, leftAnchor: String?, rightAnchor: String?, vertical: Bool) {
        var allConstraints: Array<String> = []
        
        var leftGapName = String(format: nameFormat, startIndex, row)
        var rightGapName = String(format: nameFormat, endIndex, row)
        
        if leftAnchor {
            allConstraints += "[\(leftAnchor)][\(leftGapName)]"
        }
        
        if rightAnchor {
            allConstraints += "[\(rightGapName)][\(rightAnchor)]"
        }
        
        allConstraints += "[\(rightGapName)(\(leftGapName))]"
        
        allConstraints += "V:[\(leftGapName)(debugWidth)]"
        allConstraints += "V:[\(rightGapName)(debugWidth)]"
        centerItems(self.elements[leftGapName]!, item2: self.elements["key\(0)x\(row)"]!)
        centerItems(self.elements[rightGapName]!, item2: self.elements["key\(0)x\(row)"]!)
        
        for constraint in allConstraints {
            let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                constraint,
                options: NSLayoutFormatOptions(0),
                metrics: layout,
                views: elements)
            self.view.addConstraints(generatedConstraints)
        }
    }
    
    func addFixedGapsInRange(nameFormat: String, row: Int, startIndex: Int, endIndex: Int, vertical: Bool, width: Double) {
        var allConstraints: Array<String> = []
        
        var firstGapName = String(format: nameFormat, startIndex, row)
        allConstraints += "[\(firstGapName)(\(width))]"
        
        for i in startIndex...endIndex {
            var gapName = String(format: nameFormat, i, row)
            
            if i > 0 {
                allConstraints += "[\(gapName)(\(firstGapName))]"
            }
            
            allConstraints += "V:[\(gapName)(debugWidth)]"
            centerItems(self.elements[gapName]!, item2: self.elements["key\(0)x\(row)"]!)
        }
        
        for constraint in allConstraints {
            let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                constraint,
                options: NSLayoutFormatOptions(0),
                metrics: layout,
                views: elements)
            self.view.addConstraints(generatedConstraints)
        }
    }
    
    // TODO: make this a single constraint string??
    // TODO: third row: side gaps come AFTER special buttons on sides
    // TODO: last row: flexible gaps w/no edges
    func createKeyGapConstraints(keyboard: Keyboard) {
        for i in 0..<keyboard.rows.count {
            // TODO: both of these should be determined based on the model data, not the row #
            let isSideButtonRow = (i == 2)
            let isEquallySpacedRow = (i == 3)
            
            addFlexibleGapPair("keyGap%dx%d", row: i, startIndex: 0, endIndex: keyboard.rows[i].count, leftAnchor: "leftSpacer", rightAnchor: "rightSpacer", vertical: false)
            addFixedGapsInRange("keyGap%dx%d", row: i, startIndex: 1, endIndex: keyboard.rows[i].count-1, vertical: false, width: 6)
        }
    }
    
    func createKeyConstraints(keyboard: Keyboard) {
        var allConstraints: Array<String> = []
        
        for i in 0..<keyboard.rows.count {
            for j in 0..<keyboard.rows[i].count {
                let keyModel = keyboard.rows[i][j]
                
                let keyName = "key\(j)x\(i)"
                let key = self.elements[keyName]
                
                var width = ""
                var height = "(keyHeight)"
                
                switch keyModel.type {
                case Key.KeyType.Character:
                    width = "(keyWidth)"
                case Key.KeyType.Shift, Key.KeyType.Backspace:
                    width = "(shiftAndBackspaceMaxWidth)"
                case Key.KeyType.KeyboardChange, Key.KeyType.ModeChange, Key.KeyType.SpecialCharacter, Key.KeyType.Period:
                    width = "(specialKeyWidth)"
                case Key.KeyType.Space:
                    width = "(spaceWidth)"
                case Key.KeyType.Return:
                    width = "(doneKeyWidth)"
                }
                
                allConstraints += "[keyGap\(j)x\(i)][\(keyName)\(width)][keyGap\(j+1)x\(i)]"
                allConstraints += "V:[rowGap\(i)][\(keyName)\(height)]"
            }
        }
        
        for constraint in allConstraints {
            let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                constraint,
                options: NSLayoutFormatOptions(0),
                metrics: layout,
                views: elements)
            self.view.addConstraints(generatedConstraints)
        }
    }
    
    func keyPressed(sender: KeyboardKey) {
        let model = self.keyViewToKey[sender]
        
        if model && model!.outputText {
            (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).insertText(model!.outputText)
        }
    }
    
    func backspacePressed(sender: KeyboardKey) {
        (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).deleteBackward()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    override func textWillChange(textInput: UITextInput) {
        // The app is about to change the document's contents. Perform any preparation here.
    }

    override func textDidChange(textInput: UITextInput) {
        // The app has just changed the document's contents, the document context has been updated.
    
        var textColor: UIColor
        var proxy = self.textDocumentProxy as UITextDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.Dark {
            textColor = UIColor.whiteColor()
        } else {
            textColor = UIColor.blackColor()
        }
    }
}

class Spacer: UIView {
    init(frame: CGRect) {
        super.init(frame: frame)
        self.hidden = true
    }
    convenience init() {
        return self.init(frame: CGRectZero)
    }
    convenience init(color: UIColor) {
        self.init(frame: CGRectMake(20, 20, 100, 100))
        self.layer.backgroundColor = color.CGColor
        self.hidden = false
    }
//    override class func requiresConstraintBasedLayout() -> Bool {
//        return true
//    }
}
