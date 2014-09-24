# Tasty Imitation Keyboard

I'm working on a 3rd party keyboard for iOS8 and I want it to look and feel as close as possible to Apple's keyboard. Unfortunately, it's not possible to access the keyboard view through code, so this is my attempt to imitate it by hand. (I'm sure there are ways to get even more accuracy via reverse engineering, but that's too much work for me!) In the end, I hope to produce a coherent and robust baseline for creating custom 3rd party keybards — at least, until Apple decides to fully open up their keyboard API.

## Recent Screenshots

<img width="320px" src="./Screenshot-Portrait.png"></img>
<img width="568px" src="./Screenshot-Landscape.png"></img>

## Fantastic Features

* No bitmaps! Everything is rendered using CoreGraphics.
* Autolayout galore! All the keys are laid out using autolayout constraints, meaning that the keyboard is much easier to extend.
* This keyboard is an iOS8 extension.

## Current State

![](UnderConstruction.gif)

The development of this keyboard is fully open-source, so the project may not work at all times. At the present moment, the baseline functionality is there. Left to implement are special characters, Shift, multitouch, and improved graphics (including translucenty and dark mode).

Hold-to-select-alternate-characters will be implemented at a later time.

## Build Instructions

1. Build the Keyboard target.
2. In the Simulator, go to Settings→General→Keyboard→Keyboards→Add New Keyboard and add the third-party keyboard.
3. Edit Scheme for the Keyboard target and set the Executable to be TransliteratingKeyboard.app.
4. Build and run the Keyboard target. The container app should open up, and you should be able to select the custom keyboard via the globe icon.

## Learning goals for this project:

* Swift
* 3rd party extensions
* 3rd party frameworks (for IB use)
* autolayout
* CoreGraphics
* finally release an app on the App Store, darn it

## License

This project is licensed under the 3-clause ("New") BSD license. (Go Bears!)