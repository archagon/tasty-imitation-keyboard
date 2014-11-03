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
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let tableView = self.tableView {
            let numRows = self.tableView(tableView, numberOfRowsInSection: 0)
            let fakeTableHeight = self.bounds.height - 85 //TODO: so sue me
            let rowHeight = self.tableView(tableView, heightForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
            let offset = (fakeTableHeight - (CGFloat(numRows) * rowHeight)) / CGFloat(2)
            
            if offset >= 0 {
                tableView.scrollEnabled = false
                tableView.contentInset = UIEdgeInsetsMake(offset, 0, 0, 0)
            }
            else {
                tableView.scrollEnabled = true
                tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    // TODO: I couldn't add a prototype cell to the table view in the nib for some reason
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        var sw = UISwitch()
        var label = UILabel()
        sw.setTranslatesAutoresizingMaskIntoConstraints(false)
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        
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

        return cell
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
