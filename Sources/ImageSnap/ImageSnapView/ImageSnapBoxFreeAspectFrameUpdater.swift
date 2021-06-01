//
//  ImageSnapBoxFreeAspectFrameUpdater.swift
//  
//
//  Created by Navi on 31/05/21.
//

import UIKit

struct ImageSnapBoxFreeAspectFrameUpdater {
    var minimumAspectRatio = CGFloat(0)
    
    private var contentFrame = CGRect.zero
    private var imageSnapOriginFrame = CGRect.zero
    private(set) var imageSnapBoxFrame = CGRect.zero
    private var tappedEdge = ImageSnapViewOverlayEdge.none
    
    init(tappedEdge: ImageSnapViewOverlayEdge, contentFrame: CGRect, imageSnapOriginFrame: CGRect, imageSnapBoxFrame: CGRect) {
        self.tappedEdge = tappedEdge
        self.contentFrame = contentFrame
        self.imageSnapOriginFrame = imageSnapOriginFrame
        self.imageSnapBoxFrame = imageSnapBoxFrame
    }
    
    mutating func updateImageSnapBoxFrame(xDelta: CGFloat, yDelta: CGFloat) {
        func newAspectRatioValid(withNewSize newSize: CGSize) -> Bool {
            return min(newSize.width, newSize.height) / max(newSize.width, newSize.height) >= minimumAspectRatio
        }
        
        func handleLeftEdgeFrameUpdate(newSize: CGSize) {
            if newAspectRatioValid(withNewSize: newSize) {
                imageSnapBoxFrame.origin.x = imageSnapOriginFrame.origin.x + xDelta
                imageSnapBoxFrame.size.width = newSize.width
            }
        }
        
        func handleRightEdgeFrameUpdate(newSize: CGSize) {
            if newAspectRatioValid(withNewSize: newSize) {
                imageSnapBoxFrame.size.width = newSize.width
            }
        }
        
        func handleTopEdgeFrameUpdate(newSize: CGSize) {
            if newAspectRatioValid(withNewSize: newSize) {
                imageSnapBoxFrame.origin.y = imageSnapOriginFrame.origin.y + yDelta
                imageSnapBoxFrame.size.height = newSize.height
            }
        }
        
        func handleBottomEdgeFrameUpdate(newSize: CGSize) {
            if newAspectRatioValid(withNewSize: newSize) {
                imageSnapBoxFrame.size.height = newSize.height
            }
        }
        
        func getNewImageSnapFrameSize(byTappedEdge tappedEdge: ImageSnapViewOverlayEdge) -> CGSize {
            let tappedEdgeImageSnapFrameUpdateRule: [ImageSnapViewOverlayEdge: (xDelta: CGFloat, yDelta: CGFloat)] = [.left: (-xDelta, 0), .right: (xDelta, 0), .top: (0, -yDelta), .bottom: (0, yDelta), .topLeft: (-xDelta, -yDelta), .topRight: (xDelta, -yDelta), .bottomLeft: (-xDelta, yDelta), .bottomRight: (xDelta, yDelta)]
            
            guard let delta = tappedEdgeImageSnapFrameUpdateRule[tappedEdge] else {
                return imageSnapOriginFrame.size
            }
            
            return CGSize(width: imageSnapOriginFrame.width + delta.xDelta, height: imageSnapOriginFrame.height + delta.yDelta)
        }
        
        func updateImageSnapBoxFrame() {
            let newSize = getNewImageSnapFrameSize(byTappedEdge: tappedEdge)

            switch tappedEdge {
            case .left:
                handleLeftEdgeFrameUpdate(newSize: newSize)
            case .right:
                handleRightEdgeFrameUpdate(newSize: newSize)
            case .top:
                handleTopEdgeFrameUpdate(newSize: newSize)
            case .bottom:
                handleBottomEdgeFrameUpdate(newSize: newSize)
            case .topLeft:
                handleTopEdgeFrameUpdate(newSize: newSize)
                handleLeftEdgeFrameUpdate(newSize: newSize)
            case .topRight:
                handleTopEdgeFrameUpdate(newSize: newSize)
                handleRightEdgeFrameUpdate(newSize: newSize)
            case .bottomLeft:
                handleBottomEdgeFrameUpdate(newSize: newSize)
                handleLeftEdgeFrameUpdate(newSize: newSize)
            case .bottomRight:
                handleBottomEdgeFrameUpdate(newSize: newSize)
                handleRightEdgeFrameUpdate(newSize: newSize)
            default:
                return
            }
        }
        
        updateImageSnapBoxFrame()
    }
}

