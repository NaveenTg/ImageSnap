//
//  File.swift
//  
//
//  Created by Navi on 31/05/21.
//

import UIKit

public enum ImageSnapToolbarMode {
    case normal
    case simple
}

public class ImageSnapToolbar: UIView, ImageSnapToolbarProtocol {
    public var heightForVerticalOrientationConstraint: NSLayoutConstraint?
    public var widthForHorizonOrientationConstraint: NSLayoutConstraint?
    
    public weak var imageSnapToolbarDelegate: ImageSnapToolbarDelegate?
    
    var fixedRatioSettingButton: UIButton?

    var cancelButton: UIButton?
    var resetButton: UIButton?
    var counterClockwiseRotationButton: UIButton?
    var clockwiseRotationButton: UIButton?
    var alterImageSnapper90DegreeButton: UIButton?
    var imageSnapButton: UIButton?
    
    var config: ImageSnapToolbarConfig!
    
    private var optionButtonStackView: UIStackView?
    
    private func createOptionButton(withTitle title: String?, andAction action: Selector) -> UIButton {
        let buttonColor = UIColor.white
        let buttonFontSize: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ?
            config.optionButtonFontSizeForPad :
            config.optionButtonFontSize
        
        let buttonFont = UIFont.systemFont(ofSize: buttonFontSize)
        
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.titleLabel?.font = buttonFont
        
        if let title = title {
            button.setTitle(title, for: .normal)
            button.setTitleColor(buttonColor, for: .normal)
        }
        
        button.addTarget(self, action: action, for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        
        return button
    }
    
    private func createCancelButton() {
        let cancelText = LocalizedHelper.getString("Cancel")
        
        cancelButton = createOptionButton(withTitle: cancelText, andAction: #selector(cancel))
    }
    
    private func createCounterClockwiseRotationButton() {
        counterClockwiseRotationButton = createOptionButton(withTitle: nil, andAction: #selector(counterClockwiseRotate))
        counterClockwiseRotationButton?.setImage(ToolBarButtonImageBuilder.rotateCCWImage(), for: .normal)
    }

    private func createClockwiseRotationButton() {
        clockwiseRotationButton = createOptionButton(withTitle: nil, andAction: #selector(clockwiseRotate))
        clockwiseRotationButton?.setImage(ToolBarButtonImageBuilder.rotateCWImage(), for: .normal)
    }
    
    private func createAlterImageSnapper90DegreeButton() {
        alterImageSnapper90DegreeButton = createOptionButton(withTitle: nil, andAction: #selector(alterImageSnapper90Degree))
        alterImageSnapper90DegreeButton?.setImage(ToolBarButtonImageBuilder.alterImageSnapper90DegreeImage(), for: .normal)
    }
    
    private func createResetButton(with image: UIImage? = nil) {
        if let image = image {
            resetButton = createOptionButton(withTitle: nil, andAction: #selector(reset))
            resetButton?.setImage(image, for: .normal)
        } else {
            let resetText = LocalizedHelper.getString("Reset")

            resetButton = createOptionButton(withTitle: resetText, andAction: #selector(reset))
        }
    }
    
    private func createSetRatioButton() {
        fixedRatioSettingButton = createOptionButton(withTitle: nil, andAction: #selector(setRatio))
        fixedRatioSettingButton?.setImage(ToolBarButtonImageBuilder.clampImage(), for: .normal)
    }
    
    private func createImageSnapButton() {
        let doneText = LocalizedHelper.getString("Done")
        imageSnapButton = createOptionButton(withTitle: doneText, andAction: #selector(imageSnap))
    }
    
    private func createButtonContainer() {
        optionButtonStackView = UIStackView()
        addSubview(optionButtonStackView!)
        
        optionButtonStackView?.distribution = .equalCentering
        optionButtonStackView?.isLayoutMarginsRelativeArrangement = true
    }
    
    private func setButtonContainerLayout() {
        optionButtonStackView?.translatesAutoresizingMaskIntoConstraints = false
        optionButtonStackView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionButtonStackView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        optionButtonStackView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        optionButtonStackView?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    private func addButtonsToContainer(button: UIButton?) {
        if let button = button {
            optionButtonStackView?.addArrangedSubview(button)
        }
    }
    
    private func addButtonsToContainer(buttons: [UIButton?]) {
        buttons.forEach{
            if let button = $0 {
                optionButtonStackView?.addArrangedSubview(button)
            }
        }
    }
    
    public func createToolbarUI(config: ImageSnapToolbarConfig) {
        self.config = config
        backgroundColor = .black
        
        if #available(macCatalyst 14.0, iOS 14.0, *) {
            if UIDevice.current.userInterfaceIdiom == .mac {
                backgroundColor = .white
            }
        }
        
        createButtonContainer()
        setButtonContainerLayout()
        
        if config.mode == .normal {
            createCancelButton()
            addButtonsToContainer(button: cancelButton)
        }
        
        if config.toolbarButtonOptions.contains(.counterclockwiseRotate) {
            createCounterClockwiseRotationButton()
            addButtonsToContainer(button: counterClockwiseRotationButton)
        }
        
        if config.toolbarButtonOptions.contains(.clockwiseRotate) {
            createClockwiseRotationButton()
            addButtonsToContainer(button: clockwiseRotationButton)
        }
        
        if config.toolbarButtonOptions.contains(.alterImageSnapper90Degree) {
            createAlterImageSnapper90DegreeButton()
            addButtonsToContainer(button: alterImageSnapper90DegreeButton)
        }
        
        if config.toolbarButtonOptions.contains(.reset) {
            createResetButton(with: ToolBarButtonImageBuilder.resetImage())
            addButtonsToContainer(button: resetButton)
            resetButton?.isHidden = true
        }
       
        if config.toolbarButtonOptions.contains(.ratio) && config.ratioCandidatesShowType == .presentRatioList {
            if config.includeFixedRatioSettingButton  {
                createSetRatioButton()
                addButtonsToContainer(button: fixedRatioSettingButton)
                
                if config.presetRatiosButtonSelected {
                    handleFixedRatioSetted(ratio: 0)
                    resetButton?.isHidden = false
                }
            }
        }
        
        if config.mode == .normal {
            createImageSnapButton()
            addButtonsToContainer(button: imageSnapButton)
        }
    }
    
    public func getRatioListPresentSourceView() -> UIView? {
        return fixedRatioSettingButton
    }
        
    public func respondToOrientationChange() {
        if Orientation.isPortrait {
            optionButtonStackView?.axis = .horizontal
            optionButtonStackView?.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        } else {
            optionButtonStackView?.axis = .vertical
            optionButtonStackView?.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        }
    }
    
    public func handleFixedRatioSetted(ratio: Double) {
        fixedRatioSettingButton?.tintColor = nil
    }
    
    public func handleFixedRatioUnSetted() {
        fixedRatioSettingButton?.tintColor = .white
    }
    
    public func handleImageSnapViewDidBecomeResettable() {
        resetButton?.isHidden = false
    }
    
    public func handleImageSnapViewDidBecomeUnResettable() {
        resetButton?.isHidden = true
    }
    
    public func initConstraints(heightForVerticalOrientation: CGFloat, widthForHorizonOrientation: CGFloat) {
        
    }
    
    @objc private func cancel() {
        imageSnapToolbarDelegate?.didSelectCancel()
    }
    
    @objc private func setRatio() {
        imageSnapToolbarDelegate?.didSelectSetRatio()
    }
    
    @objc private func reset(_ sender: Any) {
        imageSnapToolbarDelegate?.didSelectReset()
    }
    
    @objc private func counterClockwiseRotate(_ sender: Any) {
        imageSnapToolbarDelegate?.didSelectCounterClockwiseRotate()
    }
    
    @objc private func clockwiseRotate(_ sender: Any) {
        imageSnapToolbarDelegate?.didSelectClockwiseRotate()
    }
    
    @objc private func alterImageSnapper90Degree(_ sender: Any) {
        imageSnapToolbarDelegate?.didSelectAlterImageSnapper90Degree()
    }
    
    @objc private func imageSnap(_ sender: Any) {
        imageSnapToolbarDelegate?.didSelectImageSnap()
    }
}

