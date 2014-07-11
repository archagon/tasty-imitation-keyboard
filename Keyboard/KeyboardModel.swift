//
//  KeyboardModel.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import Foundation

class Keyboard {
    var keys: Array<Key>
    
    init(keys: Array<Key>) {
        self.keys = keys
    }
}

class Key {
    enum KeyType {
        case Character
        case SpecialCharacter
        case Shift
        case Backspace
        case ModeChange
        case KeyboardChange
        case Space
        case Return
    }
    
    var type: KeyType
    var text: String?
    
    init(type: KeyType) {
        self.type = type
    }
}

// temporary layout rules
//      - letters: side gap + standard size + gap size; side gap is flexible, and letters are centered
//      - special characters: size to width
//      - special keys: a few standard widths
//      - space and return: flexible spacing