//
//  DefaultSettings.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 11/2/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

let globalSettings = [
    (kAutoCapitalization, "Auto-Capitalization"),
    (kPeriodShortcut,  "“.” Shortcut"),
    (kKeyboardClicks, "Keyboard Clicks")
]
let globalNotes = [
    kKeyboardClicks: "Please note that keyboard clicks will work only if “Allow Full Access” is enabled in the keyboard settings. Unfortunately, this is a limitation of the operating system."
]

class DefaultSettings: ExtraView, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView?
    @IBOutlet var effectsView: UIVisualEffectView?
    @IBOutlet var backButton: UIButton?
    @IBOutlet var settingsLabel: UILabel?
    @IBOutlet var pixelLine: UIView?
    
    override var darkMode: Bool {
        didSet {
            self.updateAppearance(darkMode)
        }
    }
    
    let cellBackgroundColorDark = UIColor.whiteColor().colorWithAlphaComponent(CGFloat(0.25))
    let cellBackgroundColorLight = UIColor.whiteColor().colorWithAlphaComponent(CGFloat(1))
    let cellLabelColorDark = UIColor.whiteColor()
    let cellLabelColorLight = UIColor.blackColor()
    let cellLongLabelColorDark = UIColor.lightGrayColor()
    let cellLongLabelColorLight = UIColor.grayColor()
    
    // TODO: this is weird and hacky, move this somewhere else and localize
    var settings: [(String, String)] {
        get {
            return globalSettings
        }
    }
    var notes: [String: String] {
        get {
            return globalNotes
        }
    }
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        self.loadNib()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("loading from nib not supported")
    }
    
    func loadNib() {
        let assets = NSBundle(forClass: self.dynamicType).loadNibNamed("DefaultSettings", owner: self, options: nil)
        
        if assets.count > 0 {
            if var rootView = assets.first as? UIView {
                rootView.setTranslatesAutoresizingMaskIntoConstraints(false)
                self.addSubview(rootView)
                
                let left = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0)
                let right = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0)
                let top = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
                let bottom = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
                
                self.addConstraint(left)
                self.addConstraint(right)
                self.addConstraint(top)
                self.addConstraint(bottom)
            }
        }
        
        self.tableView?.registerClass(DefaultSettingsTableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView?.estimatedRowHeight = 44;
        self.tableView?.rowHeight = UITableViewAutomaticDimension;
        
        self.updateAppearance(self.darkMode)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        NSLog("settings subview layed out to \(self.frame)")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "General Settings"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if var cell = tableView.dequeueReusableCellWithIdentifier("cell") as? DefaultSettingsTableViewCell {
            let key = settings[indexPath.row].0
            
            if cell.sw.allTargets().count == 0 {
                cell.sw.addTarget(self, action: Selector("toggleSetting:"), forControlEvents: UIControlEvents.ValueChanged)
            }
            
            cell.sw.on = NSUserDefaults.standardUserDefaults().boolForKey(key)
            cell.label.text = settings[indexPath.row].1
            cell.longLabel.text = notes[key]
            
            cell.backgroundColor = (self.darkMode ? cellBackgroundColorDark : cellBackgroundColorLight)
            cell.label.textColor = (self.darkMode ? cellLabelColorDark : cellLabelColorLight)
            cell.longLabel.textColor = (self.darkMode ? cellLongLabelColorDark : cellLongLabelColorLight)
            
            return cell
        }
        else {
            assert(false, "this is a bad thing that just happened")
            return UITableViewCell()
        }
    }
    
    func updateAppearance(dark: Bool) {
        if dark {
            self.effectsView?.effect
            let blueColor = UIColor(red: 135/CGFloat(255), green: 206/CGFloat(255), blue: 250/CGFloat(255), alpha: 1)
            self.pixelLine?.backgroundColor = blueColor.colorWithAlphaComponent(CGFloat(0.5))
            self.backButton?.setTitleColor(blueColor, forState: UIControlState.Normal)
            self.settingsLabel?.textColor = UIColor.whiteColor()
            
            if let visibleCells = self.tableView?.visibleCells() {
                for cell in visibleCells {
                    if var cell = cell as? UITableViewCell {
                        cell.backgroundColor = cellBackgroundColorDark
                        var label = cell.viewWithTag(2) as? UILabel
                        label?.textColor = cellLabelColorDark
                        var longLabel = cell.viewWithTag(3) as? UITextView
                        longLabel?.textColor = cellLongLabelColorDark
                    }
                }
            }
        }
        else {
            let blueColor = UIColor(red: 0/CGFloat(255), green: 122/CGFloat(255), blue: 255/CGFloat(255), alpha: 1)
            self.pixelLine?.backgroundColor = blueColor.colorWithAlphaComponent(CGFloat(0.5))
            self.backButton?.setTitleColor(blueColor, forState: UIControlState.Normal)
            self.settingsLabel?.textColor = UIColor.grayColor()
            
            if let visibleCells = self.tableView?.visibleCells() {
                for cell in visibleCells {
                    if var cell = cell as? UITableViewCell {
                        cell.backgroundColor = cellBackgroundColorLight
                        var label = cell.viewWithTag(2) as? UILabel
                        label?.textColor = cellLabelColorLight
                        var longLabel = cell.viewWithTag(3) as? UITextView
                        longLabel?.textColor = cellLongLabelColorLight
                    }
                }
            }
        }
    }
    
    func toggleSetting(sender: UISwitch) {
        if let cell = sender.superview as? UITableViewCell {
            if let indexPath = self.tableView?.indexPathForCell(cell) {
                let key = settings[indexPath.row].0
                NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: key)
            }
        }
    }
}

class DefaultSettingsTableViewCell: UITableViewCell {
    
    var sw: UISwitch
    var label: UILabel
    var longLabel: UITextView
    var constraintsSetForLongLabel: Bool
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.sw = UISwitch()
        self.label = UILabel()
        self.longLabel = UITextView()
        
        self.constraintsSetForLongLabel = false
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.sw.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.label.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.longLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.longLabel.text = nil
        self.longLabel.scrollEnabled = false
        self.longLabel.selectable = false
        self.longLabel.backgroundColor = UIColor.clearColor()
        
        self.sw.tag = 1
        self.label.tag = 2
        self.longLabel.tag = 3

        self.addSubview(self.sw)
        self.addSubview(self.label)
        self.addSubview(self.longLabel)
        
        self.addConstraints()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addConstraints() {
        let hasLongText = self.longLabel.text != nil && !self.longLabel.text.isEmpty
        if hasLongText {
            let switchSide = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.RightMargin, multiplier: 1, constant: 0)
            let switchTop = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.TopMargin, multiplier: 1, constant: 0)
            let labelSide = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.LeftMargin, multiplier: 1, constant: 0)
            let labelCenter = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: sw, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            
            self.addConstraint(switchSide)
            self.addConstraint(switchTop)
            self.addConstraint(labelSide)
            self.addConstraint(labelCenter)
            
            let left = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.LeftMargin, multiplier: 1, constant: 0)
            let right = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.RightMargin, multiplier: 1, constant: 0)
            let top = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: sw, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 8)
            let bottom = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.BottomMargin, multiplier: 1, constant: 0)
            
            self.addConstraint(left)
            self.addConstraint(right)
            self.addConstraint(top)
            self.addConstraint(bottom)
            
            self.constraintsSetForLongLabel = true
        }
        else {
            let switchSide = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.RightMargin, multiplier: 1, constant: 0)
            let switchTop = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.TopMargin, multiplier: 1, constant: 0)
            let switchBottom = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.BottomMargin, multiplier: 1, constant: 0)
            let labelSide = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.LeftMargin, multiplier: 1, constant: 0)
            let labelCenter = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: sw, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            
            self.addConstraint(switchSide)
            self.addConstraint(switchTop)
            self.addConstraint(switchBottom)
            self.addConstraint(labelSide)
            self.addConstraint(labelCenter)
            
            self.constraintsSetForLongLabel = false
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let hasLongText = self.longLabel.text != nil && !self.longLabel.text.isEmpty
        if hasLongText != self.constraintsSetForLongLabel {
            self.removeConstraints(self.constraints())
            self.addConstraints()
        }
    }
}
