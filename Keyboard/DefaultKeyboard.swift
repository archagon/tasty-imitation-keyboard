//
//  DefaultKeyboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

func defaultKeyboard(keyboardType:UIKeyboardType) -> Keyboard
{
	
	if keyboardType == UIKeyboardType.NumberPad
	{
		return defaultKeyboardNumber()
	}
	else if keyboardType == UIKeyboardType.DecimalPad
	{
		return defaultKeyboardDecimal()
	}
	else if keyboardType == UIKeyboardType.EmailAddress
	{
		return defaultKeyboardEmail()
	}
	else if keyboardType == UIKeyboardType.URL || keyboardType == UIKeyboardType.WebSearch
	{
		return defaultKeyboardURL()
	}
	else
	{
		return defaultKeyboardDefault()
	}
	
}

func defaultKeyboardDefault() -> Keyboard {
    var defaultKeyboard = Keyboard()
	
    var longPresses = generatedGetLongPresses();
	
    for key in ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"] {
        var keyModel = Key(.Character)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 0)
    }
	
    for key in ["A", "S", "D", "F", "G", "H", "J", "K", "L"] {
        var keyModel = Key(.Character)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 0)
    }
    
    var keyModel = Key(.Shift)
    defaultKeyboard.addKey(keyModel, row: 2, page: 0)
    
    for key in ["Z", "X", "C", "V", "B", "N", "M"] {
        var keyModel = Key(.Character)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 0)
    }
    
    var backspace = Key(.Backspace)
    defaultKeyboard.addKey(backspace, row: 2, page: 0)
    
    var keyModeChangeNumbers = Key(.ModeChange)
    keyModeChangeNumbers.uppercaseKeyCap = "123"
    keyModeChangeNumbers.toMode = 1
    defaultKeyboard.addKey(keyModeChangeNumbers, row: 3, page: 0)
    
    var keyboardChange = Key(.KeyboardChange)
    defaultKeyboard.addKey(keyboardChange, row: 3, page: 0)
    
    var settings = Key(.Settings)
    defaultKeyboard.addKey(settings, row: 3, page: 0)
	
    var space = Key(.Space)
    space.uppercaseKeyCap = "espacio"
    space.uppercaseOutput = " "
    space.lowercaseOutput = " "
    defaultKeyboard.addKey(space, row: 3, page: 0)
	
//	var atModel = Key(.Character)
//	atModel.setLetter("@")
//	defaultKeyboard.addKey(atModel, row: 3, page: 0)

	
//	var dotModel = Key(.Character)
//	dotModel.setLetter(".")
//	defaultKeyboard.addKey(dotModel, row: 3, page: 0)
	
    var returnKey = Key(.Return)
    returnKey.uppercaseKeyCap = "intro"
    returnKey.uppercaseOutput = "\n"
    returnKey.lowercaseOutput = "\n"
    defaultKeyboard.addKey(returnKey, row: 3, page: 0)
    
    for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 1)
    }
    
    for key in ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 1)
    }
    
    var keyModeChangeSpecialCharacters = Key(.ModeChange)
    keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
    keyModeChangeSpecialCharacters.toMode = 2
    defaultKeyboard.addKey(keyModeChangeSpecialCharacters, row: 2, page: 1)
    
    for key in [".", ",", "?", "!", "'"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 1)
    }
    
    defaultKeyboard.addKey(Key(backspace), row: 2, page: 1)
    
    var keyModeChangeLetters = Key(.ModeChange)
    keyModeChangeLetters.uppercaseKeyCap = "ABC"
    keyModeChangeLetters.toMode = 0
    defaultKeyboard.addKey(keyModeChangeLetters, row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(settings), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(space), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(returnKey), row: 3, page: 1)
    
    for key in ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 2)
    }
    
    for key in ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 2)
    }
    
    defaultKeyboard.addKey(Key(keyModeChangeNumbers), row: 2, page: 2)
    
    for key in [".", ",", "?", "!", "'"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 2)
    }
    
    defaultKeyboard.addKey(Key(backspace), row: 2, page: 2)
    
    defaultKeyboard.addKey(Key(keyModeChangeLetters), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(settings), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(space), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(returnKey), row: 3, page: 2)
    
    return defaultKeyboard
	
}


func defaultKeyboardEmail() -> Keyboard {
	var defaultKeyboard = Keyboard()
	
	var longPresses = generatedGetLongPresses();
	
	for key in ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 0, page: 0)
	}
	
	for key in ["A", "S", "D", "F", "G", "H", "J", "K", "L"] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 1, page: 0)
	}
	
	var keyModel = Key(.Shift)
	defaultKeyboard.addKey(keyModel, row: 2, page: 0)
	
	for key in ["Z", "X", "C", "V", "B", "N", "M"] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 2, page: 0)
	}
	
	var backspace = Key(.Backspace)
	defaultKeyboard.addKey(backspace, row: 2, page: 0)
	
	var keyModeChangeNumbers = Key(.ModeChange)
	keyModeChangeNumbers.uppercaseKeyCap = "123"
	keyModeChangeNumbers.toMode = 1
	defaultKeyboard.addKey(keyModeChangeNumbers, row: 3, page: 0)
	
	var keyboardChange = Key(.KeyboardChange)
	defaultKeyboard.addKey(keyboardChange, row: 3, page: 0)
	
	var settings = Key(.Settings)
	defaultKeyboard.addKey(settings, row: 3, page: 0)
	
	var space = Key(.Space)
	space.uppercaseKeyCap = "espacio"
	space.uppercaseOutput = " "
	space.lowercaseOutput = " "
	defaultKeyboard.addKey(space, row: 3, page: 0)
	
	var atModel = Key(.Character)
	atModel.setLetter("@")
	defaultKeyboard.addKey(atModel, row: 3, page: 0)
	
	var dotModel = Key(.Character)
	dotModel.setLetter(".")
	defaultKeyboard.addKey(dotModel, row: 3, page: 0)
	
	var returnKey = Key(.Return)
	returnKey.uppercaseKeyCap = "intro"
	returnKey.uppercaseOutput = "\n"
	returnKey.lowercaseOutput = "\n"
	defaultKeyboard.addKey(returnKey, row: 3, page: 0)
	
	for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 0, page: 1)
	}
	
	for key in ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 1, page: 1)
	}
	
	var keyModeChangeSpecialCharacters = Key(.ModeChange)
	keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
	keyModeChangeSpecialCharacters.toMode = 2
	defaultKeyboard.addKey(keyModeChangeSpecialCharacters, row: 2, page: 1)
	
	for key in [".", ",", "?", "!", "'"] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 2, page: 1)
	}
	
	defaultKeyboard.addKey(Key(backspace), row: 2, page: 1)
	
	var keyModeChangeLetters = Key(.ModeChange)
	keyModeChangeLetters.uppercaseKeyCap = "ABC"
	keyModeChangeLetters.toMode = 0
	defaultKeyboard.addKey(keyModeChangeLetters, row: 3, page: 1)
	
	defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 1)
	
	defaultKeyboard.addKey(Key(settings), row: 3, page: 1)
	
	defaultKeyboard.addKey(Key(space), row: 3, page: 1)
	
	defaultKeyboard.addKey(Key(returnKey), row: 3, page: 1)
	
	for key in ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 0, page: 2)
	}
	
	for key in ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 1, page: 2)
	}
	
	defaultKeyboard.addKey(Key(keyModeChangeNumbers), row: 2, page: 2)
	
	for key in [".", ",", "?", "!", "'"] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 2, page: 2)
	}
	
	defaultKeyboard.addKey(Key(backspace), row: 2, page: 2)
	
	defaultKeyboard.addKey(Key(keyModeChangeLetters), row: 3, page: 2)
	
	defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 2)
	
	defaultKeyboard.addKey(Key(settings), row: 3, page: 2)
	
	defaultKeyboard.addKey(Key(space), row: 3, page: 2)
	
	defaultKeyboard.addKey(Key(returnKey), row: 3, page: 2)
	
	return defaultKeyboard
	
}


func defaultKeyboardURL() -> Keyboard {
	var defaultKeyboard = Keyboard()
	
	var longPresses = generatedGetLongPresses();
	
	for key in ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 0, page: 0)
	}
	
	for key in ["A", "S", "D", "F", "G", "H", "J", "K", "L"] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 1, page: 0)
	}
	
	var keyModel = Key(.Shift)
	defaultKeyboard.addKey(keyModel, row: 2, page: 0)
	
	for key in ["Z", "X", "C", "V", "B", "N", "M"] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 2, page: 0)
	}
	
	var backspace = Key(.Backspace)
	defaultKeyboard.addKey(backspace, row: 2, page: 0)
	
	var keyModeChangeNumbers = Key(.ModeChange)
	keyModeChangeNumbers.uppercaseKeyCap = "123"
	keyModeChangeNumbers.toMode = 1
	defaultKeyboard.addKey(keyModeChangeNumbers, row: 3, page: 0)
	
	var keyboardChange = Key(.KeyboardChange)
	defaultKeyboard.addKey(keyboardChange, row: 3, page: 0)
	
	var settings = Key(.Settings)
	defaultKeyboard.addKey(settings, row: 3, page: 0)
	
	var space = Key(.Space)
	space.uppercaseKeyCap = "espacio"
	space.uppercaseOutput = " "
	space.lowercaseOutput = " "
	defaultKeyboard.addKey(space, row: 3, page: 0)
	
	var dotModel = Key(.Character)
	dotModel.setLetter(".")
	defaultKeyboard.addKey(dotModel, row: 3, page: 0)
	
	var returnKey = Key(.Return)
	returnKey.uppercaseKeyCap = "intro"
	returnKey.uppercaseOutput = "\n"
	returnKey.lowercaseOutput = "\n"
	defaultKeyboard.addKey(returnKey, row: 3, page: 0)
	
	for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 0, page: 1)
	}
	
	for key in ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 1, page: 1)
	}
	
	var keyModeChangeSpecialCharacters = Key(.ModeChange)
	keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
	keyModeChangeSpecialCharacters.toMode = 2
	defaultKeyboard.addKey(keyModeChangeSpecialCharacters, row: 2, page: 1)
	
	for key in [".", ",", "?", "!", "'"] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 2, page: 1)
	}
	
	defaultKeyboard.addKey(Key(backspace), row: 2, page: 1)
	
	var keyModeChangeLetters = Key(.ModeChange)
	keyModeChangeLetters.uppercaseKeyCap = "ABC"
	keyModeChangeLetters.toMode = 0
	defaultKeyboard.addKey(keyModeChangeLetters, row: 3, page: 1)
	
	defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 1)
	
	defaultKeyboard.addKey(Key(settings), row: 3, page: 1)
	
	defaultKeyboard.addKey(Key(space), row: 3, page: 1)
	
	defaultKeyboard.addKey(Key(returnKey), row: 3, page: 1)
	
	for key in ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 0, page: 2)
	}
	
	for key in ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 1, page: 2)
	}
	
	defaultKeyboard.addKey(Key(keyModeChangeNumbers), row: 2, page: 2)
	
	for key in [".", ",", "?", "!", "'"] {
		var keyModel = Key(.SpecialCharacter)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 2, page: 2)
	}
	
	defaultKeyboard.addKey(Key(backspace), row: 2, page: 2)
	
	defaultKeyboard.addKey(Key(keyModeChangeLetters), row: 3, page: 2)
	
	defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 2)
	
	defaultKeyboard.addKey(Key(settings), row: 3, page: 2)
	
	defaultKeyboard.addKey(Key(space), row: 3, page: 2)
	
	defaultKeyboard.addKey(Key(returnKey), row: 3, page: 2)
	
	return defaultKeyboard
	
}

func defaultKeyboardDecimal() -> Keyboard {
	var defaultKeyboard = Keyboard()
	
	for key in ["1", "2", "3","."] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 0, page: 0)
	}
	
	for key in ["4", "5", "6",","] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 1, page: 0)
	}
	
	for key in ["7", "8","9","-"] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 2, page: 0)
	}
	
	var keyboardChange = Key(.KeyboardChange)
	//	defaultKeyboard.addKey(keyboardChange, row: 3, page: 0)
	
	for key in ["00","0"] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 3, page: 0)
		
	}
	
	var backspace = Key(.Backspace)
	
	defaultKeyboard.addKey(keyboardChange, row: 3, page: 0)
	
	defaultKeyboard.addKey(backspace, row: 3, page: 0)
	
	
	
	return defaultKeyboard
}


func defaultKeyboardNumber() -> Keyboard {
	var defaultKeyboard = Keyboard()
	
	for key in ["1", "2", "3","."] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 0, page: 0)
	}
	
	for key in ["4", "5", "6",","] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 1, page: 0)
	}
	
	for key in ["7", "8","9","-"] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 2, page: 0)
	}
	
	var keyboardChange = Key(.KeyboardChange)
//	defaultKeyboard.addKey(keyboardChange, row: 3, page: 0)
	
	for key in ["00","0"] {
		var keyModel = Key(.Character)
		keyModel.setLetter(key)
		defaultKeyboard.addKey(keyModel, row: 3, page: 0)
        
	}
	
	var backspace = Key(.Backspace)
    
    defaultKeyboard.addKey(keyboardChange, row: 3, page: 0)
    
	defaultKeyboard.addKey(backspace, row: 3, page: 0)
	
	
	
	return defaultKeyboard
}


func generatedGetLongPresses() -> [String: [String]] {
    var lps = [String: [String]]()
    lps["k"] = ["ǩ"]
    lps["t"] = ["ŧ", "þ"]
    lps["d"] = ["đ", "ð"]
    lps["D"] = ["Đ", "Ð"]
    lps["Z"] = ["Ž", "Ʒ", "Ǯ"]
    lps["u"] = ["ü", "ú", "ù", "û", "ũ", "ū", "ŭ"]
    lps["n"] = ["ŋ"]
    lps["c"] = ["č", "ç"]
    lps["e"] = ["ë", "é", "è", "ê", "ẽ", "ė", "ē", "ĕ", "ę"]
    lps["Æ"] = ["Ä"]
    lps["Ø"] = ["Ö"]
    lps["æ"] = ["ä"]
    lps["A"] = ["Æ", "Ä", "Å", "Á", "À", "Â", "Ã", "Ȧ", "Ā"]
    lps["s"] = ["š"]
    lps["ø"] = ["ö"]
    lps["S"] = ["Š"]
    lps["K"] = ["Ǩ"]
    lps["G"] = ["Ĝ", "Ḡ", "Ǧ", "Ǥ"]
    lps["O"] = ["Œ", "Ö", "Ó", "Ò", "Ô", "Õ", "Ō", "Ŏ"]
    lps["C"] = ["Č", "Ç"]
    lps["a"] = ["æ", "ä", "å", "á", "à", "â", "ã", "ȧ", "ā"]
    lps["E"] = ["Ë", "É", "È", "Ê", "Ẽ", "Ė", "Ē", "Ĕ", "Ę"]
    lps["N"] = ["Ŋ"]
    lps["g"] = ["ĝ", "ḡ", "ǧ", "ǥ"]
    lps["U"] = ["Ü", "Ú", "Ù", "Û", "Ũ", "Ū", "Ŭ"]
    lps["i"] = ["ï", "í", "ì", "î", "ĩ", "ī", "ĭ"]
    lps["z"] = ["ž", "ʒ", "ǯ"]
    lps["o"] = ["œ", "ö", "ó", "ò", "ô", "õ", "ō", "ŏ"]
    lps["I"] = ["Ï", "Í", "Ì", "Î", "Ĩ", "Ī", "Ĭ"]
    lps["Y"] = ["Ý", "Ỳ", "Ŷ", "Ẏ", "Ȳ"]
    lps["y"] = ["ý", "ỳ", "ŷ", "ẏ", "ȳ"]
    lps["T"] = ["Ŧ", "Þ"]
    return lps
}
