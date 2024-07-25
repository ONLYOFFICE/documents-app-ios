//
//  PersonalMigrationViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.07.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

final class PersonalMigrationViewController: UIViewController {
    // MARK: - Properties

    var onClose: (() -> Void)?
    var onCreate: (() -> Void)?

    var allowClose: Bool = false {
        didSet {
            closeButton.isHidden = !allowClose
        }
    }

    // Close
    private lazy var closeButton = {
        $0.setImageForAllStates(Asset.Images.closeLarge.image)
        $0.addTarget(self, action: #selector(onCloseButton), for: .touchUpInside)
        return $0
    }(UIButton())

    // Illustration
    private lazy var illustration: UIImageView = {
        $0.contentMode = .center
        return $0
    }(UIImageView(image: Asset.Images.illustrationPersonalMigration.image))

    // Caption
    private lazy var captionLabel: UILabel = {
        $0.text = NSLocalizedString("ONLYOFFICE Personal is wrapping up", comment: "")
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.font = UIFont.systemFont(ofSize: 22).with(weight: .medium)
        return $0
    }(UILabel())

    // Description
    private lazy var descriptionLabel: UILabel = {
        $0.text = NSLocalizedString("ONLYOFFICE Personal will be discontinued on September 1st, 2024. We recommend you move to the free ONLYOFFICE DocSpace Cloud.", comment: "")
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.textStyle = .subheadline
        $0.textColor = .secondaryLabel
        return $0
    }(UILabel())

    // Create portal button
    private lazy var createPortlaButton: ASCButtonStyle = {
        $0.styleType = .action
        $0.setTitleForAllStates(NSLocalizedString("Create a free account", comment: ""))
        $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        $0.addTarget(self, action: #selector(onCreatePortlaButton), for: .touchUpInside)
        return $0
    }(ASCButtonStyle())

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        buildView()
    }

    private func buildView() {
        view.backgroundColor = .secondarySystemBackground

        for view in view.subviews {
            view.removeFromSuperview()
        }

        // Close
        view.addSubview(closeButton)
        closeButton.anchor(
            top: view.safeAreaLayoutGuide.topAnchor,
            trailing: view.safeAreaLayoutGuide.trailingAnchor,
            padding: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 20)
        )

        // Content
        let contentStackView: UIStackView = {
            $0.axis = .vertical
            $0.distribution = .fill
            $0.alignment = .center
            $0.spacing = 16
            return $0
        }(UIStackView(arrangedSubviews: [
            illustration,
            {
                $0.axis = .horizontal
                $0.alignment = .leading
                $0.distribution = .fill
                return $0
            }(UIStackView(arrangedSubviews: [
                {
                    $0.contentMode = .scaleAspectFill
                    $0.anchor(size: CGSize(width: 28, height: 28))
                    return $0
                }(UIImageView(image: Asset.Images.onlyofficeLogoSmall.image)),
                captionLabel,
            ])),
            descriptionLabel,
            UIView(),
            createPortlaButton,
        ]))

        view.addSubview(contentStackView)
        contentStackView.anchorCenterXToSuperview()
        contentStackView.anchorCenterYToSuperview(constant: 0)
        contentStackView.anchor(widthConstant: 280)
    }

    @objc
    private func onCloseButton(_ sender: UIButton) {
        onClose?()
    }

    @objc
    private func onCreatePortlaButton(_ sender: ASCButtonStyle) {
        onCreate?()
    }
}

@available(iOS 17, *)
#Preview {
    PersonalMigrationViewController()
}
