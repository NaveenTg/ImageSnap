//
//  RotationDialPlate.swift
//  
//
//  Created by Navi on 01/06/21.
//

import UIKit

fileprivate let bigDegreeScaleNumber = 36
fileprivate let smallDegreeScaleNumber = bigDegreeScaleNumber * 5
fileprivate let margin: CGFloat = 0
fileprivate let spaceBetweenScaleAndNumber: CGFloat = 10

class RotationDialPlate: UIView {

    let smallDotLayer:CAReplicatorLayer = {
        var r = CAReplicatorLayer()
        r.instanceCount = smallDegreeScaleNumber
        r.instanceTransform =
            CATransform3DMakeRotation(
                2 * CGFloat.pi / CGFloat(r.instanceCount),
                0,0,1)
        
        return r
    }()
    
    let bigDotLayer:CAReplicatorLayer = {
        var r = CAReplicatorLayer()
        r.instanceCount = bigDegreeScaleNumber
        r.instanceTransform =
            CATransform3DMakeRotation(
                2 * CGFloat.pi / CGFloat(r.instanceCount),
                0,0,1)
        
        return r
    }()
    
    var config = DialConfig.Config()
    
    init(frame: CGRect, config: DialConfig.Config = DialConfig.Config()) {
        super.init(frame: frame)
        self.config = config
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func getSmallScaleMark() -> CALayer {
        let mark = CAShapeLayer()
        mark.frame = CGRect(x: 0, y: 0, width: 2, height: 2)
        mark.path = UIBezierPath(ovalIn: mark.bounds).cgPath
        mark.fillColor = config.smallScaleColor.cgColor
        
        return mark
    }
    
    private func getBigScaleMark() -> CALayer {
        let mark = CAShapeLayer()
        mark.frame = CGRect(x: 0, y: 0, width: 4, height: 4)
        mark.path = UIBezierPath(ovalIn: mark.bounds).cgPath
        mark.fillColor = config.bigScaleColor.cgColor
        
        return mark
    }
    
    private func setupAngleNumber() {
        let numberFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption2)
        let cgFont = CTFontCreateUIFontForLanguage(.label, numberFont.pointSize/2, nil)
        
        let numberPlateLayer = CALayer()
        numberPlateLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        numberPlateLayer.frame = self.bounds
        self.layer.addSublayer(numberPlateLayer)
        
        let origin = CGPoint(x: numberPlateLayer.frame.midX, y: numberPlateLayer.frame.midY)
        let startPos = CGPoint(x: numberPlateLayer.bounds.midX, y: numberPlateLayer.bounds.maxY - margin - spaceBetweenScaleAndNumber)
        let step = (2 * CGFloat.pi) / CGFloat(bigDegreeScaleNumber)
        for i in (0 ..< bigDegreeScaleNumber){
            
            guard i % config.numberShowSpan == 0 else {
                continue
            }
            
            let numberLayer = CATextLayer()
            numberLayer.bounds.size = CGSize(width: 30, height: 15)
            numberLayer.fontSize = numberFont.pointSize
            numberLayer.alignmentMode = CATextLayerAlignmentMode.center
            numberLayer.contentsScale = UIScreen.main.scale
            numberLayer.font = cgFont
            let angle = (i > bigDegreeScaleNumber / 2 ? i - bigDegreeScaleNumber : i) * 10
            numberLayer.string = "\(angle)"
            numberLayer.foregroundColor = config.numberColor.cgColor
            
            let stepChange = CGFloat(i) * step
            numberLayer.position = CGVector(from:origin, to:startPos).rotate(-stepChange).add(origin.vector).point.checked
            
            numberLayer.transform = CATransform3DMakeRotation(-stepChange, 0, 0, 1)
            numberPlateLayer.addSublayer(numberLayer)
        }
    }
    
    private func setupSmallScaleMarks() {
        smallDotLayer.frame = self.bounds
        smallDotLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let smallScaleMark = getSmallScaleMark()
        smallScaleMark.position = CGPoint(x: smallDotLayer.bounds.midX, y: margin)
        smallDotLayer.addSublayer(smallScaleMark)
        
        self.layer.addSublayer(smallDotLayer)
    }
    
    private func setupBigScaleMarks() {
        bigDotLayer.frame = self.bounds
        bigDotLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let bigScaleMark = getBigScaleMark()
        bigScaleMark.position = CGPoint(x: bigDotLayer.bounds.midX, y: margin)
        bigDotLayer.addSublayer(bigScaleMark)
        self.layer.addSublayer(bigDotLayer)
    }
    
    private func setCenterPart() {
        let layer = CAShapeLayer()
        let r: CGFloat = 4
        layer.frame = CGRect(x: (self.layer.bounds.width - r) / 2 , y: (self.layer.bounds.height - r) / 2, width: r, height: r)
        layer.path = UIBezierPath(ovalIn: layer.bounds).cgPath
        layer.fillColor = config.centerAxisColor.cgColor
        
        self.layer.addSublayer(layer)
    }
    
    private func setup() {
        setupSmallScaleMarks()
        setupBigScaleMarks()
        setupAngleNumber()
        setCenterPart()
    }
}
