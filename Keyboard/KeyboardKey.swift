//
//  KeyboardKey.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

// TODO: correct corner radius
// TODO: refactor

// popup constraints have to be setup with the topmost view in mind; hence these callbacks
protocol KeyboardKeyProtocol: class {
    func popupFrame(for key: KeyboardKey, direction: Direction) -> CGRect
    func willShowPopup(for key: KeyboardKey, direction: Direction) //may be called multiple times during layout
    func willHidePopup(for key: KeyboardKey)
}

enum VibrancyType {
    case lightSpecial
    case darkSpecial
    case darkRegular
}

class KeyboardKey: UIControl {
    
    weak var delegate: KeyboardKeyProtocol?
    
    var vibrancy: VibrancyType?
    
    var text: String {
        didSet {
            self.label.text = text
            self.label.frame = CGRect(x: self.labelInset, y: self.labelInset, width: self.bounds.width - self.labelInset * 2, height: self.bounds.height - self.labelInset * 2)
            self.redrawText()
        }
    }
    
    var color: UIColor { didSet { updateColors() }}
    var underColor: UIColor { didSet { updateColors() }}
    var borderColor: UIColor { didSet { updateColors() }}
    var popupColor: UIColor { didSet { updateColors() }}
    var drawUnder: Bool { didSet { updateColors() }}
    var drawOver: Bool { didSet { updateColors() }}
    var drawBorder: Bool { didSet { updateColors() }}
    var underOffset: CGFloat { didSet { updateColors() }}
    
    var textColor: UIColor { didSet { updateColors() }}
    var downColor: UIColor? { didSet { updateColors() }}
    var downUnderColor: UIColor? { didSet { updateColors() }}
    var downBorderColor: UIColor? { didSet { updateColors() }}
    var downTextColor: UIColor? { didSet { updateColors() }}
    
    var labelInset: CGFloat = 0 {
        didSet {
            if oldValue != labelInset {
                self.label.frame = CGRect(x: self.labelInset, y: self.labelInset, width: self.bounds.width - self.labelInset * 2, height: self.bounds.height - self.labelInset * 2)
            }
        }
    }
    
    var shouldRasterize: Bool = false {
        didSet {
            for view in [self.displayView, self.borderView, self.underView] {
                view?.layer.shouldRasterize = shouldRasterize
                view?.layer.rasterizationScale = UIScreen.main.scale
            }
        }
    }
    
    var popupDirection: Direction?
    
    override var isEnabled: Bool { didSet { updateColors() }}
    override var isSelected: Bool {
        didSet {
            updateColors()
        }
    }
    override var isHighlighted: Bool {
        didSet {
            updateColors()
        }
    }
    
    override var frame: CGRect {
        didSet {
            self.redrawText()
        }
    }
    
    var label: UILabel
    var popupLabel: UILabel?
    var shape: Shape? {
        didSet {
            if oldValue != nil && shape == nil {
                oldValue?.removeFromSuperview()
            }
            self.redrawShape()
            updateColors()
        }
    }
    
    var background: KeyboardKeyBackground
    var popup: KeyboardKeyBackground?
    var connector: KeyboardConnector?
    
    var displayView: ShapeView
    var borderView: ShapeView?
    var underView: ShapeView?
    
    var shadowView: UIView
    var shadowLayer: CALayer
    
    init(vibrancy optionalVibrancy: VibrancyType?) {
        self.vibrancy = optionalVibrancy
        
        self.displayView = ShapeView()
        self.underView = ShapeView()
        self.borderView = ShapeView()
        
        self.shadowLayer = CAShapeLayer()
        self.shadowView = UIView()
        
        self.label = UILabel()
        self.text = ""
        
        self.color = UIColor.white
        self.underColor = UIColor.gray
        self.borderColor = UIColor.black
        self.popupColor = UIColor.white
        self.drawUnder = true
        self.drawOver = true
        self.drawBorder = false
        self.underOffset = 1
        
        self.background = KeyboardKeyBackground(cornerRadius: 4, underOffset: self.underOffset)
        
        self.textColor = UIColor.black
        self.popupDirection = nil
        
        super.init(frame: CGRect.zero)
        
        self.addSubview(self.shadowView)
        self.shadowView.layer.addSublayer(self.shadowLayer)
        
        self.addSubview(self.displayView)
        if let underView = self.underView {
            self.addSubview(underView)
        }
        if let borderView = self.borderView {
            self.addSubview(borderView)
        }
        
        self.addSubview(self.background)
        self.background.addSubview(self.label)
        
        setupViews: do {
            self.displayView.isOpaque = false
            self.underView?.isOpaque = false
            self.borderView?.isOpaque = false
            
            self.shadowLayer.shadowOpacity = Float(0.2)
            self.shadowLayer.shadowRadius = 4
            self.shadowLayer.shadowOffset = CGSize(width: 0, height: 3)
            
            self.borderView?.lineWidth = CGFloat(0.5)
            self.borderView?.fillColor = UIColor.clear
            
            self.label.textAlignment = NSTextAlignment.center
            self.label.baselineAdjustment = UIBaselineAdjustment.alignCenters
            self.label.font = self.label.font.withSize(22)
            self.label.adjustsFontSizeToFitWidth = true
            self.label.minimumScaleFactor = CGFloat(0.1)
            self.label.isUserInteractionEnabled = false
            self.label.numberOfLines = 1
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func setNeedsLayout() {
        return super.setNeedsLayout()
    }
    
    var oldBounds: CGRect?
    override func layoutSubviews() {
        self.layoutPopupIfNeeded()
        
        let boundingBox = (self.popup != nil ? self.bounds.union(self.popup!.frame) : self.bounds)
        
        if self.bounds.width == 0 || self.bounds.height == 0 {
            return
        }
        if oldBounds != nil && boundingBox.size.equalTo(oldBounds!.size) {
            return
        }
        oldBounds = boundingBox

        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.background.frame = self.bounds
        self.label.frame = CGRect(x: self.labelInset, y: self.labelInset, width: self.bounds.width - self.labelInset * 2, height: self.bounds.height - self.labelInset * 2)
        
        self.displayView.frame = boundingBox
        self.shadowView.frame = boundingBox
        self.borderView?.frame = boundingBox
        self.underView?.frame = boundingBox
        
        CATransaction.commit()
        
        self.refreshViews()
    }
    
    func refreshViews() {
        self.refreshShapes()
        self.redrawText()
        self.redrawShape()
        self.updateColors()
    }
    
    func refreshShapes() {
        // TODO: dunno why this is necessary
        self.background.setNeedsLayout()
        
        self.background.layoutIfNeeded()
        self.popup?.layoutIfNeeded()
        self.connector?.layoutIfNeeded()
        
        let testPath = UIBezierPath()
        let edgePath = UIBezierPath()
        
        let unitSquare = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        // TODO: withUnder
        let addCurves = { (fromShape: KeyboardKeyBackground?, toPath: UIBezierPath, toEdgePaths: UIBezierPath) -> Void in
            if let shape = fromShape {
                let path = shape.fillPath
                let translatedUnitSquare = self.displayView.convert(unitSquare, from: shape)
                let transformFromShapeToView = CGAffineTransform(translationX: translatedUnitSquare.origin.x, y: translatedUnitSquare.origin.y)
                path?.apply(transformFromShapeToView)
                if path != nil { toPath.append(path!) }
                if let edgePaths = shape.edgePaths {
                    for (_, anEdgePath) in edgePaths.enumerated() {
                        let editablePath = anEdgePath
                        editablePath.apply(transformFromShapeToView)
                        toEdgePaths.append(editablePath)
                    }
                }
            }
        }
        
        addCurves(self.popup, testPath, edgePath)
        addCurves(self.connector, testPath, edgePath)
        
        let shadowPath = UIBezierPath(cgPath: testPath.cgPath)
        
        addCurves(self.background, testPath, edgePath)
        
        let underPath = self.background.underPath
        let translatedUnitSquare = self.displayView.convert(unitSquare, from: self.background)
        let transformFromShapeToView = CGAffineTransform(translationX: translatedUnitSquare.origin.x, y: translatedUnitSquare.origin.y)
        underPath?.apply(transformFromShapeToView)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if let _ = self.popup {
            self.shadowLayer.shadowPath = shadowPath.cgPath
        }
        
        self.underView?.curve = underPath
        self.displayView.curve = testPath
        self.borderView?.curve = edgePath
        
        if let borderLayer = self.borderView?.layer as? CAShapeLayer {
            borderLayer.strokeColor = UIColor.green.cgColor
        }
        
        CATransaction.commit()
    }
    
    func layoutPopupIfNeeded() {
        if self.popup != nil && self.popupDirection == nil {
            self.shadowView.isHidden = false
            self.borderView?.isHidden = false
            
            self.popupDirection = Direction.up
            
            self.layoutPopup(self.popupDirection!)
            self.configurePopup(self.popupDirection!)
            
            self.delegate?.willShowPopup(for: self, direction: self.popupDirection!)
        }
        else {
            self.shadowView.isHidden = true
            self.borderView?.isHidden = true
        }
    }
    
    func redrawText() {
//        self.keyView.frame = self.bounds
//        self.button.frame = self.bounds
//        
//        self.button.setTitle(self.text, forState: UIControlState.Normal)
    }
    
    func redrawShape() {
        if let shape = self.shape {
            self.text = ""
            shape.removeFromSuperview()
            self.addSubview(shape)
            
            let pointOffset: CGFloat = 4
            let size = CGSize(width: self.bounds.width - pointOffset - pointOffset, height: self.bounds.height - pointOffset - pointOffset)
            shape.frame = CGRect(
                x: CGFloat((self.bounds.width - size.width) / 2.0),
                y: CGFloat((self.bounds.height - size.height) / 2.0),
                width: size.width,
                height: size.height)
            
            shape.setNeedsLayout()
        }
    }
    
    func updateColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let switchColors = self.isHighlighted || self.isSelected
        
        if switchColors {
            if let downColor = self.downColor {
                self.displayView.fillColor = downColor
            }
            else {
                self.displayView.fillColor = self.color
            }
            
            if let downUnderColor = self.downUnderColor {
                self.underView?.fillColor = downUnderColor
            }
            else {
                self.underView?.fillColor = self.underColor
            }
            
            if let downBorderColor = self.downBorderColor {
                self.borderView?.strokeColor = downBorderColor
            }
            else {
                self.borderView?.strokeColor = self.borderColor
            }
            
            if let downTextColor = self.downTextColor {
                self.label.textColor = downTextColor
                self.popupLabel?.textColor = downTextColor
                self.shape?.color = downTextColor
            }
            else {
                self.label.textColor = self.textColor
                self.popupLabel?.textColor = self.textColor
                self.shape?.color = self.textColor
            }
        }
        else {
            self.displayView.fillColor = self.color
            
            self.underView?.fillColor = self.underColor
            
            self.borderView?.strokeColor = self.borderColor
            
            self.label.textColor = self.textColor
            self.popupLabel?.textColor = self.textColor
            self.shape?.color = self.textColor
        }
        
        if self.popup != nil {
            self.displayView.fillColor = self.popupColor
        }
        
        CATransaction.commit()
    }
    
    func layoutPopup(_ dir: Direction) {
        assert(self.popup != nil, "popup not found")
        
        if let popup = self.popup {
            if let delegate = self.delegate {
                let frame = delegate.popupFrame(for: self, direction: dir)
                popup.frame = frame
                popupLabel?.frame = popup.bounds
            }
            else {
                popup.frame = CGRect.zero
                popup.center = self.center
            }
        }
    }
    
    func configurePopup(_ direction: Direction) {
        assert(self.popup != nil, "popup not found")
        
        self.background.attach(direction)
        self.popup!.attach(direction.opposite())
        
        let kv = self.background
        let p = self.popup!
        
        self.connector?.removeFromSuperview()
        self.connector = KeyboardConnector(cornerRadius: 4, underOffset: self.underOffset, start: kv, end: p, startConnectable: kv, endConnectable: p, startDirection: direction, endDirection: direction.opposite())
        self.connector!.layer.zPosition = -1
        self.addSubview(self.connector!)
        
//        self.drawBorder = true
        
        if direction == Direction.up {
//            self.popup!.drawUnder = false
//            self.connector!.drawUnder = false
        }
    }
    
    func showPopup() {
        if self.popup == nil {
            self.layer.zPosition = 1000
            
            let popup = KeyboardKeyBackground(cornerRadius: 9.0, underOffset: self.underOffset)
            self.popup = popup
            self.addSubview(popup)
            
            let popupLabel = UILabel()
            popupLabel.textAlignment = self.label.textAlignment
            popupLabel.baselineAdjustment = self.label.baselineAdjustment
            popupLabel.font = self.label.font.withSize(22 * 2)
            popupLabel.adjustsFontSizeToFitWidth = self.label.adjustsFontSizeToFitWidth
            popupLabel.minimumScaleFactor = CGFloat(0.1)
            popupLabel.isUserInteractionEnabled = false
            popupLabel.numberOfLines = 1
            popupLabel.frame = popup.bounds
            popupLabel.text = self.label.text
            popup.addSubview(popupLabel)
            self.popupLabel = popupLabel
            
            self.label.isHidden = true
        }
    }
    
    @objc func hidePopup() {
        if self.popup != nil {
            self.delegate?.willHidePopup(for: self)
            
            self.popupLabel?.removeFromSuperview()
            self.popupLabel = nil
            
            self.connector?.removeFromSuperview()
            self.connector = nil
            
            self.popup?.removeFromSuperview()
            self.popup = nil
            
            self.label.isHidden = false
            self.background.attach(nil)
            
            self.layer.zPosition = 0
            
            self.popupDirection = nil
        }
    }
}

/*
    PERFORMANCE NOTES

    * CAShapeLayer: convenient and low memory usage, but chunky rotations
    * drawRect: fast, but high memory usage (looks like there's a backing store for each of the 3 views)
    * if I set CAShapeLayer to shouldRasterize, perf is *almost* the same as drawRect, while mem usage is the same as before
    * oddly, 3 CAShapeLayers show the same memory usage as 1 CAShapeLayer — where is the backing store?
    * might want to move to drawRect with combined draw calls for performance reasons — not clear yet
*/

class ShapeView: UIView {
    
    var shapeLayer: CAShapeLayer?

    override class var layerClass : AnyClass {
        return CAShapeLayer.self
    }
    
    var curve: UIBezierPath? {
        didSet {
            if let layer = self.shapeLayer {
                layer.path = curve?.cgPath
            }
            else {
                self.setNeedsDisplay()
            }
        }
    }
    
    var fillColor: UIColor? {
        didSet {
            if let layer = self.shapeLayer {
                layer.fillColor = fillColor?.cgColor
            }
            else {
                self.setNeedsDisplay()
            }
        }
    }

    var strokeColor: UIColor? {
        didSet {
            if let layer = self.shapeLayer {
                layer.strokeColor = strokeColor?.cgColor
            }
            else {
                self.setNeedsDisplay()
            }
        }
    }
    
    var lineWidth: CGFloat? {
        didSet {
            if let layer = self.shapeLayer {
                if let lineWidth = self.lineWidth {
                    layer.lineWidth = lineWidth
                }
            }
            else {
                self.setNeedsDisplay()
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.shapeLayer = self.layer as? CAShapeLayer
        
        // optimization: off by default to ensure quick mode transitions; re-enable during rotations
        //self.layer.shouldRasterize = true
        //self.layer.rasterizationScale = UIScreen.mainScreen().scale
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func drawCall(_ rect:CGRect) {
        if self.shapeLayer == nil {
            if let curve = self.curve {
                if let lineWidth = self.lineWidth {
                    curve.lineWidth = lineWidth
                }
                
                if let fillColor = self.fillColor {
                    fillColor.setFill()
                    curve.fill()
                }
                
                if let strokeColor = self.strokeColor {
                    strokeColor.setStroke()
                    curve.stroke()
                }
            }
        }
    }
    
//    override func drawRect(rect: CGRect) {
//        if self.shapeLayer == nil {
//            self.drawCall(rect)
//        }
//    }
}
