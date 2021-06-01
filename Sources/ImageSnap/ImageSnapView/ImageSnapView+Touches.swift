//
//  ImageSnapView+Touches.swift
//  
//
//  Created by Navi on 31/05/21.
//

import Foundation
import UIKit

extension ImageSnapView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let p = self.convert(point, to: self)
        
        if let rotationDial = rotationDial, rotationDial.frame.contains(p) {
            return rotationDial
        }
        
        if (gridOverlayView.frame.insetBy(dx: -hotAreaUnit/2, dy: -hotAreaUnit/2).contains(p) &&
            !gridOverlayView.frame.insetBy(dx: hotAreaUnit/2, dy: hotAreaUnit/2).contains(p))
        {
            return self
        }
        
        if self.bounds.contains(p) {
            return self.scrollView
        }
        
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard touches.count == 1, let touch = touches.first else {
            return
        }
        
        delegate?.imageSnapViewDidBeginResize(self)
        
        if touch.view is RotationDial {
            viewModel.setTouchRotationBoardStatus()
            return
        }
        
        let point = touch.location(in: self)
        viewModel.prepareForImageSnap(byTouchPoint: point)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard touches.count == 1, let touch = touches.first else {
            return
        }
        
        if touch.view is RotationDial {
            return
        }
        
        let point = touch.location(in: self)
        updateImageSnapBoxFrame(with: point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if viewModel.needImageSnap() {
            gridOverlayView.handleEdgeUntouched()
            let contentRect = getContentBounds()
            adjustUIForNewImageSnap(contentRect: contentRect) {[weak self] in
                self?.delegate?.imageSnapViewDidEndResize(self!)
                self?.viewModel.setBetweenOperationStatus()
                self?.scrollView.updateMinZoomScale()
            }
        } else {
            delegate?.imageSnapViewDidEndResize(self)
            viewModel.setBetweenOperationStatus()
        }
    }
}
