//
//  ViewController.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
                            
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var textField = UITextField(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        textField.text = "try me!"
        
        var image = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("asdf", ofType: "jpg")!)
        var asdf = UIImageView(image: image)
        asdf.frame = self.view.bounds
        
        self.view.addSubview(asdf)
        self.view.addSubview(textField)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

