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
    These are all labeled "rowGap<x>", where 0 <= x <= row count.
    
    Similarly, there are invisible spacer gaps between every key.
    There are also invisible gaps at the start and end of every row.
    These are labeled "keyGap<x>x<y>, where 0 <= x <= key count and y <= 0 < row count.
    
    The keys are labeled "key<x>x<y>".
    */
    
    func createViews(keyboard: Array<Array<String>>) {
        for i in 0...keyboard.count {
            var rowGap = Spacer(color: ((i == 0 || i == keyboard.count) ? UIColor.purpleColor() : UIColor.yellowColor()))
            let rowGapName = "rowGap\(i)"
            rowGap.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.elements[rowGapName] = rowGap
            self.view.addSubview(rowGap)
            
            if (i < keyboard.count) {
                for j in 0...keyboard[i].count {
                    var keyGap = Spacer(color: UIColor.blueColor())
                    let keyGapName = "keyGap\(j)x\(i)"
                    keyGap.setTranslatesAutoresizingMaskIntoConstraints(false)
                    self.elements[keyGapName] = keyGap
                    self.view.addSubview(keyGap)
                    
                    if (j < keyboard[i].count) {
                        var key = keyboard[i][j]
                        
                        var keyView = KeyboardKey(frame: CGRectMake(0, 0, 26, 39)) // TODO:
                        let keyViewName = "key\(j)x\(i)"
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
    
    func createKeyGapConstraints(keyboard: Array<Array<String>>) {
        var allConstraints: Array<String> = []
        
        var canonicalMarginGap: String? = nil
        
        for i in 0..keyboard.count {
            for j in 0...keyboard[i].count {
                let keyGapName = "keyGap\(j)x\(i)"
                let keyGap = self.elements[keyGapName]
                
                let isLeftMarginGap = (j == 0)
                let isRightMarginGap = (j == keyboard[i].count)
                
                if isLeftMarginGap {
                    canonicalMarginGap = keyGapName
                    allConstraints += "[leftSpacer][\(keyGapName)]"
                }
                else if isRightMarginGap {
                    allConstraints += "[key\(j-1)x\(i)][\(keyGapName)(\(canonicalMarginGap))][rightSpacer]"
                }
                else {
                    allConstraints += "[key\(j-1)x\(i)][\(keyGapName)(keyGap)]"
                }
                
                // each gap has the same height
                allConstraints += "V:[\(keyGapName)(debugWidth)]"
                
                // and the same centering
                self.view.addConstraint(NSLayoutConstraint(
                    item: keyGap,
                    attribute: NSLayoutAttribute.CenterY,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self.elements["key\(0)x\(i)"],
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
                let keyName = "key\(j)x\(i)"
                let key = self.elements[keyName]
                
                allConstraints += "[keyGap\(j)x\(i)][\(keyName)(keyWidth)]"
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
