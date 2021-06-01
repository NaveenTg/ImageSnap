//
//  ImageSnapDimmingView.swift
//  
//
//  Created by Navi on 01/06/21.
//

import UIKit

class ImageSnapDimmingView: UIView, ImageSnapMaskProtocol {
    var imageSnapShapeType: ImageSnapShapeType = .rect
    
    convenience init(imageSnapShapeType: ImageSnapShapeType = .rect) {
        self.init(frame: CGRect.zero)
        self.imageSnapShapeType = imageSnapShapeType
        initialize()
    }
    
    func setMask() {
        let layer = createOverLayer(opacity: 0.5)
        self.layer.addSublayer(layer)
    }
}
