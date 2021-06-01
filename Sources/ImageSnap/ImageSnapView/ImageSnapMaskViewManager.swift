//
//  ImageSnapMaskViewManager.swift
//  
//
//  Created by Navi on 31/05/21.
//

import UIKit

class ImageSnapMaskViewManager {
    fileprivate var dimmingView: ImageSnapDimmingView!
    fileprivate var visualEffectView: ImageSnapVisualEffectView!
    
    var imageSnapShapeType: ImageSnapShapeType = .rect
    var imageSnapVisualEffectType: ImageSnapVisualEffectType = .blurDark
    
    init(with superview: UIView,
         imageSnapShapeType: ImageSnapShapeType = .rect,
         imageSnapVisualEffectType: ImageSnapVisualEffectType = .blurDark) {
        
        setup(in: superview)
        self.imageSnapShapeType = imageSnapShapeType
        self.imageSnapVisualEffectType = imageSnapVisualEffectType
    }
    
    private func setupOverlayView(in view: UIView) {
        dimmingView = ImageSnapDimmingView(imageSnapShapeType: imageSnapShapeType)
        dimmingView.isUserInteractionEnabled = false
        dimmingView.alpha = 0
        view.addSubview(dimmingView)
    }
    
    private func setupTranslucencyView(in view: UIView) {
        visualEffectView = ImageSnapVisualEffectView(imageSnapShapeType: imageSnapShapeType, effectType: imageSnapVisualEffectType)
        visualEffectView.isUserInteractionEnabled = false
        view.addSubview(visualEffectView)
    }

    func setup(in view: UIView) {
        setupOverlayView(in: view)
        setupTranslucencyView(in: view)
    }
    
    func removeMaskViews() {
        dimmingView.removeFromSuperview()
        visualEffectView.removeFromSuperview()
    }
    
    func bringMaskViewsToFront() {
        dimmingView.superview?.bringSubviewToFront(dimmingView)
        visualEffectView.superview?.bringSubviewToFront(visualEffectView)
    }
    
    func showDimmingBackground() {
        UIView.animate(withDuration: 0.1) {
            self.dimmingView.alpha = 1
            self.visualEffectView.alpha = 0
        }
    }
    
    func showVisualEffectBackground() {
        UIView.animate(withDuration: 0.5) {
            self.dimmingView.alpha = 0
            self.visualEffectView.alpha = 1
        }
    }
    
    func adaptMaskTo(match imageSnapRect: CGRect) {
        dimmingView.adaptMaskTo(match: imageSnapRect)
        visualEffectView.adaptMaskTo(match: imageSnapRect)
    }
}

