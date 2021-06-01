//
//  ImageSnapToolbarProtocol.swift
//  
//
//  Created by Navi on 31/05/21.
//

import UIKit

public protocol ImageSnapToolbarDelegate: AnyObject {
    func didSelectCancel()
    func didSelectImageSnap()
    func didSelectCounterClockwiseRotate()
    func didSelectClockwiseRotate()
    func didSelectReset()
    func didSelectSetRatio()
    func didSelectRatio(ratio: Double)
    func didSelectAlterImageSnapper90Degree()
}

public protocol ImageSnapToolbarProtocol: UIView {
    var heightForVerticalOrientationConstraint: NSLayoutConstraint? {get set}
    var widthForHorizonOrientationConstraint: NSLayoutConstraint? {get set}
    var imageSnapToolbarDelegate: ImageSnapToolbarDelegate? {get set}

    func createToolbarUI(config: ImageSnapToolbarConfig)
    func handleFixedRatioSetted(ratio: Double)
    func handleFixedRatioUnSetted()
    
    // MARK: - The following functions have default implementations
    func getRatioListPresentSourceView() -> UIView?
    
    func initConstraints(heightForVerticalOrientation: CGFloat,
                        widthForHorizonOrientation: CGFloat)
    
    func respondToOrientationChange()
    func adjustLayoutConstraintsWhenOrientationChange()
    func adjustUIWhenOrientationChange()
        
    func handleImageSnapViewDidBecomeResettable()
    func handleImageSnapViewDidBecomeUnResettable()
}

public extension ImageSnapToolbarProtocol {
    func getRatioListPresentSourceView() -> UIView? {
        return nil
    }
    
    func initConstraints(heightForVerticalOrientation: CGFloat, widthForHorizonOrientation: CGFloat) {
        heightForVerticalOrientationConstraint = heightAnchor.constraint(equalToConstant: heightForVerticalOrientation)
        widthForHorizonOrientationConstraint = widthAnchor.constraint(equalToConstant: widthForHorizonOrientation)
    }
    
    func respondToOrientationChange() {
        adjustLayoutConstraintsWhenOrientationChange()
        adjustUIWhenOrientationChange()
    }
    
    func adjustLayoutConstraintsWhenOrientationChange() {
        if Orientation.isPortrait {
            heightForVerticalOrientationConstraint?.isActive = true
            widthForHorizonOrientationConstraint?.isActive = false
        } else {
            heightForVerticalOrientationConstraint?.isActive = false
            widthForHorizonOrientationConstraint?.isActive = true
        }
    }
    
    func adjustUIWhenOrientationChange() {
        
    }
        
    func handleImageSnapViewDidBecomeResettable() {
        
    }
    
    func handleImageSnapViewDidBecomeUnResettable() {
        
    }
}
