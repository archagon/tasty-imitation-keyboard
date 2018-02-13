//
//  ViewController.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

class HostingAppViewController: UIViewController {
    
    @IBOutlet var stats: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(HostingAppViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HostingAppViewController.keyboardDidHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChangeFrame:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HostingAppViewController.keyboardDidChangeFrame(_:)), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func dismiss() {
        for view in self.view.subviews {
            if let inputView = view as? UITextField {
                inputView.resignFirstResponder()
            }
        }
    }
    
    var startTime: TimeInterval?
    var firstHeightTime: TimeInterval?
    var secondHeightTime: TimeInterval?
    var referenceHeight: CGFloat = 216
    
    @objc func keyboardWillShow() {
        if startTime == nil {
            startTime = CACurrentMediaTime()
        }
    }
    
    @objc func keyboardDidHide() {
        startTime = nil
        firstHeightTime = nil
        secondHeightTime = nil
        
        self.stats?.text = "(Waiting for keyboard...)"
    }
    
    @objc func keyboardDidChangeFrame(_ notification: Notification) {
        //let frameBegin: CGRect! = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue
        let frameEnd: CGRect! = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        
        if frameEnd.height == referenceHeight {
            if firstHeightTime == nil {
                firstHeightTime = CACurrentMediaTime()
                
                if let startTime = self.startTime {
                    if let firstHeightTime = self.firstHeightTime {
                        let formatString = NSString(format: "First: %.2f, Total: %.2f", (firstHeightTime - startTime), (firstHeightTime - startTime))
                        self.stats?.text = formatString as String
                    }
                }
            }
        }
        else if frameEnd.height != 0 {
            if secondHeightTime == nil {
                secondHeightTime = CACurrentMediaTime()

                if let startTime = self.startTime {
                    if let firstHeightTime = self.firstHeightTime {
                        if let secondHeightTime = self.secondHeightTime {
                            let formatString = NSString(format: "First: %.2f, Second: %.2f, Total: %.2f", (firstHeightTime - startTime), (secondHeightTime - firstHeightTime), (secondHeightTime - startTime))
                            self.stats?.text = formatString as String
                        }
                    }
                }
            }
        }
    }
}

