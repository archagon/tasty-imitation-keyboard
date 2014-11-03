//
//  DefaultSettings.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 11/2/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// TODO: move this somewhere else and localize
let settings = [
    (kAutoCapitalization, "Auto-Capitalization"),
    (kPeriodShortcut,  "“.” Shortcut"),
    (kKeyboardClicks, "Keyboard Clicks")
]

let notes = [
    kKeyboardClicks: "Please note that keyboard clicks will work only if “Allow Full Access” is enabled in the keyboard settings. Unfortunately, this is a limitation of the operating system. Rest assured that absoutely none of your keystrokes will be recorded or sent over the network with this setting enabled — it is strictly for sound playback and nothing else."
]

class DefaultSettings: ExtraView, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView?
    @IBOutlet var effectsView: UIVisualEffectView?
    @IBOutlet var backButton: UIButton?
    @IBOutlet var settingsLabel: UILabel?
    
    override var darkMode: Bool {
        didSet {
            self.updateAppearance(darkMode)
        }
    }
    
    let cellBackgroundColorDark = UIColor.whiteColor().colorWithAlphaComponent(CGFloat(0.25))
    let cellBackgroundColorLight = UIColor.whiteColor().colorWithAlphaComponent(CGFloat(1))
    let cellLabelColorDark = UIColor.whiteColor()
    let cellLabelColorLight = UIColor.blackColor()
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        fatalError("this class requires a nib")
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.updateAppearance(self.darkMode)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
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
    
    // TODO: I couldn't add a prototype cell to the table view in the nib for some reason
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        var sw = UISwitch()
        var label = UILabel()
        sw.setTranslatesAutoresizingMaskIntoConstraints(false)
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        sw.tag = 1
        label.tag = 2
        
        sw.on = NSUserDefaults.standardUserDefaults().boolForKey(settings[indexPath.row].0)
        label.text = settings[indexPath.row].1
        label.sizeToFit()
        
        sw.addTarget(self, action: Selector("toggleSetting:"), forControlEvents: UIControlEvents.ValueChanged)
        
        cell.addSubview(sw)
        cell.addSubview(label)
        
        let left = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: cell, attribute: NSLayoutAttribute.LeftMargin, multiplier: 1, constant: 0)
        let labelCenterY = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: cell, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: cell, attribute: NSLayoutAttribute.RightMargin, multiplier: 1, constant: 0)
        let swCenterY = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: cell, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        
        cell.addConstraint(left)
        cell.addConstraint(right)
        cell.addConstraint(labelCenterY)
        cell.addConstraint(swCenterY)
        
        cell.backgroundColor = (self.darkMode ? cellBackgroundColorDark : cellBackgroundColorLight)
        label.textColor = (self.darkMode ? cellLabelColorDark : cellLabelColorLight)

        return cell
    }
    
    func updateAppearance(dark: Bool) {
        if dark {
            self.effectsView?.effect
            self.backButton?.setTitleColor(UIColor(red: 135/CGFloat(255), green: 206/CGFloat(255), blue: 250/CGFloat(255), alpha: 1), forState: UIControlState.Normal)
            self.settingsLabel?.textColor = UIColor.whiteColor()
            
            if let visibleCells = self.tableView?.visibleCells() {
                for cell in visibleCells {
                    if var cell = cell as? UITableViewCell {
                        cell.backgroundColor = cellBackgroundColorDark
                        var label = cell.viewWithTag(2) as? UILabel
                        label?.textColor = cellLabelColorDark
                    }
                }
            }
        }
        else {
            self.backButton?.setTitleColor(UIColor(red: 0/CGFloat(255), green: 122/CGFloat(255), blue: 255/CGFloat(255), alpha: 1), forState: UIControlState.Normal)
            self.settingsLabel?.textColor = UIColor.grayColor()
            
            if let visibleCells = self.tableView?.visibleCells() {
                for cell in visibleCells {
                    if var cell = cell as? UITableViewCell {
                        cell.backgroundColor = cellBackgroundColorLight
                        var label = cell.viewWithTag(2) as? UILabel
                        label?.textColor = cellLabelColorLight
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
