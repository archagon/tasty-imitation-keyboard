//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit
import KeyboardFramework

let layout = [
    "leftGap": 5,
    "rightGap": 3,
    "topGap": 5,
    "bottomGap": 2,
    "debugWidth": 2,
    "keyWidth": 26,
    "keyHeight": 39,
    "keyGap": 5
]

class KeyboardViewController: UIInputViewController {

    var nextKeyboardButton: UIButton!
    var textField: UITextField!
    var elements: Dictionary<String, UIView>

    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.elements = Dictionary<String, UIView>()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.view.removeFromSuperview()
//        self.view = UIView(frame: CGRect(x: 20, y: 20, width: 400, height: 400))
    
        // Perform custom UI setup here
        self.nextKeyboardButton = UIButton.buttonWithType(.System) as UIButton
    
        self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), forState: .Normal)
        self.nextKeyboardButton.sizeToFit()
        self.nextKeyboardButton.setTranslatesAutoresizingMaskIntoConstraints(false)
    
        self.nextKeyboardButton.addTarget(self, action: "advanceToNextInputMode", forControlEvents: .TouchUpInside)
        
//        self.nextKeyboardButton.center = CGPoint(x: 100, y: 100)
        
        self.view.addSubview(self.nextKeyboardButton)
    
        var nextKeyboardButtonLeftSideConstraint = NSLayoutConstraint(item: self.nextKeyboardButton, attribute: .Left, relatedBy: .Equal, toItem: self.view, attribute: .Left, multiplier: 1.0, constant: 0.0)
        var nextKeyboardButtonBottomConstraint = NSLayoutConstraint(item: self.nextKeyboardButton, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        self.view.addConstraints([nextKeyboardButtonLeftSideConstraint, nextKeyboardButtonBottomConstraint])
        
        //////////////
        // keyboard //
        //////////////
        
        let keyboardKeys = [
            ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
            ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
            ["⇧", "Z", "X", "C", "V", "B", "N", "M", "⬅︎"],
            ["123", "🌐", "space", "return"]];
        let firstRow = keyboardKeys[0]
        
        ///////////////
        // constants //
        ///////////////
        
        let keyboardSize = CGSizeMake(320.0, 216.0)
        let gapSize = 12.0/2
        let keySize: CGSize = CGSizeMake(52.0/2, 78.0/2)
        let rowGapSize = (keyboardSize.height - (Double(keyboardKeys.count) * keySize.height)) / (Double(keyboardKeys.count + 1))
        
        ////////////
        // layout //
        ////////////
        
        addEdgeConstraints()
//        addRows(keyboardKeys)
        
        createViews(keyboardKeys)
        createRowGapConstraints(keyboardKeys)
        createKeyGapConstraints(keyboardKeys)
        createKeyConstraints(keyboardKeys)
        
        self.view.setNeedsUpdateConstraints()
    }
    
    func addEdgeConstraints() {
        let spacers = [
            "leftSpacer": Spacer(),
            "rightSpacer": Spacer(),
            "topSpacer": Spacer(),
            "bottomSpacer": Spacer()]
        
        // basic setup
        for (name, spacer) in spacers {
            spacer.setTranslatesAutoresizingMaskIntoConstraints(false)
            spacer.layer.backgroundColor = UIColor.redColor().CGColor
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
    
    func createViews(keyboard: Array<Array<String>>) {
        for i in 0...keyboard.count {
            var rowGap = Spacer()
            let rowGapName = "rowGap\(i)"
            rowGap.layer.backgroundColor = UIColor.yellowColor().CGColor
            rowGap.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.elements[rowGapName] = rowGap
            self.view.addSubview(rowGap)
            
            if (i < keyboard.count) {
                for j in 0...keyboard[i].count {
                    var keyGap = Spacer()
                    let keyGapName = "keyGap\(i)x\(j)"
                    keyGap.layer.backgroundColor = UIColor.blueColor().CGColor
                    keyGap.setTranslatesAutoresizingMaskIntoConstraints(false)
                    self.elements[keyGapName] = keyGap
                    self.view.addSubview(keyGap)
                    
                    if (j < keyboard[i].count) {
                        var key = keyboard[i][j]
                        
                        var keyView = KeyboardKey(frame: CGRectMake(0, 0, 26, 39)) // TODO:
                        let keyViewName = "key\(i)x\(j)"
                        keyView.enabled = true
                        keyView.setTranslatesAutoresizingMaskIntoConstraints(false)
                        keyView.text = key
                        keyView.addTarget(self, action: "keyPressed:", forControlEvents: UIControlEvents.TouchUpInside)
                        self.elements[keyViewName] = keyView
                        self.view.addSubview(keyView)
                    }
                }
            }
        }
    }
    
    func createRowGapConstraints(keyboard: Array<Array<String>>) {
        var allConstraints: Array<String> = []
        
        var canonicalMarginGap: String? = nil
        var canonicalRowGap: String? = nil
        
        for i in 0...keyboard.count {
            let rowGapName = "rowGap\(i)"
            let rowGap = self.elements[rowGapName]
            
            let isTopMarginGap = (i == 0)
            let isBottomMarginGap = (i == keyboard.count)
            
            if isTopMarginGap {
                canonicalMarginGap = rowGapName
                allConstraints += "V:[topSpacer][\(rowGapName)(5)]" // TODO:
            }
            else if isBottomMarginGap {
                allConstraints += "V:[\(rowGapName)(\(canonicalMarginGap))][bottomSpacer]"
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
    
    func createKeyGapConstraints(keyboard: Array<Array<String>>) {
        var allConstraints: Array<String> = []
        
        var canonicalMarginGap: String? = nil
        
        for i in 0..keyboard.count {
            for j in 0...keyboard[i].count {
                let keyGapName = "keyGap\(i)x\(j)"
                let keyGap = self.elements[keyGapName]
                
                let isLeftMarginGap = (j == 0)
                let isRightMarginGap = (j == keyboard[i].count)
                
                if isLeftMarginGap {
                    canonicalMarginGap = keyGapName
                    allConstraints += "[leftSpacer][\(keyGapName)]"
                }
                else if isRightMarginGap {
                    allConstraints += "[\(keyGapName)(\(canonicalMarginGap))][rightSpacer]"
                }
                else {
                    allConstraints += "[key\(0)x\(j-1)][\(keyGapName)(keyGap)]"
                }
                
                // each gap has the same height
                allConstraints += "V:[\(keyGapName)(debugWidth)]"
                
                // and the same centering
                self.view.addConstraint(NSLayoutConstraint(
                    item: keyGap,
                    attribute: NSLayoutAttribute.CenterY,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.elements["key\(0)x\(j-1)"],
                    attribute: NSLayoutAttribute.CenterY,
                    multiplier: 1,
                    constant: 0))
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
    
    func createKeyConstraints(keyboard: Array<Array<String>>) {
        var allConstraints: Array<String> = []
        
        for i in 0..keyboard.count {
            for j in 0..keyboard[i].count {
                let keyName = "key\(i)x\(j)"
                let key = self.elements[keyName]
                
                allConstraints += "[keyGap\(i)x\(j)][\(keyName)(keyWidth)]"
                allConstraints += "V:[rowGap\(i)][\(keyName)(keyHeight)]"
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
    
    func addRows(rows: Array<Array<String>>) {
        var canonicalRowGap: String? = nil
        var canonicalKeyFromPreviousRow: String? = nil
        
        var rowId = 0
        
        for h in 0..rows.count {
            let row = rows[h]
            
            let firstRowInRows = (h == 0)
            let lastRowInRows = (h == (rows.count - 1))
            
            if !firstRowInRows {
                var rowGap = Spacer()
                
                let rowGapName = "rowGap\(rowId)"
                rowGap.layer.backgroundColor = UIColor.yellowColor().CGColor
                rowGap.setTranslatesAutoresizingMaskIntoConstraints(false)
                self.elements[rowGapName] = rowGap
                self.view.addSubview(rowGap)
                
                var height = ""
                if !canonicalRowGap {
                    canonicalRowGap = rowGapName
                }
                else {
                    height = "(\(canonicalRowGap))"
                }
                
                let constraints = [
                    "[\(rowGapName)(debugWidth)]",
                    "V:[\(canonicalKeyFromPreviousRow)][\(rowGapName)\(height)]"
                ]
                
                for constraint in constraints {
                    let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                        constraint,
                        options: NSLayoutFormatOptions(0),
                        metrics: layout,
                        views: elements)
                    self.view.addConstraints(generatedConstraints)
                }
                
                self.view.addConstraint(NSLayoutConstraint(
                    item: rowGap,
                    attribute: NSLayoutAttribute.CenterX,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.view,
                    attribute: NSLayoutAttribute.CenterX,
                    multiplier: 1,
                    constant: 0))
            }
            
            canonicalKeyFromPreviousRow = nil
            
            var keyId = 0
            var canonicalGap: String? = nil
            var previousKey: KeyboardKey? = nil
            
            for i in 0..row.count {
                let key = row[i]
                
                let firstKeyInRow = (i == 0)
                let lastKeyInRow = (i == (row.count - 1))
                
                if !firstKeyInRow {
                    var gap = Spacer()

                    let name = "spacer\(rowId)x\(keyId)"
                    gap.layer.backgroundColor = UIColor.blueColor().CGColor
                    gap.setTranslatesAutoresizingMaskIntoConstraints(false)
                    self.elements[name] = gap
                    self.view.addSubview(gap)
                    
                    var width = ""
                    if !canonicalGap {
                        canonicalGap = name
                    }
                    else {
                        width = "(\(canonicalGap))"
                    }
                    
                    let constraints = [
                        "[key\(rowId)x\(keyId-1)][\(name)\(width)]",
                        "V:[topSpacer][\(name)(debugWidth)]"
                    ]
                    
                    for constraint in constraints {
                        let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                            constraint,
                            options: NSLayoutFormatOptions(0),
                            metrics: layout,
                            views: elements)
                        self.view.addConstraints(generatedConstraints)
                    }
                    
                    self.view.addConstraint(NSLayoutConstraint(
                        item: gap,
                        attribute: NSLayoutAttribute.CenterY,
                        relatedBy: NSLayoutRelation.Equal,
                        toItem: previousKey,
                        attribute: NSLayoutAttribute.CenterY,
                        multiplier: 1,
                        constant: 0))
                }
                
                var keyView = KeyboardKey(frame: CGRectMake(0, 0, 26, 39)) // TODO:
                
                let name = "key\(rowId)x\(keyId)"
                keyView.enabled = true
                keyView.setTranslatesAutoresizingMaskIntoConstraints(false)
                keyView.text = key
                keyView.addTarget(self, action: "keyPressed:", forControlEvents: UIControlEvents.TouchUpInside)
                self.elements[name] = keyView
                self.view.addSubview(keyView)
                
                if (!canonicalKeyFromPreviousRow) {
                    canonicalKeyFromPreviousRow = name
                }
                
                var leftEdge = (firstKeyInRow ? "leftSpacer" : "spacer\(rowId)x\(keyId)")
                var topEdge = (firstRowInRows ? "topSpacer" : "rowGap\(rowId)")
                
                var constraints = [
                    "[\(leftEdge)][\(name)(keyWidth)]",
                    "V:[\(topEdge)][\(name)(keyHeight)]"
                ]
                
                if (lastKeyInRow) {
                    constraints += "[\(name)][rightSpacer]"
                }
                if (lastRowInRows) {
                    constraints += "V:[\(name)][bottomSpacer]"
                }
                
                for constraint in constraints {
                    let generatedConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                        constraint,
                        options: NSLayoutFormatOptions(0),
                        metrics: layout,
                        views: elements)
                    self.view.addConstraints(generatedConstraints)
                }
                
                previousKey = keyView
                keyId++
            }
            
            rowId++
        }
    }
    
    func keyPressed(sender: KeyboardKey) {
        NSLog("got key from \(sender)")
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
        self.nextKeyboardButton.setTitleColor(textColor, forState: .Normal)
    }
}

class Spacer: UIView {
    init(frame: CGRect) {
        super.init(frame: frame)
//        self.hidden = true
    }
    convenience init() {
        return self.init(frame: CGRectMake(20, 20, 100, 100))
    }
//    override class func requiresConstraintBasedLayout() -> Bool {
//        return true
//    }
}
