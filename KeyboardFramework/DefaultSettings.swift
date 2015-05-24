//
//  DefaultSettings.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 11/2/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

public class DefaultSettings: ExtraView, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet public var tableView: UITableView?
    @IBOutlet public var effectsView: UIVisualEffectView?
    @IBOutlet public var backButton: UIButton?
    @IBOutlet public var settingsLabel: UILabel?
    @IBOutlet public var pixelLine: UIView?
    
    override public var darkMode: Bool {
        didSet {
            self.updateAppearance(darkMode)
        }
    }
    
    public let cellBackgroundColorDark = UIColor.whiteColor().colorWithAlphaComponent(CGFloat(0.25))
    public let cellBackgroundColorLight = UIColor.whiteColor().colorWithAlphaComponent(CGFloat(1))
    public let cellLabelColorDark = UIColor.whiteColor()
    public let cellLabelColorLight = UIColor.blackColor()
    public let cellLongLabelColorDark = UIColor.lightGrayColor()
    public let cellLongLabelColorLight = UIColor.grayColor()
    
    // TODO: these probably don't belong here, and also need to be localized
    public var settingsList: [(String, [String])] {
        get {
            return [
                ("General Settings", [kAutoCapitalization, kPeriodShortcut, kKeyboardClicks]),
                ("Extra Settings", [kSmallLowercase])
            ]
        }
    }
    public var settingsNames: [String:String] {
        get {
            return [
                kAutoCapitalization: "Auto-Capitalization",
                kPeriodShortcut:  "“.” Shortcut",
                kKeyboardClicks: "Keyboard Clicks",
                kSmallLowercase: "Allow Lowercase Key Caps"
            ]
        }
    }
    public var settingsNotes: [String: String] {
        get {
            return [
                kKeyboardClicks: "Please note that keyboard clicks will work only if “Allow Full Access” is enabled in the keyboard settings. Unfortunately, this is a limitation of the operating system.",
                kSmallLowercase: "Changes your key caps to lowercase when Shift is off, making it easier to tell what mode you are in."
            ]
        }
    }
    
    required public init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        self.loadNib()
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("loading from nib not supported")
    }
    
    public func loadNib() {
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
        
        // XXX: this is here b/c a totally transparent background does not support scrolling in blank areas
        self.tableView?.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.01)
        
        self.updateAppearance(self.darkMode)
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.settingsList.count
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settingsList[section].1.count
    }
    
    public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == self.settingsList.count - 1 {
            return 50
        }
        else {
            return 0
        }
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.settingsList[section].0
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if var cell = tableView.dequeueReusableCellWithIdentifier("cell") as? DefaultSettingsTableViewCell {
            let key = self.settingsList[indexPath.section].1[indexPath.row]
            
            if cell.sw.allTargets().count == 0 {
                cell.sw.addTarget(self, action: Selector("toggleSetting:"), forControlEvents: UIControlEvents.ValueChanged)
            }
            
            cell.sw.on = NSUserDefaults.standardUserDefaults().boolForKey(key)
            cell.label.text = self.settingsNames[key]
            cell.longLabel.text = self.settingsNotes[key]
            
            cell.backgroundColor = (self.darkMode ? cellBackgroundColorDark : cellBackgroundColorLight)
            cell.label.textColor = (self.darkMode ? cellLabelColorDark : cellLabelColorLight)
            cell.longLabel.textColor = (self.darkMode ? cellLongLabelColorDark : cellLongLabelColorLight)

            cell.changeConstraints()
            
            return cell
        }
        else {
            assert(false, "this is a bad thing that just happened")
            return UITableViewCell()
        }
    }
    
    public func updateAppearance(dark: Bool) {
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
    
    public func toggleSetting(sender: UISwitch) {
        if let cell = sender.superview as? UITableViewCell {
            if let indexPath = self.tableView?.indexPathForCell(cell) {
                let key = self.settingsList[indexPath.section].1[indexPath.row]
                NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: key)
            }
        }
    }
}

public class DefaultSettingsTableViewCell: UITableViewCell {
    
    public var sw: UISwitch
    public var label: UILabel
    public var longLabel: UITextView
    public var constraintsSetForLongLabel: Bool
    public var cellConstraints: [NSLayoutConstraint]
    
    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.sw = UISwitch()
        self.label = UILabel()
        self.longLabel = UITextView()
        self.cellConstraints = []
        
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

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func addConstraints() {
        let margin: CGFloat = 8
        let sideMargin = margin * 2
        
        let hasLongText = self.longLabel.text != nil && !self.longLabel.text.isEmpty
        if hasLongText {
            let switchSide = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: -sideMargin)
            let switchTop = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: margin)
            let labelSide = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: sideMargin)
            let labelCenter = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: sw, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            
            self.addConstraint(switchSide)
            self.addConstraint(switchTop)
            self.addConstraint(labelSide)
            self.addConstraint(labelCenter)
            
            let left = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: sideMargin)
            let right = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: -sideMargin)
            let top = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: sw, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: margin)
            let bottom = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: -margin)
            
            self.addConstraint(left)
            self.addConstraint(right)
            self.addConstraint(top)
            self.addConstraint(bottom)
        
            self.cellConstraints += [switchSide, switchTop, labelSide, labelCenter, left, right, top, bottom]
            
            self.constraintsSetForLongLabel = true
        }
        else {
            let switchSide = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: -sideMargin)
            let switchTop = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: margin)
            let switchBottom = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: -margin)
            let labelSide = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: sideMargin)
            let labelCenter = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: sw, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            
            self.addConstraint(switchSide)
            self.addConstraint(switchTop)
            self.addConstraint(switchBottom)
            self.addConstraint(labelSide)
            self.addConstraint(labelCenter)
            
            self.cellConstraints += [switchSide, switchTop, switchBottom, labelSide, labelCenter]
            
            self.constraintsSetForLongLabel = false
        }
    }
    
    // XXX: not in updateConstraints because it doesn't play nice with UITableViewAutomaticDimension for some reason
    public func changeConstraints() {
        let hasLongText = self.longLabel.text != nil && !self.longLabel.text.isEmpty
        if hasLongText != self.constraintsSetForLongLabel {
            self.removeConstraints(self.cellConstraints)
            self.cellConstraints.removeAll()
            self.addConstraints()
        }
    }
}
