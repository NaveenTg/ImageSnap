//
//  ImageSnapBoxLockedAspectFrameUpdater.swift
//  
//
//  Created by Navi on 31/05/21.
//

import Foundation
import UIKit

struct ImageSnapBoxLockedAspectFrameUpdater {
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
        var xDelta = xDelta
        var yDelta = yDelta
        
        let aspectRatio = (imageSnapOriginFrame.size.width / imageSnapOriginFrame.size.height);
        
        func updateHeightFromBothSides() {
            imageSnapBoxFrame.size.height = imageSnapBoxFrame.width / aspectRatio;
            imageSnapBoxFrame.origin.y = imageSnapOriginFrame.midY - (imageSnapBoxFrame.height * 0.5);
        }
        
        func updateWidthFromBothSides() {
            imageSnapBoxFrame.size.width = imageSnapBoxFrame.height * aspectRatio
            imageSnapBoxFrame.origin.x = imageSnapOriginFrame.midX - imageSnapBoxFrame.width * 0.5
        }
        
        func handleLeftEdgeFrameUpdate() {
            updateHeightFromBothSides()
            xDelta = max(0, xDelta)
            imageSnapBoxFrame.origin.x = imageSnapOriginFrame.origin.x + xDelta
            imageSnapBoxFrame.size.width = imageSnapOriginFrame.width - xDelta
            imageSnapBoxFrame.size.height = imageSnapBoxFrame.size.width / aspectRatio
        }
        
        func handleRightEdgeFrameUpdate() {
            updateHeightFromBothSides()
            imageSnapBoxFrame.size.width = min(imageSnapOriginFrame.width + xDelta, contentFrame.height * aspectRatio)
            imageSnapBoxFrame.size.height = imageSnapBoxFrame.size.width / aspectRatio
        }
        
        func handleTopEdgeFrameUpdate() {
            updateWidthFromBothSides()
            yDelta = max(0, yDelta)
            imageSnapBoxFrame.origin.y = imageSnapOriginFrame.origin.y + yDelta
            imageSnapBoxFrame.size.height = imageSnapOriginFrame.height - yDelta
            imageSnapBoxFrame.size.width = imageSnapOriginFrame.size.height * aspectRatio
        }
        
        func handleBottomEdgeFrameUpdate() {
            updateWidthFromBothSides()
            imageSnapBoxFrame.size.height = min(imageSnapOriginFrame.height + yDelta, contentFrame.width / aspectRatio)
            imageSnapBoxFrame.size.width = imageSnapBoxFrame.size.height * aspectRatio
        }
        
        let tappedEdgeImageSnapFrameUpdateRule: [ImageSnapViewOverlayEdge: (xDelta: CGFloat, yDelta: CGFloat)] = [.topLeft: (xDelta, yDelta), .topRight: (-xDelta, yDelta), .bottomLeft: (xDelta, -yDelta), .bottomRight: (-xDelta, -yDelta)]
        
        func setImageSnapBoxSize() {
            guard let delta = tappedEdgeImageSnapFrameUpdateRule[tappedEdge] else {
                return
            }
            
            var distance = CGPoint()
            distance.x = 1.0 - (delta.xDelta / imageSnapOriginFrame.width)
            distance.y = 1.0 - (delta.yDelta / imageSnapOriginFrame.height)
            let scale = (distance.x + distance.y) * 0.5
            
            imageSnapBoxFrame.size.width = ceil(imageSnapOriginFrame.width * scale)
            imageSnapBoxFrame.size.height = ceil(imageSnapOriginFrame.height * scale)
        }
        
        func handleTopLeftEdgeFrameUpdate() {
            xDelta = max(0, xDelta)
            yDelta = max(0, yDelta)
            
            setImageSnapBoxSize()
            imageSnapBoxFrame.origin.x = imageSnapOriginFrame.origin.x + (imageSnapOriginFrame.width - imageSnapBoxFrame.width)
            imageSnapBoxFrame.origin.y = imageSnapOriginFrame.origin.y + (imageSnapOriginFrame.height - imageSnapBoxFrame.height)
        }

        func handleTopRightEdgeFrameUpdate() {
            xDelta = max(0, xDelta)
            yDelta = max(0, yDelta)
            
            setImageSnapBoxSize()
            imageSnapBoxFrame.origin.y = imageSnapOriginFrame.origin.y + (imageSnapOriginFrame.height - imageSnapBoxFrame.height)
        }
        
        func handleBottomLeftEdgeFrameUpdate() {
            setImageSnapBoxSize()
            imageSnapBoxFrame.origin.x = imageSnapOriginFrame.maxX - imageSnapBoxFrame.width;
        }
        
        func handleBottomRightEdgeFrameUpdate() {
            setImageSnapBoxSize()
        }
        
        func updateImageSnapBoxFrame() {
            switch tappedEdge {
            case .left:
                handleLeftEdgeFrameUpdate()
            case .right:
                handleRightEdgeFrameUpdate()
            case .top:
                handleTopEdgeFrameUpdate()
            case .bottom:
                handleBottomEdgeFrameUpdate()
            case .topLeft:
                handleTopLeftEdgeFrameUpdate()
            case .topRight:
                handleTopRightEdgeFrameUpdate()
            case .bottomLeft:
                handleBottomLeftEdgeFrameUpdate()
            case .bottomRight:
                handleBottomRightEdgeFrameUpdate()
            default:
                print("none")
            }
        }
        
        updateImageSnapBoxFrame()
    }
}
