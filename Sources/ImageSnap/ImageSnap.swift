import UIKit

private(set) var bundle: Bundle? = {
    return ImageSnap.Config.bundle
} ()

public func imageSnapViewController(image: UIImage,
                               config: ImageSnap.Config = ImageSnap.Config(),
                               imageSnapToolbar: ImageSnapToolbarProtocol = ImageSnapToolbar(frame: CGRect.zero)) -> ImageSnapViewController {
    return ImageSnapViewController(image: image,
                              config: config,
                              mode: .normal,
                              imageSnapToolbar: imageSnapToolbar)
}

public func imageSnapCustomizableViewController(image: UIImage,
                                           config: ImageSnap.Config = ImageSnap.Config(),
                                           imageSnapToolbar: ImageSnapToolbarProtocol = ImageSnapToolbar(frame: CGRect.zero)) -> ImageSnapViewController {
    return ImageSnapViewController(image: image,
                              config: config,
                              mode: .customizable,
                              imageSnapToolbar: imageSnapToolbar)
}

public func getImageSnappedImage(byImageSnapInfo info: ImageSnapInfo, andImage image: UIImage) -> UIImage? {
    return image.getImageSnappedImage(byImageSnapInfo: info)
}

public typealias Transformation = (
    offset: CGPoint,
    rotation: CGFloat,
    scale: CGFloat,
    manualZoomed: Bool,
    intialMaskFrame: CGRect,
    maskFrame: CGRect,
    scrollBounds: CGRect
)

public typealias ImageSnapInfo = (translation: CGPoint, rotation: CGFloat, scale: CGFloat, imageSnapSize: CGSize, imageViewSize: CGSize)

public enum PresetTransformationType {
    case none
    case presetInfo(info: Transformation)
    case presetNormalizedInfo(normailizedInfo: CGRect)
}

public enum PresetFixedRatioType {
    /** When choose alwaysUsingOnePresetFixedRatio, fixed-ratio setting button does not show.
     */
    case alwaysUsingOnePresetFixedRatio(ratio: Double = 0)
    case canUseMultiplePresetFixedRatio(defaultRatio: Double = 0)
}

public enum ImageSnapVisualEffectType {
    case blurDark
    case dark
    case light
    case none
}

public enum ImageSnapShapeType {
    case rect
    
    /**
      The ratio of the imageSnap mask will always be 1:1.
     ### Notice
     It equals imageSnapShapeType = .rect
     and presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
     */
    case square

    /**
     When maskOnly is true, the imageSnapped image is kept rect
     */
    case ellipse(maskOnly: Bool = false)
    
    /**
      The ratio of the imageSnap mask will always be 1:1 and when maskOnly is true, the imageSnapped image is kept rect.
     ### Notice
     It equals imageSnapShapeType = .ellipse and presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
     */
    case circle(maskOnly: Bool = false)

    /**
     When maskOnly is true, the imageSnapped image is kept rect
     */
    case roundedRect(radiusToShortSide: CGFloat, maskOnly: Bool = false)
        
    case diamond(maskOnly: Bool = false)
    
    case heart(maskOnly: Bool = false)
    
    case polygon(sides: Int, offset: CGFloat = 0, maskOnly: Bool = false)
    
    /**
      Each point should have normailzed values whose range is 0...1
     */
    case path(points: [CGPoint], maskOnly: Bool = false)
}

public enum RatioCandidatesShowType {
    case presentRatioList
    case alwaysShowRatioList
}

public enum FixRatiosShowType {
    case adaptive
    case horizontal
    case vetical
}

public struct ImageSnapToolbarConfig {
    public var optionButtonFontSize: CGFloat = 14
    public var optionButtonFontSizeForPad: CGFloat = 20
    public var imageSnapToolbarHeightForVertialOrientation: CGFloat = 44
    public var imageSnapToolbarWidthForHorizontalOrientation: CGFloat = 80
    public var ratioCandidatesShowType: RatioCandidatesShowType = .presentRatioList
    public var fixRatiosShowType: FixRatiosShowType = .adaptive
    public var toolbarButtonOptions: ToolbarButtonOptions = .default
    public var presetRatiosButtonSelected = false
    
    var mode: ImageSnapToolbarMode = .normal
    var includeFixedRatioSettingButton = true
}

public struct Config {
    public var presetTransformationType: PresetTransformationType = .none
    public var imageSnapShapeType: ImageSnapShapeType = .rect
    public var imageSnapVisualEffectType: ImageSnapVisualEffectType = .blurDark
    public var ratioOptions: RatioOptions = .all
    public var presetFixedRatioType: PresetFixedRatioType = .canUseMultiplePresetFixedRatio()
    public var showRotationDial = true
    public var imageSnapToolbarConfig = ImageSnapToolbarConfig()
    
    var customRatios: [(width: Int, height: Int)] = []
    
    static private var bundleIdentifier: String = {
        return "com.echo.framework.ImageSnap"
    } ()
    
    static private(set) var bundle: Bundle? = {
        guard let bundle = Bundle(identifier: bundleIdentifier) else {
            return nil
        }
        
        if let url = bundle.url(forResource: "Resource", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return bundle
        }
        return nil
    } ()
    
    public init() {
    }
        
    mutating public func addCustomRatio(byHorizontalWidth width: Int, andHorizontalHeight height: Int) {
        customRatios.append((width, height))
    }

    mutating public func addCustomRatio(byVerticalWidth width: Int, andVerticalHeight height: Int) {
        customRatios.append((height, width))
    }
    
    func hasCustomRatios() -> Bool {
        return customRatios.count > 0
    }
    
    func getCustomRatioItems() -> [RatioItemType] {
        return customRatios.map {
            (String("\($0.width):\($0.height)"), Double($0.width)/Double($0.height), String("\($0.height):\($0.width)"), Double($0.height)/Double($0.width))
        }
    }
}
