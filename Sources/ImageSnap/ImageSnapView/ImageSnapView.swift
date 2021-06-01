//
//  ImageSnapView.swift
//  
//
//  Created by Navi on 31/05/21.
//

import UIKit

protocol ImageSnapViewDelegate: AnyObject {
    func imageSnapViewDidBecomeResettable(_ imageSnapView: ImageSnapView)
    func imageSnapViewDidBecomeUnResettable(_ imageSnapView: ImageSnapView)
    func imageSnapViewDidBeginResize(_ imageSnapView: ImageSnapView)
    func imageSnapViewDidEndResize(_ imageSnapView: ImageSnapView)
}

let imageSnapViewMinimumBoxSize: CGFloat = 42
let minimumAspectRatio: CGFloat = 0
let hotAreaUnit: CGFloat = 32
let imageSnapViewPadding:CGFloat = 14.0

class ImageSnapView: UIView {
    var imageSnapShapeType: ImageSnapShapeType = .rect
    var imageSnapVisualEffectType: ImageSnapVisualEffectType = .blurDark
    var angleDashboardHeight: CGFloat = 60
    
    var image: UIImage {
        didSet {
            imageContainer.image = image
        }
    }
    let viewModel: ImageSnapViewModel
    
    weak var delegate: ImageSnapViewDelegate? {
        didSet {
            checkImageStatusChanged()
        }
    }
    
    var aspectRatioLockEnabled = false

    let imageContainer: ImageContainer
    let gridOverlayView: ImageSnapOverlayView
    var rotationDial: RotationDial?

    lazy var scrollView = ImageSnapScrollView(frame: bounds)
    lazy var imageSnapMaskViewManager = ImageSnapMaskViewManager(with: self,
                                                       imageSnapShapeType: imageSnapShapeType,
                                                       imageSnapVisualEffectType: imageSnapVisualEffectType)

    var manualZoomed = false
    private var imageSnapFrameKVO: NSKeyValueObservation?
    var forceFixedRatio = false
    var imageStatusChangedCheckForForceFixedRatio = false
    
    deinit {
        print("ImageSnapView deinit.")
    }
    
    init(image: UIImage, viewModel: ImageSnapViewModel = ImageSnapViewModel()) {
        self.image = image
        self.viewModel = viewModel
        
        imageContainer = ImageContainer()
        gridOverlayView = ImageSnapOverlayView()

        super.init(frame: CGRect.zero)
        
        self.viewModel.statusChanged = { [weak self] status in
            self?.render(by: status)
        }
        
        imageSnapFrameKVO = viewModel.observe(\.imageSnapBoxFrame,
                                         options: [.new, .old])
        { [unowned self] _, changed in
            guard let imageSnapFrame = changed.newValue else { return }
            self.gridOverlayView.frame = imageSnapFrame
            self.imageSnapMaskViewManager.adaptMaskTo(match: imageSnapFrame)
        }
        
        initalRender()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initalRender() {
        setupUI()
        checkImageStatusChanged()
    }
    
    private func render(by viewStatus: ImageSnapViewStatus) {
        gridOverlayView.isHidden = false
        
        switch viewStatus {
        case .initial:
            initalRender()
        case .rotating(let angle):
            viewModel.degrees = angle.degrees
            rotateScrollView()
        case .degree90Rotating:
            imageSnapMaskViewManager.showVisualEffectBackground()
            gridOverlayView.isHidden = true
            rotationDial?.isHidden = true
        case .touchImage:
            imageSnapMaskViewManager.showDimmingBackground()
            gridOverlayView.gridLineNumberType = .imageSnap
            gridOverlayView.setGrid(hidden: false, animated: true)
        case .touchImageSnapboxHandle(let tappedEdge):
            gridOverlayView.handleEdgeTouched(with: tappedEdge)
            rotationDial?.isHidden = true
            imageSnapMaskViewManager.showDimmingBackground()
        case .touchRotationBoard:
            gridOverlayView.gridLineNumberType = .rotate
            gridOverlayView.setGrid(hidden: false, animated: true)
            imageSnapMaskViewManager.showDimmingBackground()
        case .betweenOperation:
            gridOverlayView.handleEdgeUntouched()
            rotationDial?.isHidden = false
            adaptAngleDashboardToImageSnapBox()
            imageSnapMaskViewManager.showVisualEffectBackground()
            checkImageStatusChanged()
        }
    }
    
    private func isTheSamePoint(p1: CGPoint, p2: CGPoint) -> Bool {
        let tolerance = CGFloat.ulpOfOne * 10
        if abs(p1.x - p2.x) > tolerance { return false }
        if abs(p1.y - p2.y) > tolerance { return false }
        
        return true
    }
    
    private func imageStatusChanged() -> Bool {
        if viewModel.getTotalRadians() != 0 { return true }
        
        if (forceFixedRatio) {
            if imageStatusChangedCheckForForceFixedRatio {
                imageStatusChangedCheckForForceFixedRatio = false
                return scrollView.zoomScale != 1
            }
        }
        
        if !isTheSamePoint(p1: getImageLeftTopAnchorPoint(), p2: .zero) {
            return true
        }
        
        if !isTheSamePoint(p1: getImageRightBottomAnchorPoint(), p2: CGPoint(x: 1, y: 1)) {
            return true
        }
        
        return false
    }
    
    private func checkImageStatusChanged() {
        if imageStatusChanged() {
            delegate?.imageSnapViewDidBecomeResettable(self)
        } else {
            delegate?.imageSnapViewDidBecomeUnResettable(self)
        }
    }
    
    private func setupUI() {
        setupScrollView()
        imageContainer.image = image
        
        scrollView.addSubview(imageContainer)
        scrollView.imageContainer = imageContainer
        
        setGridOverlayView()
    }
    
    func resetUIFrame() {
        imageSnapMaskViewManager.removeMaskViews()
        imageSnapMaskViewManager.setup(in: self)
        viewModel.resetImageSnapFrame(by: getInitialImageSnapBoxRect())
                
        scrollView.transform = .identity
        scrollView.resetBy(rect: viewModel.imageSnapBoxFrame)
        
        imageContainer.frame = scrollView.bounds
        imageContainer.center = CGPoint(x: scrollView.bounds.width/2, y: scrollView.bounds.height/2)

        gridOverlayView.superview?.bringSubviewToFront(gridOverlayView)
        
        setupAngleDashboard()
        
        if aspectRatioLockEnabled {
            setFixedRatioImageSnapBox()
        }
    }
    
    func adaptForImageSnapBox() {
        resetUIFrame()
    }
    
    private func setupScrollView() {
        scrollView.touchesBegan = { [weak self] in
            self?.viewModel.setTouchImageStatus()
        }
        
        scrollView.touchesEnded = { [weak self] in
            self?.viewModel.setBetweenOperationStatus()
        }
        
        scrollView.delegate = self
        addSubview(scrollView)
    }
    
    private func setGridOverlayView() {
        gridOverlayView.isUserInteractionEnabled = false
        gridOverlayView.gridHidden = true
        addSubview(gridOverlayView)
    }
    
    private func setupAngleDashboard() {
        if angleDashboardHeight == 0 {
            return
        }
        
        if rotationDial != nil {
            rotationDial?.removeFromSuperview()
        }
        
        var config = DialConfig.Config()
        config.backgroundColor = .clear
        config.angleShowLimitType = .limit(angle: CGAngle(degrees: 40))
        config.rotationLimitType = .limit(angle: CGAngle(degrees: 45))
        config.numberShowSpan = 1
        
        let boardLength = min(bounds.width, bounds.height) * 0.6
        let rotationDial = RotationDial(frame: CGRect(x: 0, y: 0, width: boardLength, height: angleDashboardHeight), config: config)
        self.rotationDial = rotationDial
        rotationDial.isUserInteractionEnabled = true
        addSubview(rotationDial)
        
        rotationDial.setRotationCenter(by: gridOverlayView.center, of: self)
        
        rotationDial.didRotate = { [unowned self] angle in
            if self.forceFixedRatio {
                let newRadians = self.viewModel.getTotalRadias(by: angle.radians)
                self.viewModel.setRotatingStatus(by: CGAngle(radians: newRadians))
            } else {
                self.viewModel.setRotatingStatus(by: angle)
            }
        }
        
        rotationDial.didFinishedRotate = { [unowned self] in
            self.viewModel.setBetweenOperationStatus()
        }
        
        rotationDial.rotateDialPlate(by: CGAngle(radians: viewModel.radians))
        adaptAngleDashboardToImageSnapBox()
    }
    
    private func adaptAngleDashboardToImageSnapBox() {
        guard let rotationDial = rotationDial else { return }

        if Orientation.isPortrait {
            rotationDial.transform = CGAffineTransform(rotationAngle: 0)
            rotationDial.frame.origin.x = gridOverlayView.frame.origin.x +  (gridOverlayView.frame.width - rotationDial.frame.width) / 2
            rotationDial.frame.origin.y = gridOverlayView.frame.maxY
        } else if Orientation.isLandscapeLeft {
            rotationDial.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            rotationDial.frame.origin.x = gridOverlayView.frame.maxX
            rotationDial.frame.origin.y = gridOverlayView.frame.origin.y + (gridOverlayView.frame.height - rotationDial.frame.height) / 2
        } else if Orientation.isLandscapeRight {
            rotationDial.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            rotationDial.frame.origin.x = gridOverlayView.frame.minX - rotationDial.frame.width
            rotationDial.frame.origin.y = gridOverlayView.frame.origin.y + (gridOverlayView.frame.height - rotationDial.frame.height) / 2
        }
    }
    
    func updateImageSnapBoxFrame(with point: CGPoint) {
        let contentFrame = getContentBounds()
        let newImageSnapBoxFrame = viewModel.getNewImageSnapBoxFrame(with: point, and: contentFrame, aspectRatioLockEnabled: aspectRatioLockEnabled)
        
        let contentBounds = getContentBounds()
        
        guard newImageSnapBoxFrame.width >= imageSnapViewMinimumBoxSize
                && newImageSnapBoxFrame.minX >= contentBounds.minX
                && newImageSnapBoxFrame.maxX <= contentBounds.maxX
                && newImageSnapBoxFrame.height >= imageSnapViewMinimumBoxSize
                && newImageSnapBoxFrame.minY >= contentBounds.minY
                && newImageSnapBoxFrame.maxY <= contentBounds.maxY else {
            return
        }
        
        if imageContainer.contains(rect: newImageSnapBoxFrame, fromView: self) {
            viewModel.imageSnapBoxFrame = newImageSnapBoxFrame
        } else {
            let minX = max(viewModel.imageSnapBoxFrame.minX, newImageSnapBoxFrame.minX)
            let minY = max(viewModel.imageSnapBoxFrame.minY, newImageSnapBoxFrame.minY)
            let maxX = min(viewModel.imageSnapBoxFrame.maxX, newImageSnapBoxFrame.maxX)
            let maxY = min(viewModel.imageSnapBoxFrame.maxY, newImageSnapBoxFrame.maxY)

            var rect: CGRect
            
            rect = CGRect(x: minX, y: minY, width: newImageSnapBoxFrame.width, height: maxY - minY)
            if imageContainer.contains(rect: rect, fromView: self) {
                viewModel.imageSnapBoxFrame = rect
                return
            }
            
            rect = CGRect(x: minX, y: minY, width: maxX - minX, height: newImageSnapBoxFrame.height)
            if imageContainer.contains(rect: rect, fromView: self) {
                viewModel.imageSnapBoxFrame = rect
                return
            }
            
            rect = CGRect(x: newImageSnapBoxFrame.minX, y: minY, width: newImageSnapBoxFrame.width, height: maxY - minY)
            if imageContainer.contains(rect: rect, fromView: self) {
                viewModel.imageSnapBoxFrame = rect
                return
            }

            rect = CGRect(x: minX, y: newImageSnapBoxFrame.minY, width: maxX - minX, height: newImageSnapBoxFrame.height)
            if imageContainer.contains(rect: rect, fromView: self) {
                viewModel.imageSnapBoxFrame = rect
                return
            }
                                                
            viewModel.imageSnapBoxFrame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }
}


// MARK: - Adjust UI
extension ImageSnapView {
    private func rotateScrollView() {
        let totalRadians = forceFixedRatio ? viewModel.radians : viewModel.getTotalRadians()
        
        self.scrollView.transform = CGAffineTransform(rotationAngle: totalRadians)
        self.updatePosition(by: totalRadians)
    }
    
    private func getInitialImageSnapBoxRect() -> CGRect {
        guard image.size.width > 0 && image.size.height > 0 else {
            return .zero
        }
        
        let outsideRect = getContentBounds()
        
        let insideRect: CGRect
        
        if viewModel.isUpOrUpsideDown() {
            insideRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        } else {
            insideRect = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
        }
        
        return GeometryHelper.getInscribeRect(fromOutsideRect: outsideRect, andInsideRect: insideRect)
    }
    
    func getContentBounds() -> CGRect {
        let rect = self.bounds
        var contentRect = CGRect.zero
        
        if Orientation.isPortrait {
            contentRect.origin.x = rect.origin.x + imageSnapViewPadding
            contentRect.origin.y = rect.origin.y + imageSnapViewPadding
            
            contentRect.size.width = rect.width - 2 * imageSnapViewPadding
            contentRect.size.height = rect.height - 2 * imageSnapViewPadding - angleDashboardHeight
        } else if Orientation.isLandscape {
            contentRect.size.width = rect.width - 2 * imageSnapViewPadding - angleDashboardHeight
            contentRect.size.height = rect.height - 2 * imageSnapViewPadding
            
            contentRect.origin.y = rect.origin.y + imageSnapViewPadding
            if Orientation.isLandscapeLeft {
                contentRect.origin.x = rect.origin.x + imageSnapViewPadding
            } else {
                contentRect.origin.x = rect.origin.x + imageSnapViewPadding + angleDashboardHeight
            }
        }
        
        return contentRect
    }
    
    fileprivate func getImageLeftTopAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.imageSnapLeftTopOnImage
        }
        
        let lt = gridOverlayView.convert(CGPoint(x: 0, y: 0), to: imageContainer)
        let point = CGPoint(x: lt.x / imageContainer.bounds.width, y: lt.y / imageContainer.bounds.height)
        return point
    }
    
    fileprivate func getImageRightBottomAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.imageSnapRightBottomOnImage
        }
        
        let rb = gridOverlayView.convert(CGPoint(x: gridOverlayView.bounds.width, y: gridOverlayView.bounds.height), to: imageContainer)
        let point = CGPoint(x: rb.x / imageContainer.bounds.width, y: rb.y / imageContainer.bounds.height)
        return point
    }
    
    fileprivate func saveAnchorPoints() {
        viewModel.imageSnapLeftTopOnImage = getImageLeftTopAnchorPoint()
        viewModel.imageSnapRightBottomOnImage = getImageRightBottomAnchorPoint()
    }
    
    func adjustUIForNewImageSnap(contentRect:CGRect,
                            animation: Bool = true,
                            zoom: Bool = true,
                            completion: @escaping ()->Void) {
        
        let scaleX: CGFloat
        let scaleY: CGFloat
        
        scaleX = contentRect.width / viewModel.imageSnapBoxFrame.size.width
        scaleY = contentRect.height / viewModel.imageSnapBoxFrame.size.height
        
        let scale = min(scaleX, scaleY)
        
        let newImageSnapBounds = CGRect(x: 0, y: 0, width: viewModel.imageSnapBoxFrame.width * scale, height: viewModel.imageSnapBoxFrame.height * scale)
        
        let radians = forceFixedRatio ? viewModel.radians : viewModel.getTotalRadians()
        
        // calculate the new bounds of scroll view
        let newBoundWidth = abs(cos(radians)) * newImageSnapBounds.size.width + abs(sin(radians)) * newImageSnapBounds.size.height
        let newBoundHeight = abs(sin(radians)) * newImageSnapBounds.size.width + abs(cos(radians)) * newImageSnapBounds.size.height
        
        // calculate the zoom area of scroll view
        var scaleFrame = viewModel.imageSnapBoxFrame
        
        let refContentWidth = abs(cos(radians)) * scrollView.contentSize.width + abs(sin(radians)) * scrollView.contentSize.height
        let refContentHeight = abs(sin(radians)) * scrollView.contentSize.width + abs(cos(radians)) * scrollView.contentSize.height
        
        if scaleFrame.width >= refContentWidth {
            scaleFrame.size.width = refContentWidth
        }
        if scaleFrame.height >= refContentHeight {
            scaleFrame.size.height = refContentHeight
        }
        
        let contentOffset = scrollView.contentOffset
        let contentOffsetCenter = CGPoint(x: (contentOffset.x + scrollView.bounds.width / 2),
                                          y: (contentOffset.y + scrollView.bounds.height / 2))
        
        
        scrollView.bounds = CGRect(x: 0, y: 0, width: newBoundWidth, height: newBoundHeight)
        
        let newContentOffset = CGPoint(x: (contentOffsetCenter.x - newBoundWidth / 2),
                                       y: (contentOffsetCenter.y - newBoundHeight / 2))
        scrollView.contentOffset = newContentOffset
        
        let newImageSnapBoxFrame = GeometryHelper.getInscribeRect(fromOutsideRect: contentRect, andInsideRect: viewModel.imageSnapBoxFrame)
        
        func updateUI(by newImageSnapBoxFrame: CGRect, and scaleFrame: CGRect) {
            viewModel.imageSnapBoxFrame = newImageSnapBoxFrame
            
            if zoom {
                let zoomRect = convert(scaleFrame,
                                            to: scrollView.imageContainer)
                scrollView.zoom(to: zoomRect, animated: false)
            }
            scrollView.checkContentOffset()
            makeSureImageContainsImageSnapOverlay()
        }
        
        if animation {
            UIView.animate(withDuration: 0.25, animations: {
                updateUI(by: newImageSnapBoxFrame, and: scaleFrame)
            }) {_ in
                completion()
            }
        } else {
            updateUI(by: newImageSnapBoxFrame, and: scaleFrame)
            completion()
        }
                
        manualZoomed = true
    }
    
    func makeSureImageContainsImageSnapOverlay() {
        if !imageContainer.contains(rect: gridOverlayView.frame, fromView: self, tolerance: 0.25) {
            scrollView.zoomScaleToBound(animated: true)
        }
    }
    
    fileprivate func updatePosition(by radians: CGFloat) {
        let width = abs(cos(radians)) * gridOverlayView.frame.width + abs(sin(radians)) * gridOverlayView.frame.height
        let height = abs(sin(radians)) * gridOverlayView.frame.width + abs(cos(radians)) * gridOverlayView.frame.height
        
        scrollView.updateLayout(byNewSize: CGSize(width: width, height: height))
        
        if !manualZoomed || scrollView.shouldScale() {
            scrollView.zoomScaleToBound()
            manualZoomed = false
        } else {
            scrollView.updateMinZoomScale()
        }
        
        scrollView.checkContentOffset()
    }
    
    fileprivate func updatePositionFor90Rotation(by radians: CGFloat) {
                
        func adjustScrollViewForNormalRatio(by radians: CGFloat) -> CGFloat {
            let width = abs(cos(radians)) * gridOverlayView.frame.width + abs(sin(radians)) * gridOverlayView.frame.height
            let height = abs(sin(radians)) * gridOverlayView.frame.width + abs(cos(radians)) * gridOverlayView.frame.height

            let newSize: CGSize
            if viewModel.rotationType == .none || viewModel.rotationType == .counterclockwise180 {
                newSize = CGSize(width: width, height: height)
            } else {
                newSize = CGSize(width: height, height: width)
            }

            let scale = newSize.width / scrollView.bounds.width
            scrollView.updateLayout(byNewSize: newSize)
            return scale
        }
        
        let scale = adjustScrollViewForNormalRatio(by: radians)
                        
        let newZoomScale = scrollView.zoomScale * scale
        scrollView.minimumZoomScale = newZoomScale
        scrollView.zoomScale = newZoomScale
        
        scrollView.checkContentOffset()
    }
}

// MARK: - internal API
extension ImageSnapView {
    func imageSnap(_ image: UIImage) -> (imageSnappedImage: UIImage?, transformation: Transformation) {

        let info = getImageSnapInfo()
        
        let transformation = Transformation(
            offset: scrollView.contentOffset,
            rotation: getTotalRadians(),
            scale: scrollView.zoomScale,
            manualZoomed: manualZoomed,
            intialMaskFrame: getInitialImageSnapBoxRect(),
            maskFrame: gridOverlayView.frame,
            scrollBounds: scrollView.bounds
        )
        
        guard let imageSnappedImage = image.getImageSnappedImage(byImageSnapInfo: info) else {
            return (nil, transformation)
        }
        
        switch imageSnapShapeType {
        case .rect,
             .square,
             .circle(maskOnly: true),
             .roundedRect(_, maskOnly: true),
             .path(_, maskOnly: true),
             .diamond(maskOnly: true),
             .heart(maskOnly: true),
             .polygon(_, _, maskOnly: true):
            return (imageSnappedImage, transformation)
        case .ellipse:
            return (imageSnappedImage.ellipseMasked, transformation)
        case .circle:
            return (imageSnappedImage.ellipseMasked, transformation)
        case .roundedRect(let radiusToShortSide, maskOnly: false):
            let radius = min(imageSnappedImage.size.width, imageSnappedImage.size.height) * radiusToShortSide
            return (imageSnappedImage.roundRect(radius), transformation)
        case .path(let points, maskOnly: false):
            return (imageSnappedImage.clipPath(points), transformation)
        case .diamond(maskOnly: false):
            let points = [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)]
            return (imageSnappedImage.clipPath(points), transformation)
        case .heart(maskOnly: false):
            return (imageSnappedImage.heart, transformation)
        case .polygon(let sides, let offset, maskOnly: false):
            let points = polygonPointArray(sides: sides, x: 0.5, y: 0.5, radius: 0.5, offset: 90 + offset)
            return (imageSnappedImage.clipPath(points), transformation)
        }
    }
    
    func getImageSnapInfo() -> ImageSnapInfo {
        
        let rect = imageContainer.convert(imageContainer.bounds,
                                          to: self)
        let point = rect.center
        let zeroPoint = gridOverlayView.center
        
        let translation =  CGPoint(x: (point.x - zeroPoint.x), y: (point.y - zeroPoint.y))
                
        return ImageSnapInfo(
            translation: translation,
            rotation: getTotalRadians(),
            scale: scrollView.zoomScale,
            imageSnapSize: gridOverlayView.frame.size,
            imageViewSize: imageContainer.bounds.size
        )
        
    }
    
    func getTotalRadians() -> CGFloat {
        return forceFixedRatio ? viewModel.radians : viewModel.getTotalRadians()
    }
    
    func imageSnap() -> (imageSnappedImage: UIImage?, transformation: Transformation) {
        return imageSnap(image)
    }
        
    func handleRotate() {
        viewModel.resetImageSnapFrame(by: getInitialImageSnapBoxRect())
        
        scrollView.transform = .identity
        scrollView.resetBy(rect: viewModel.imageSnapBoxFrame)
        
        setupAngleDashboard()
        rotateScrollView()
        
        if viewModel.imageSnapRightBottomOnImage != .zero {
            var lt = CGPoint(x: viewModel.imageSnapLeftTopOnImage.x * imageContainer.bounds.width, y: viewModel.imageSnapLeftTopOnImage.y * imageContainer.bounds.height)
            var rb = CGPoint(x: viewModel.imageSnapRightBottomOnImage.x * imageContainer.bounds.width, y: viewModel.imageSnapRightBottomOnImage.y * imageContainer.bounds.height)
            
            lt = imageContainer.convert(lt, to: self)
            rb = imageContainer.convert(rb, to: self)
            
            let rect = CGRect(origin: lt, size: CGSize(width: rb.x - lt.x, height: rb.y - lt.y))
            viewModel.imageSnapBoxFrame = rect
            
            let contentRect = getContentBounds()
            
            adjustUIForNewImageSnap(contentRect: contentRect) { [weak self] in
                self?.adaptAngleDashboardToImageSnapBox()
                self?.viewModel.setBetweenOperationStatus()
            }
        }
    }
    
    func RotateBy90(rotateAngle: CGFloat, completion: @escaping ()->Void = {}) {
        viewModel.setDegree90RotatingStatus()
        let rorateDuration = 0.25
        
        if forceFixedRatio {
            viewModel.setRotatingStatus(by: CGAngle(radians: viewModel.radians))
            let angle = CGAngle(radians: rotateAngle + viewModel.radians)
            
            UIView.animate(withDuration: rorateDuration, animations: {
                self.viewModel.setRotatingStatus(by: angle)
            }) {[weak self] _ in
                guard let self = self else { return }
                self.viewModel.RotateBy90(rotateAngle: rotateAngle)
                self.viewModel.setBetweenOperationStatus()
                completion()
            }
            
            return
        }
        
        var rect = gridOverlayView.frame
        rect.size.width = gridOverlayView.frame.height
        rect.size.height = gridOverlayView.frame.width
        
        let newRect = GeometryHelper.getInscribeRect(fromOutsideRect: getContentBounds(), andInsideRect: rect)
        
        let radian = rotateAngle
        let transfrom = scrollView.transform.rotated(by: radian)
        
        UIView.animate(withDuration: rorateDuration, animations: {
            self.viewModel.imageSnapBoxFrame = newRect
            self.scrollView.transform = transfrom
            self.updatePositionFor90Rotation(by: radian + self.viewModel.radians)
        }) {[weak self] _ in
            guard let self = self else { return }
            self.scrollView.updateMinZoomScale()
            self.viewModel.RotateBy90(rotateAngle: rotateAngle)
            self.viewModel.setBetweenOperationStatus()
            completion()
        }
    }
    
    func reset() {
        scrollView.removeFromSuperview()
        gridOverlayView.removeFromSuperview()
        rotationDial?.removeFromSuperview()
        
        if forceFixedRatio {
            aspectRatioLockEnabled = true
        } else {
            aspectRatioLockEnabled = false
        }
        
        viewModel.reset(forceFixedRatio: forceFixedRatio)
        resetUIFrame()
        delegate?.imageSnapViewDidBecomeUnResettable(self)
    }
    
    func prepareForDeviceRotation() {
        viewModel.setDegree90RotatingStatus()
        saveAnchorPoints()
    }
    
    fileprivate func setRotation(byRadians radians: CGFloat) {
        scrollView.transform = CGAffineTransform(rotationAngle: radians)
        updatePosition(by: radians)
        rotationDial?.rotateDialPlate(to: CGAngle(radians: radians), animated: false)
    }
    

    func setFixedRatioImageSnapBox(zoom: Bool = true, imageSnapBox: CGRect? = nil) {
        let refImageSnapBox = imageSnapBox ?? getInitialImageSnapBoxRect()
        viewModel.setImageSnapBoxFrame(by: refImageSnapBox, and: getImageRatioH())
        
        let contentRect = getContentBounds()
        adjustUIForNewImageSnap(contentRect: contentRect, animation: false, zoom: zoom) { [weak self] in
            guard let self = self else { return }
            if self.forceFixedRatio {
                self.imageStatusChangedCheckForForceFixedRatio = true
            }
            self.viewModel.setBetweenOperationStatus()
        }
        
        adaptAngleDashboardToImageSnapBox()
        scrollView.updateMinZoomScale()
    }
    
    func getRatioType(byImageIsOriginalisHorizontal isHorizontal: Bool) -> RatioType {
        return viewModel.getRatioType(byImageIsOriginalHorizontal: isHorizontal)
    }
    
    func getImageRatioH() -> Double {
        if viewModel.rotationType == .none || viewModel.rotationType == .counterclockwise180 {
            return Double(image.ratioH())
        } else {
            return Double(1/image.ratioH())
        }
    }
    
    func transform(byTransformInfo transformation: Transformation, rotateDial: Bool = true) {
        viewModel.setRotatingStatus(by: CGAngle(radians:transformation.rotation))

        if (transformation.scrollBounds != .zero) {
            scrollView.bounds = transformation.scrollBounds
        }

        manualZoomed = transformation.manualZoomed
        scrollView.zoomScale = transformation.scale
        scrollView.contentOffset = transformation.offset
        viewModel.setBetweenOperationStatus()
        
        if (transformation.maskFrame != .zero) {
            viewModel.imageSnapBoxFrame = transformation.maskFrame
        }

        if (rotateDial) {
            rotationDial?.rotateDialPlate(by: CGAngle(radians: viewModel.radians))
            adaptAngleDashboardToImageSnapBox()
        }
    }
}

