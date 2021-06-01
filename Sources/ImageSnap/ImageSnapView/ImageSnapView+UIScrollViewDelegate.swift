//
//  ImageSnapView+UIScrollViewDelegate.swift
//  
//
//  Created by Navi on 31/05/21.
//

import Foundation
import UIKit

extension ImageSnapView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageContainer
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel.setTouchImageStatus()
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.delegate?.imageSnapViewDidBeginResize(self)
        viewModel.setTouchImageStatus()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        viewModel.setBetweenOperationStatus()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.delegate?.imageSnapViewDidEndResize(self)
        makeSureImageContainsImageSnapOverlay()
        
        manualZoomed = true
        viewModel.setBetweenOperationStatus()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            viewModel.setBetweenOperationStatus()
        }
    }
}


