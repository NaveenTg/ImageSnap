//
//  ImageSnapViewModel.swift
//  
//
//  Created by Navi on 31/05/21.
//

import UIKit

enum ImageRotationType: CGFloat {
    case none = 0
    case counterclockwise90 = -90
    case counterclockwise180 = -180
    case counterclockwise270 = -270
    
    mutating func counterclockwiseRotate90() {
        if self == .counterclockwise270 {
            self = .none
        } else {
            self = ImageRotationType(rawValue: self.rawValue - 90) ?? .none
        }
    }
    
    mutating func clockwiseRotate90() {
        switch (self) {
        case .counterclockwise90:
            self = .none
        case .counterclockwise180:
            self = .counterclockwise90
        case .counterclockwise270:
            self = .counterclockwise180
        case .none:
            self = .counterclockwise270
        }
    }
}

class ImageSnapViewModel: NSObject {
    var statusChanged: (_ status: ImageSnapViewStatus)->Void = { _ in }
    
    var viewStatus: ImageSnapViewStatus = .initial {
        didSet {
            self.statusChanged(viewStatus)
        }
    }
    
    @objc dynamic var imageSnapBoxFrame = CGRect.zero
    var imageSnapOrignFrame = CGRect.zero
    
    var panOriginPoint = CGPoint.zero
    var tappedEdge = ImageSnapViewOverlayEdge.none
    
    var degrees: CGFloat = 0
    
    var radians: CGFloat {
        get {
          return degrees * CGFloat.pi / 180
        }
    }
    
    var rotationType: ImageRotationType = .none
    var aspectRatio: CGFloat = -1
    var imageSnapLeftTopOnImage: CGPoint = .zero
    var imageSnapRightBottomOnImage: CGPoint = CGPoint(x: 1, y: 1)
    
    func reset(forceFixedRatio: Bool = false) {
        imageSnapBoxFrame = .zero
        degrees = 0
        rotationType = .none
        
        if forceFixedRatio == false {
            aspectRatio = -1
        }
        
        imageSnapLeftTopOnImage = .zero
        imageSnapRightBottomOnImage = CGPoint(x: 1, y: 1)
        
        setInitialStatus()
    }
    
    func RotateBy90(rotateAngle: CGFloat) {
        if (rotateAngle < 0) {
            rotationType.counterclockwiseRotate90()
        } else {
            rotationType.clockwiseRotate90()
        }
    }
    
    func counterclockwiseRotateBy90() {
        rotationType.counterclockwiseRotate90()
    }
    
    func clockwiseRotateBy90() {
        rotationType.clockwiseRotate90()
    }

    func getTotalRadias(by radians: CGFloat) -> CGFloat {
        return radians + rotationType.rawValue * CGFloat.pi / 180
    }
    
    func getTotalRadians() -> CGFloat {
        return getTotalRadias(by: radians)
    }
    
    func getRatioType(byImageIsOriginalHorizontal isHorizontal: Bool) -> RatioType {
        if isUpOrUpsideDown() {
            return isHorizontal ? .horizontal : .vertical
        } else {
            return isHorizontal ? .vertical : .horizontal
        }
    }
    
    func isUpOrUpsideDown() -> Bool {
        return rotationType == .none || rotationType == .counterclockwise180
    }

    func prepareForImageSnap(byTouchPoint point: CGPoint) {
        panOriginPoint = point
        imageSnapOrignFrame = imageSnapBoxFrame
        
        tappedEdge = imageSnapEdge(forPoint: point)
        
        if tappedEdge == .none {
            setTouchImageStatus()
        } else {
            setTouchImageSnapboxHandleStatus()
        }
    }
    
    func resetImageSnapFrame(by frame: CGRect) {
        imageSnapBoxFrame = frame
        imageSnapOrignFrame = frame
    }
    
    func needImageSnap() -> Bool {
        return !imageSnapOrignFrame.equalTo(imageSnapBoxFrame)
    }
    
    func imageSnapEdge(forPoint point: CGPoint) -> ImageSnapViewOverlayEdge {
        let touchRect = imageSnapBoxFrame.insetBy(dx: -hotAreaUnit / 2, dy: -hotAreaUnit / 2)
        return GeometryHelper.getImageSnapEdge(forPoint: point, byTouchRect: touchRect, hotAreaUnit: hotAreaUnit)
    }
    
    func getNewImageSnapBoxFrame(with point: CGPoint, and contentFrame: CGRect, aspectRatioLockEnabled: Bool) -> CGRect {
        var point = point
        point.x = max(contentFrame.origin.x - imageSnapViewPadding, point.x)
        point.y = max(contentFrame.origin.y - imageSnapViewPadding, point.y)
        
        //The delta between where we first tapped, and where our finger is now
        let xDelta = ceil(point.x - panOriginPoint.x)
        let yDelta = ceil(point.y - panOriginPoint.y)
        
        let newImageSnapBoxFrame: CGRect
        if aspectRatioLockEnabled {
            var imageSnapBoxLockedAspectFrameUpdater = ImageSnapBoxLockedAspectFrameUpdater(tappedEdge: tappedEdge, contentFrame: contentFrame, imageSnapOriginFrame: imageSnapOrignFrame, imageSnapBoxFrame: imageSnapBoxFrame)
            imageSnapBoxLockedAspectFrameUpdater.updateImageSnapBoxFrame(xDelta: xDelta, yDelta: yDelta)
            newImageSnapBoxFrame = imageSnapBoxLockedAspectFrameUpdater.imageSnapBoxFrame
        } else {
            var imageSnapBoxFreeAspectFrameUpdater = ImageSnapBoxFreeAspectFrameUpdater(tappedEdge: tappedEdge, contentFrame: contentFrame, imageSnapOriginFrame: imageSnapOrignFrame, imageSnapBoxFrame: imageSnapBoxFrame)
            imageSnapBoxFreeAspectFrameUpdater.updateImageSnapBoxFrame(xDelta: xDelta, yDelta: yDelta)
            newImageSnapBoxFrame = imageSnapBoxFreeAspectFrameUpdater.imageSnapBoxFrame
        }

        return newImageSnapBoxFrame
    }
    
    func setImageSnapBoxFrame(by refImageSnapBox: CGRect, and imageRationH: Double) {
        var imageSnapBoxFrame = refImageSnapBox
        let center = imageSnapBoxFrame.center
        
        if (aspectRatio > CGFloat(imageRationH)) {
            imageSnapBoxFrame.size.height = imageSnapBoxFrame.width / aspectRatio
        } else {
            imageSnapBoxFrame.size.width = imageSnapBoxFrame.height * aspectRatio
        }
        
        imageSnapBoxFrame.origin.x = center.x - imageSnapBoxFrame.width / 2
        imageSnapBoxFrame.origin.y = center.y - imageSnapBoxFrame.height / 2
        
        self.imageSnapBoxFrame = imageSnapBoxFrame
    }
}

// MARK: - Handle view status changes
extension ImageSnapViewModel {
    func setInitialStatus() {
        viewStatus = .initial
    }
    
    func setRotatingStatus(by angle: CGAngle) {
        viewStatus = .rotating(angle: angle)
    }
    
    func setDegree90RotatingStatus() {
        viewStatus = .degree90Rotating
    }
    
    func setTouchImageStatus() {
        viewStatus = .touchImage
    }

    func setTouchRotationBoardStatus() {
        viewStatus = .touchRotationBoard
    }

    func setTouchImageSnapboxHandleStatus() {
        viewStatus = .touchImageSnapboxHandle(tappedEdge: tappedEdge)
    }
    
    func setBetweenOperationStatus() {
        viewStatus = .betweenOperation
    }
}
