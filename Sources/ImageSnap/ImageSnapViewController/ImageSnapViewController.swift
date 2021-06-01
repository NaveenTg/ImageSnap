//
//  ImageSnapViewController.swift
//  
//
//  Created by Navi on 31/05/21.
//

import UIKit

public protocol ImageSnapViewControllerDelegate: AnyObject {
    func imageSnapViewControllerDidImageSnap(_ imageSnapViewController: ImageSnapViewController,
                                   imageSnapped: UIImage, transformation: Transformation)
    func imageSnapViewControllerDidFailToImageSnap(_ imageSnapViewController: ImageSnapViewController, original: UIImage)
    func imageSnapViewControllerDidCancel(_ imageSnapViewController: ImageSnapViewController, original: UIImage)
    
    func imageSnapViewControllerDidBeginResize(_ imageSnapViewController: ImageSnapViewController)
    func imageSnapViewControllerDidEndResize(_ imageSnapViewController: ImageSnapViewController, original: UIImage, imageSnapInfo: ImageSnapInfo)
}

public extension ImageSnapViewControllerDelegate where Self: UIViewController {
    func imageSnapViewControllerDidFailToImageSnap(_ imageSnapViewController: ImageSnapViewController, original: UIImage) {}
    func imageSnapViewControllerDidBeginResize(_ imageSnapViewController: ImageSnapViewController) {}
    func imageSnapViewControllerDidEndResize(_ imageSnapViewController: ImageSnapViewController, original: UIImage, imageSnapInfo: ImageSnapInfo) {}
}

public enum ImageSnapViewControllerMode {
    case normal
    case customizable
}

public class ImageSnapViewController: UIViewController {
    /// When a ImageSnapViewController is used in a storyboard,
    /// passing an image to it is needed after the ImageSnapViewController is created.
    public var image: UIImage! {
        didSet {
            imageSnapView.image = image
        }
    }
    
    public weak var delegate: ImageSnapViewControllerDelegate?
    public var mode: ImageSnapViewControllerMode = .normal
    public var config = ImageSnap.Config()
    
    private var orientation: UIInterfaceOrientation = .unknown
    private lazy var imageSnapView = ImageSnapView(image: image, viewModel: ImageSnapViewModel())
    private var imageSnapToolbar: ImageSnapToolbarProtocol
    private var ratioPresenter: RatioPresenter?
    private var ratioSelector: RatioSelector?
    private var stackView: UIStackView?
    private var imageSnapStackView: UIStackView!
    private var initialLayout = false
    private var disableRotation = false
    
    deinit {
        print("ImageSnapViewController deinit.")
    }
    
    init(image: UIImage,
         config: ImageSnap.Config = ImageSnap.Config(),
         mode: ImageSnapViewControllerMode = .normal,
         imageSnapToolbar: ImageSnapToolbarProtocol = ImageSnapToolbar(frame: CGRect.zero)) {
        self.image = image
        
        self.config = config
        
        switch config.imageSnapShapeType {
        case .circle, .square:
            self.config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
        default:
            ()
        }
        
        self.mode = mode
        self.imageSnapToolbar = imageSnapToolbar
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.imageSnapToolbar = ImageSnapToolbar(frame: CGRect.zero)
        super.init(coder: aDecoder)
    }
    
    fileprivate func createRatioSelector() {
        let fixedRatioManager = getFixedRatioManager()
        self.ratioSelector = RatioSelector(type: fixedRatioManager.type, originalRatioH: fixedRatioManager.originalRatioH, ratios: fixedRatioManager.ratios)
        self.ratioSelector?.didGetRatio = { [weak self] ratio in
            self?.setFixedRatio(ratio)
        }
    }
    
    fileprivate func createImageSnapToolbar() {
        imageSnapToolbar.imageSnapToolbarDelegate = self
        
        switch(config.presetFixedRatioType) {
            case .alwaysUsingOnePresetFixedRatio(let ratio):
                config.imageSnapToolbarConfig.includeFixedRatioSettingButton = false
                                
                if case .none = config.presetTransformationType  {
                    setFixedRatio(ratio)
                }
                
            case .canUseMultiplePresetFixedRatio(let defaultRatio):
                if (defaultRatio > 0) {
                    setFixedRatio(defaultRatio)
                    imageSnapView.aspectRatioLockEnabled = true
                    config.imageSnapToolbarConfig.presetRatiosButtonSelected = true
                }
                
                config.imageSnapToolbarConfig.includeFixedRatioSettingButton = true
        }
                
        if mode == .normal {
            config.imageSnapToolbarConfig.mode = .normal
        } else {
            config.imageSnapToolbarConfig.mode = .simple
        }
        
        imageSnapToolbar.createToolbarUI(config: config.imageSnapToolbarConfig)
                
        imageSnapToolbar.initConstraints(heightForVerticalOrientation: config.imageSnapToolbarConfig.imageSnapToolbarHeightForVertialOrientation, widthForHorizonOrientation: config.imageSnapToolbarConfig.imageSnapToolbarWidthForHorizontalOrientation)
    }
    
    private func getRatioType() -> RatioType {
        switch config.imageSnapToolbarConfig.fixRatiosShowType {
        case .adaptive:
            return imageSnapView.getRatioType(byImageIsOriginalisHorizontal: imageSnapView.image.isHorizontal())
        case .horizontal:
            return .horizontal
        case .vetical:
            return .vertical
        }
    }
    
    fileprivate func getFixedRatioManager() -> FixedRatioManager {
        let type: RatioType = getRatioType()
        
        let ratio = imageSnapView.getImageRatioH()
        
        return FixedRatioManager(type: type,
                                 originalRatioH: ratio,
                                 ratioOptions: config.ratioOptions,
                                 customRatios: config.getCustomRatioItems())
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        createImageSnapView()
        createImageSnapToolbar()
        if config.imageSnapToolbarConfig.ratioCandidatesShowType == .alwaysShowRatioList && config.imageSnapToolbarConfig.includeFixedRatioSettingButton {
            createRatioSelector()
        }
        initLayout()
        updateLayout()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initialLayout == false {
            initialLayout = true
            view.layoutIfNeeded()
            imageSnapView.adaptForImageSnapBox()
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.top, .bottom]
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        imageSnapView.prepareForDeviceRotation()
        rotated()
    }
    
    @objc func rotated() {
        let currentOrientation = Orientation.orientation
        
        guard currentOrientation != .unknown else { return }
        guard currentOrientation != orientation else { return }
        
        orientation = currentOrientation
        
        if UIDevice.current.userInterfaceIdiom == .phone
            && currentOrientation == .portraitUpsideDown {
            return
        }
        
        updateLayout()
        view.layoutIfNeeded()
        
        // When it is embedded in a container, the timing of viewDidLayoutSubviews
        // is different with the normal mode.
        // So delay the execution to make sure handleRotate runs after the final
        // viewDidLayoutSubviews
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.imageSnapView.handleRotate()
        }
    }
    
    private func setFixedRatio(_ ratio: Double, zoom: Bool = true) {
        imageSnapToolbar.handleFixedRatioSetted(ratio: ratio)
        imageSnapView.aspectRatioLockEnabled = true
        
        if (imageSnapView.viewModel.aspectRatio != CGFloat(ratio)) {
            imageSnapView.viewModel.aspectRatio = CGFloat(ratio)
            
            if case .alwaysUsingOnePresetFixedRatio = config.presetFixedRatioType {
                self.imageSnapView.setFixedRatioImageSnapBox(zoom: zoom)
            } else {
                UIView.animate(withDuration: 0.5) {
                    self.imageSnapView.setFixedRatioImageSnapBox(zoom: zoom)
                }
            }
            
        }
    }
    
    private func createImageSnapView() {
        if !config.showRotationDial {
            imageSnapView.angleDashboardHeight = 0
        }
        imageSnapView.delegate = self
        imageSnapView.clipsToBounds = true
        imageSnapView.imageSnapShapeType = config.imageSnapShapeType
        imageSnapView.imageSnapVisualEffectType = config.imageSnapVisualEffectType
        
        if case .alwaysUsingOnePresetFixedRatio = config.presetFixedRatioType {
            imageSnapView.forceFixedRatio = true
        } else {
            imageSnapView.forceFixedRatio = false
        }
    }
    
    private func processPresetTransformation(completion: (Transformation)->Void) {
        if case .presetInfo(let transformInfo) = config.presetTransformationType {
            var newTransform = getTransformInfo(byTransformInfo: transformInfo)
            
            // The first transform is just for retrieving the final imageSnapBoxFrame
            imageSnapView.transform(byTransformInfo: newTransform, rotateDial: false)
            
            // The second transform is for adjusting the scale of transformInfo
            let adjustScale = (imageSnapView.viewModel.imageSnapBoxFrame.width / imageSnapView.viewModel.imageSnapOrignFrame.width) / (transformInfo.maskFrame.width / transformInfo.intialMaskFrame.width)
            newTransform.scale *= adjustScale
            imageSnapView.transform(byTransformInfo: newTransform)
            completion(transformInfo)
        } else if case .presetNormalizedInfo(let normailizedInfo) = config.presetTransformationType {
            let transformInfo = getTransformInfo(byNormalizedInfo: normailizedInfo);
            imageSnapView.transform(byTransformInfo: transformInfo)
            imageSnapView.scrollView.frame = transformInfo.maskFrame
            completion(transformInfo)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        processPresetTransformation() { [weak self] transform in
            guard let self = self else { return }
            if case .alwaysUsingOnePresetFixedRatio(let ratio) = self.config.presetFixedRatioType {
                self.imageSnapView.aspectRatioLockEnabled = true
                self.imageSnapToolbar.handleFixedRatioSetted(ratio: ratio)
                
                if ratio == 0 {
                    self.imageSnapView.viewModel.aspectRatio = transform.maskFrame.width / transform.maskFrame.height
                } else {
                    self.imageSnapView.viewModel.aspectRatio = CGFloat(ratio)
                    self.imageSnapView.setFixedRatioImageSnapBox(zoom: false, imageSnapBox: imageSnapView.viewModel.imageSnapBoxFrame)
                }
            }
        }
    }
    
    private func getTransformInfo(byTransformInfo transformInfo: Transformation) -> Transformation {
        let imageSnapFrame = imageSnapView.viewModel.imageSnapOrignFrame
        let contentBound = imageSnapView.getContentBounds()
        
        let adjustScale: CGFloat
        var maskFrameWidth: CGFloat
        var maskFrameHeight: CGFloat
        
        if ( transformInfo.maskFrame.height / transformInfo.maskFrame.width >= contentBound.height / contentBound.width ) {
            maskFrameHeight = contentBound.height
            maskFrameWidth = transformInfo.maskFrame.width / transformInfo.maskFrame.height * maskFrameHeight
            adjustScale = maskFrameHeight / transformInfo.maskFrame.height
        } else {
            maskFrameWidth = contentBound.width
            maskFrameHeight = transformInfo.maskFrame.height / transformInfo.maskFrame.width * maskFrameWidth
            adjustScale = maskFrameWidth / transformInfo.maskFrame.width
        }
        
        var newTransform = transformInfo
        
        newTransform.offset = CGPoint(x:transformInfo.offset.x * adjustScale,
                                      y:transformInfo.offset.y * adjustScale)
        
        newTransform.maskFrame = CGRect(x: imageSnapFrame.origin.x + (imageSnapFrame.width - maskFrameWidth) / 2,
                                        y: imageSnapFrame.origin.y + (imageSnapFrame.height - maskFrameHeight) / 2,
                                        width: maskFrameWidth,
                                        height: maskFrameHeight)
        newTransform.scrollBounds = CGRect(x: transformInfo.scrollBounds.origin.x * adjustScale,
                                           y: transformInfo.scrollBounds.origin.y * adjustScale,
                                           width: transformInfo.scrollBounds.width * adjustScale,
                                           height: transformInfo.scrollBounds.height * adjustScale)
        
        return newTransform
    }
    
    private func getTransformInfo(byNormalizedInfo normailizedInfo: CGRect) -> Transformation {
        let imageSnapFrame = imageSnapView.viewModel.imageSnapBoxFrame
        
        let scale: CGFloat = min(1/normailizedInfo.width, 1/normailizedInfo.height)
        
        var offset = imageSnapFrame.origin
        offset.x = imageSnapFrame.width * normailizedInfo.origin.x * scale
        offset.y = imageSnapFrame.height * normailizedInfo.origin.y * scale
        
        var maskFrame = imageSnapFrame
        
        if (normailizedInfo.width > normailizedInfo.height) {
            let adjustScale = 1 / normailizedInfo.width
            maskFrame.size.height = normailizedInfo.height * imageSnapFrame.height * adjustScale
            maskFrame.origin.y += (imageSnapFrame.height - maskFrame.height) / 2
        } else if (normailizedInfo.width < normailizedInfo.height) {
            let adjustScale = 1 / normailizedInfo.height
            maskFrame.size.width = normailizedInfo.width * imageSnapFrame.width * adjustScale
            maskFrame.origin.x += (imageSnapFrame.width - maskFrame.width) / 2
        }
        
        let manualZoomed = (scale != 1.0)
        let transformantion = Transformation(offset: offset,
                                             rotation: 0,
                                             scale: scale,
                                             manualZoomed: manualZoomed,
                                             intialMaskFrame: .zero,
                                             maskFrame: maskFrame,
                                             scrollBounds: .zero)
        return transformantion
    }
    
    private func handleCancel() {
        self.delegate?.imageSnapViewControllerDidCancel(self, original: self.image)
    }
    
    private func resetRatioButton() {
        imageSnapView.aspectRatioLockEnabled = false
        imageSnapToolbar.handleFixedRatioUnSetted()
    }
    
    @objc private func handleSetRatio() {
        if imageSnapView.aspectRatioLockEnabled {
            resetRatioButton()
            return
        }
        
        guard let presentSourceView = imageSnapToolbar.getRatioListPresentSourceView() else {
            return
        }
        
        let fixedRatioManager = getFixedRatioManager()
        
        guard fixedRatioManager.ratios.count > 0 else { return }
        
        if fixedRatioManager.ratios.count == 1 {
            let ratioItem = fixedRatioManager.ratios[0]
            let ratioValue = (fixedRatioManager.type == .horizontal) ? ratioItem.ratioH : ratioItem.ratioV
            setFixedRatio(ratioValue)
            return
        }
        
        ratioPresenter = RatioPresenter(type: fixedRatioManager.type,
                                        originalRatioH: fixedRatioManager.originalRatioH,
                                        ratios: fixedRatioManager.ratios,
                                        fixRatiosShowType: config.imageSnapToolbarConfig.fixRatiosShowType)
        ratioPresenter?.didGetRatio = {[weak self] ratio in
            self?.setFixedRatio(ratio, zoom: false)
        }
        ratioPresenter?.present(by: self, in: presentSourceView)
    }
    
    private func handleReset() {
        resetRatioButton()
        imageSnapView.reset()
        ratioSelector?.reset()
        ratioSelector?.update(fixedRatioManager: getFixedRatioManager())
    }
    
    private func handleRotate(rotateAngle: CGFloat) {
        if !disableRotation {
            disableRotation = true
            imageSnapView.RotateBy90(rotateAngle: rotateAngle) { [weak self] in
                self?.disableRotation = false
                self?.ratioSelector?.update(fixedRatioManager: self?.getFixedRatioManager())
            }
        }
        
    }
    
    private func handleAlterImageSnapper90Degree() {
        let ratio = Double(imageSnapView.gridOverlayView.frame.height / imageSnapView.gridOverlayView.frame.width)
        
        imageSnapView.viewModel.aspectRatio = CGFloat(ratio)
        
        UIView.animate(withDuration: 0.5) {
            self.imageSnapView.setFixedRatioImageSnapBox()
        }
    }
    
    private func handleImageSnap() {
        let imageSnapResult = imageSnapView.imageSnap()
        guard let image = imageSnapResult.imageSnappedImage else {
            delegate?.imageSnapViewControllerDidFailToImageSnap(self, original: imageSnapView.image)
            return
        }
        
        self.delegate?.imageSnapViewControllerDidImageSnap(self, imageSnapped: image, transformation: imageSnapResult.transformation)
    }
}

// Auto layout
extension ImageSnapViewController {
    fileprivate func initLayout() {
        imageSnapStackView = UIStackView()
        imageSnapStackView.axis = .vertical
        imageSnapStackView.addArrangedSubview(imageSnapView)
        
        if let ratioSelector = ratioSelector {
            imageSnapStackView.addArrangedSubview(ratioSelector)
        }
        
        stackView = UIStackView()
        view.addSubview(stackView!)
        
        imageSnapStackView?.translatesAutoresizingMaskIntoConstraints = false
        stackView?.translatesAutoresizingMaskIntoConstraints = false
        imageSnapToolbar.translatesAutoresizingMaskIntoConstraints = false
        imageSnapView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        stackView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        stackView?.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        stackView?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    }
    
    fileprivate func setStackViewAxis() {
        if Orientation.isPortrait {
            stackView?.axis = .vertical
        } else if Orientation.isLandscape {
            stackView?.axis = .horizontal
        }
    }
    
    fileprivate func changeStackViewOrder() {
        stackView?.removeArrangedSubview(imageSnapStackView)
        stackView?.removeArrangedSubview(imageSnapToolbar)
        
        if Orientation.isPortrait || Orientation.isLandscapeRight {
            stackView?.addArrangedSubview(imageSnapStackView)
            stackView?.addArrangedSubview(imageSnapToolbar)
        } else if Orientation.isLandscapeLeft {
            stackView?.addArrangedSubview(imageSnapToolbar)
            stackView?.addArrangedSubview(imageSnapStackView)
        }
    }
    
    fileprivate func updateLayout() {
        setStackViewAxis()
        imageSnapToolbar.respondToOrientationChange()
        changeStackViewOrder()
    }
}

extension ImageSnapViewController: ImageSnapViewDelegate {
    
    func imageSnapViewDidBecomeResettable(_ imageSnapView: ImageSnapView) {
        imageSnapToolbar.handleImageSnapViewDidBecomeResettable()
    }
    
    func imageSnapViewDidBecomeUnResettable(_ imageSnapView: ImageSnapView) {
        imageSnapToolbar.handleImageSnapViewDidBecomeUnResettable()
    }
    
    func imageSnapViewDidBeginResize(_ imageSnapView: ImageSnapView) {
        delegate?.imageSnapViewControllerDidBeginResize(self)
    }
    
    func imageSnapViewDidEndResize(_ imageSnapView: ImageSnapView) {
        delegate?.imageSnapViewControllerDidEndResize(self, original: imageSnapView.image, imageSnapInfo: imageSnapView.getImageSnapInfo())
    }
}

extension ImageSnapViewController: ImageSnapToolbarDelegate {
    public func didSelectCancel() {
        handleCancel()
    }
    
    public func didSelectImageSnap() {
        handleImageSnap()
    }
    
    public func didSelectCounterClockwiseRotate() {
        handleRotate(rotateAngle: -CGFloat.pi / 2)
    }
    
    public func didSelectClockwiseRotate() {
        handleRotate(rotateAngle: CGFloat.pi / 2)
    }
    
    public func didSelectReset() {
        handleReset()
    }
    
    public func didSelectSetRatio() {
        handleSetRatio()
    }
    
    public func didSelectRatio(ratio: Double) {
        setFixedRatio(ratio)
    }
    
    public func didSelectAlterImageSnapper90Degree() {
        handleAlterImageSnapper90Degree()
    }
}

// API
extension ImageSnapViewController {
    public func imageSnap() {
        let imageSnapResult = imageSnapView.imageSnap()
        guard let image = imageSnapResult.imageSnappedImage else {
            delegate?.imageSnapViewControllerDidFailToImageSnap(self, original: imageSnapView.image)
            return
        }
        
        delegate?.imageSnapViewControllerDidImageSnap(self, imageSnapped: image, transformation: imageSnapResult.transformation)
    }
    
    public func process(_ image: UIImage) -> UIImage? {
        return imageSnapView.imageSnap(image).imageSnappedImage
    }
}

