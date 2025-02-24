//
//  TopBannerView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 13.01.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import UIKit

struct TopBannerViewModel {
    var icon: UIImage?
    var text: String

    static func lifetime(formattedString: String) -> TopBannerViewModel {
        .init(
            icon: Asset.Images.fire.image,
            text: formattedString
        )
    }

    static var trash: TopBannerViewModel {
        .init(text: NSLocalizedString("Items in Trash are automatically deleted after 30 days", comment: ""))
    }
}

final class TopBannerView: UICollectionReusableView {
    static let identifier: String = "TopBannerView"
    static let bannerHeight: CGFloat = 42

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [iconImageView, titleLabel])
        stackView.axis = .horizontal
        stackView.spacing = .horizontalSpace
        stackView.alignment = .center
        stackView.backgroundColor = .tertiarySystemFill
        stackView.layerCornerRadius = .cornerRadius
        stackView.clipsToBounds = true
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: .horizontalPadding, bottom: 0, right: .horizontalPadding)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
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
        addSubview(stackView)
        setupStackViewConstraint()
    }

    private func setupStackViewConstraint() {
        stackView.anchor(
            top: topAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            padding: UIEdgeInsets(top: .zero, left: .horizontalPadding, bottom: .zero, right: .horizontalPadding)
        )
    }

    // MARK: - Configuration

    func configure(viewModel: TopBannerViewModel) {
        iconImageView.isHidden = viewModel.icon == nil
        iconImageView.image = viewModel.icon
        titleLabel.text = viewModel.text
    }
}

private extension CGFloat {
    static let cornerRadius: CGFloat = 10
    static let horizontalPadding: CGFloat = 16
    static let imageSize: CGFloat = 18
    static let contentHeight: CGFloat = 42
    static let horizontalSpace: CGFloat = 12
}
