import UIKit
import QuartzCore

class KeyboardKeyBackground: UIControl {
    
    let cornerOffset = [0.05, 0.05]
    let arcHeightPercentageRadius = 0.15
    let color = [0.93, 0.98, 0.95]
    var currentColor: Array<Double>
    
    override var selected: Bool {
        didSet {
            if selected {
                self.currentColor = color.map { $0 * 0.85 }
            }
            else {
                self.currentColor = color
            }
            self.setNeedsDisplay()
        }
    }
    
    init(frame: CGRect) {
        currentColor = self.color
        
        super.init(frame: frame)
        
        self.contentMode = UIViewContentMode.Redraw
        self.opaque = false
    }

    override func drawRect(rect: CGRect) {
        ///////////
        // setup //
        ///////////
        
        let ctx = UIGraphicsGetCurrentContext()
        let csp = CGColorSpaceCreateDeviceRGB()
        
        /////////////////////////
        // draw the background //
        /////////////////////////
        
        CGContextSetFillColorWithColor(ctx, UIColor.clearColor().CGColor)
        CGContextFillRect(ctx, self.bounds)
        
        /////////////////////
        // draw the border //
        /////////////////////
        
        let segmentWidth = self.bounds.width * (1 - (cornerOffset[0] * 2))
        let segmentHeight = self.bounds.height * (1 - (cornerOffset[1] * 2))
        let arcLength = segmentHeight * arcHeightPercentageRadius
        
        let startMidpoint = CGPoint(
            x: self.bounds.width * cornerOffset[0],
            y: self.bounds.height * cornerOffset[1] + segmentHeight/2.0)
        
        var path = CGPathCreateMutable();
        
        CGPathMoveToPoint(path, nil, startMidpoint.x, startMidpoint.y)
        
        func correctPosition(index: Int, offset: Int) -> Bool {
            let shiftedOffset = offset % 4
            var shiftedIndex = index - shiftedOffset
            shiftedIndex = (shiftedIndex + 4) % 4
            return shiftedIndex < 2
        }
        
        for i in 0...3 {
            let firstPoint = CGPoint(
                x: self.bounds.width * cornerOffset[0] + (correctPosition(i, 1) ? segmentWidth : 0),
                y: self.bounds.height * cornerOffset[1] + (correctPosition(i, 0) ? segmentHeight : 0))
            let nextPoint = CGPoint(
                x: self.bounds.width * cornerOffset[0] + (correctPosition(i, 0) ? segmentWidth : 0),
                y: self.bounds.height * cornerOffset[1] + (correctPosition(i, -1) ? segmentHeight : 0))
            
            CGPathAddArcToPoint(path, nil,
                firstPoint.x,
                firstPoint.y,
                nextPoint.x,
                nextPoint.y,
                arcLength)
        }
        
        CGPathAddLineToPoint(path, nil, startMidpoint.x, startMidpoint.y)
        CGPathCloseSubpath(path)
        
        var drawColor = self.currentColor
        drawColor.append(1.0)
        let color2 = drawColor.map { $0 * 0.80 }
        color2[3] = 1.0
        let color3 = drawColor.map { $0 * 0.4 }
        color3[3] = 0.85
        
        CGContextSetFillColor(ctx, color3)
        CGContextTranslateCTM(ctx, 0, 3)
        CGContextAddPath(ctx, path)
        CGContextFillPath(ctx)
        CGContextTranslateCTM(ctx, 0, -3)
        
        CGContextSetFillColor(ctx, drawColor)
        CGContextAddPath(ctx, path)
        CGContextFillPath(ctx)
        
        CGContextSetStrokeColor(ctx, color2)
        CGContextSetLineWidth(ctx, 2.0)
        CGContextAddPath(ctx, path)
        CGContextStrokePath(ctx)
        
        /////////////
        // cleanup //
        /////////////
        
        CGColorSpaceRelease(csp)
        CGPathRelease(path)
    }
}

class KeyboardKeyView: UIControl {
    
    var button: UIButton
    var background: KeyboardKeyBackground
    
    var text: String! {
        didSet {
            self.redrawText()
        }
    }
    
    override var frame: CGRect {
        didSet {
            self.redrawText()
        }
    }
    
    override var enabled: Bool {
        didSet {
            self.button.enabled = enabled
            self.background.enabled = enabled
        }
    }
    
    override var selected: Bool {
        didSet {
            self.button.selected = selected;
            self.background.selected = selected
        }
    }
    
    override var highlighted: Bool {
        didSet {
            self.button.highlighted = highlighted;
            self.background.highlighted = highlighted
        }
    }
    
    init(frame: CGRect) {
        button = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        background = KeyboardKeyBackground(frame: CGRectZero)
        
        super.init(frame: frame)
        
        self.addSubview(background)
        self.addSubview(button)
        
        let normalTextColor = [0.5, 0.5, 0.9]
        let disabledTextColor = normalTextColor.map { $0 * 1.5 }
        let selectedTextColor = normalTextColor.map { $0 * 0.75 }
        
        self.button.setTitleColor(UIColor(red: normalTextColor[0], green: normalTextColor[1], blue: normalTextColor[2], alpha: 1.0), forState:UIControlState.Normal)
        self.button.setTitleColor(UIColor(red: disabledTextColor[0], green: disabledTextColor[1], blue: disabledTextColor[2], alpha: 1.0), forState:UIControlState.Disabled)
        self.button.setTitleColor(UIColor(red: selectedTextColor[0], green: selectedTextColor[1], blue: selectedTextColor[2], alpha: 1.0), forState:UIControlState.Selected)
        
//        self.button.setTitleShadowColor(UIColor.blueColor(), forState: UIControlState.Normal);
        
        self.button.titleLabel.font = self.button.titleLabel.font.fontWithSize(frame.height * 0.50)
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        return super.sizeThatFits(size)
    }
    
    func redrawText() {
        self.background.frame = self.frame
        self.button.frame = self.frame
        
        self.button.setTitle(self.text, forState: UIControlState.Normal)
    }
}

////////////////////////////
// HERE BE THE PLAYGROUND //
////////////////////////////

///////////////
// CONSTANTS //
///////////////

let w = 80
let h = 100

///////////////
// EXECUTION //
///////////////

var allKeys: Array<KeyboardKeyView> = []

class TestTarget {
    func test(caller: KeyboardKeyView) {
        caller
    }
}

var target = TestTarget()

let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
let alphabetCount = countElements(alphabet)
let randomIndex = (Int(arc4random()) % alphabetCount)
var i = 0
for char in alphabet {
    if (i != randomIndex) {
        i++
        continue
    }
    
    let key = KeyboardKeyView(frame: CGRect(x: 0, y: 0, width: w, height: h))
    key.text = String(char)
    allKeys.append(key)
    key.addTarget(target, action: "test:", forControlEvents: UIControlEvents.TouchUpInside)
    
    key
    
    break
}

let longKey = KeyboardKeyView(frame: CGRect(x: 0, y: 0, width: 300, height: h))
longKey.text = "Space"
allKeys.append(longKey)
longKey

for key in allKeys {
    continue
    
    let maxChunk = 0.4
    var frameWidthChange = (Double(w) * maxChunk) - Double(arc4random()) % (2 * (Double(w) * maxChunk))
    var frameHeightChange = (Double(h) * maxChunk) - Double(arc4random()) % (2 * (Double(h) * maxChunk))
    
    var frame = key.frame
    var frameSize = frame.size
    frameSize.width += frameWidthChange
    frameSize.height += frameHeightChange
    frame.size = frameSize
    key.frame = frame
    
//    key.enabled = false
//    key.selected = true
    
    key
}

let gap = 2.0
let viewWidth = 800.0
//var viewWidth = allKeys.reduce(0, {(acc: Double, val: KeyboardKeyView) -> Double in acc + gap + val.bounds.width})

var fauxKeyboard = UIView(frame: CGRect(x: 0, y: 0, width: viewWidth, height: 0))
fauxKeyboard.layer.borderColor = UIColor.redColor().CGColor
fauxKeyboard.layer.borderWidth = 3
fauxKeyboard.layer.backgroundColor = UIColor.lightGrayColor().CGColor

var runningSum = gap
var highestKeyInRow = 0.0
var rowOffset = gap
var line = 0
for i in 0..allKeys.count {
    var key = allKeys[i]
    
    if runningSum + key.bounds.width + gap > viewWidth {
        rowOffset += highestKeyInRow + gap
        highestKeyInRow = 0
        line += 1
        runningSum = 0
    }
    
    var frame = key.frame
    var frameOrigin = frame.origin
    frameOrigin.x = runningSum
    frameOrigin.y = rowOffset
    frame.origin = frameOrigin
    key.frame = frame
    
    runningSum += key.bounds.width/2.0 + gap
    highestKeyInRow = max(highestKeyInRow, key.frame.height)
    
    fauxKeyboard.addSubview(key)
}

rowOffset += highestKeyInRow + gap + 20

fauxKeyboard.frame = CGRectMake(0, 0, viewWidth, rowOffset)

longKey.selected = true
fauxKeyboard

var button = UIButton.buttonWithType(UIButtonType.System) as UIButton
button.setTitle("test", forState: .Normal)
button.sizeToFit()
