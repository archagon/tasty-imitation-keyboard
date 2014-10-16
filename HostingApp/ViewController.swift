//
//  ViewController.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class HostingAppViewController: UIViewController {
    
    @IBOutlet var effectsView: UIVisualEffectView?
    @IBOutlet var textField: UITextView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func darkMode(sender: UISwitch) {
        self.textField?.keyboardAppearance = (sender.on ? UIKeyboardAppearance.Dark : UIKeyboardAppearance.Light)
    }
}

