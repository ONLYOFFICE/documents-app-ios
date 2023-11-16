//
//  ASCFolderLogoAvatarView.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 15.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

class ASCFolderLogoAvatarView: UIImageView {
    // MARK: - Properties

    var titleInitials: String? {
        didSet {
            setupInitialsLabel()
            updateAppearance()
        }
    }

    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17).bold()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle Methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInitialsLabel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInitialsLabel()
    }

    private func setupInitialsLabel() {
        addSubview(initialsLabel)
        initialsLabel.text = titleInitials

        NSLayoutConstraint.activate([
            initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    private func updateAppearance() {
        if traitCollection.userInterfaceStyle == .dark {
            initialsLabel.textColor = backgroundColor
            backgroundColor = backgroundColor?.withAlphaComponent(0.2)
        } else {
            initialsLabel.textColor = .white
            backgroundColor = backgroundColor?.withAlphaComponent(1.0)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
}
