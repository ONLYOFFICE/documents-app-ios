//
//  TopBannerView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 13.01.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import UIKit

final class TopBannerView: UICollectionReusableView {
    static let identifier: String = "TopBannerView"
    static let bannerHeight: CGFloat = 42

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .tertiarySystemFill
        view.layerCornerRadius = .cornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)

        setupContainerViewConstraint()
        setupIconImageViewConstraint()
        setupTitleLabelConstraint()
    }

    private func setupContainerViewConstraint() {
        containerView.anchor(
            top: topAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            padding: UIEdgeInsets(top: .zero, left: .horizontalPadding, bottom: .zero, right: .horizontalPadding)
        )
    }

    private func setupIconImageViewConstraint() {
        iconImageView.anchor(
            leading: containerView.leadingAnchor,
            padding: UIEdgeInsets(top: .zero, left: .iconImageViewLeadingConstant, bottom: .zero, right: .zero),
            size: CGSize(width: .imageSize, height: .imageSize)
        )

        iconImageView.anchorCenterYToSuperview()
    }

    private func setupTitleLabelConstraint() {
        titleLabel.anchor(
            leading: iconImageView.trailingAnchor,
            trailing: containerView.trailingAnchor,
            padding: UIEdgeInsets(top: .zero, left: .titleLabelLeadingConstant, bottom: .zero, right: .zero)
        )

        titleLabel.anchorCenterYToSuperview()
    }

    // MARK: - Configuration

    func configure(icon: UIImage?, text: String) {
        iconImageView.image = icon
        titleLabel.text = text
    }
}

private extension CGFloat {
    static let cornerRadius: CGFloat = 10
    static let horizontalPadding: CGFloat = 16
    static let imageSize: CGFloat = 18
    static let contentHeight: CGFloat = 42
    static let iconImageViewLeadingConstant: CGFloat = 12
    static let titleLabelLeadingConstant: CGFloat = 12
}
