//
//  ImageSnapVisualEffectView.swift
//  
//
//  Created by Navi on 01/06/21.
//

import UIKit

class ImageSnapVisualEffectView: UIVisualEffectView, ImageSnapMaskProtocol {
    var imageSnapShapeType: ImageSnapShapeType = .rect
    
    fileprivate var translucencyEffect: UIVisualEffect?
    
    convenience init(imageSnapShapeType: ImageSnapShapeType = .rect, effectType: ImageSnapVisualEffectType = .blurDark) {
        
        let (translucencyEffect, backgroundColor) = ImageSnapVisualEffectView.getEffect(byType: effectType)
        
        self.init(effect: translucencyEffect)
        self.imageSnapShapeType = imageSnapShapeType
        self.translucencyEffect = translucencyEffect
        self.backgroundColor = backgroundColor
        
        initialize()
    }
        
    func setMask() {
        let layer = createOverLayer(opacity: 0.98)
        
        let maskView = UIView(frame: self.bounds)
        maskView.clipsToBounds = true
        maskView.layer.addSublayer(layer)
        
        self.mask = maskView
    }
    
    static func getEffect(byType type: ImageSnapVisualEffectType) -> (UIVisualEffect?, UIColor) {
        switch type {
            case .blurDark: return (UIBlurEffect(style: .dark), .clear)
            case .dark: return (nil, UIColor.black.withAlphaComponent(0.75))
            case .light: return (nil, UIColor.black.withAlphaComponent(0.35))
            case .none: return (nil, .black)
        }
    }
    
}
