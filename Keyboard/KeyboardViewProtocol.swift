//
//  KeyboardViewProtocol.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// views that conform to this protocol follow the keyboard style
protocol KeyboardView {
    var color: UIColor { get set }
    var underColor: UIColor { get set }
    var borderColor: UIColor { get set }
    var drawUnder: Bool { get set }
    var drawBorder: Bool { get set }
}