//
//  ASCCopyLinkTableViewCell.swift
//  Documents
//
//  Created by Pavel Chernyshev on 11.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCCopyLinkTableViewCell: UITableViewCell, ASCReusedIdentifierProtocol {
    static var reuseId: String = "CopyLink"

    var link: String? {
        didSet {
            configureContent()
        }
    }

    var hSpacing: CGFloat = 16
    private lazy var title = UILabel()

    private lazy var copyImageView: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            imageView.image = UIImage(systemName: "doc.on.doc")
        } else {
            imageView.image = Asset.Images.barCopy.image // MARK: - todo replace the image
        }

        imageView.tintColor = .systemGray
        return imageView
    }()

    func configureContent() {
        guard let link = link else {
            return
        }

        selectionStyle = .none

        title.text = link
        title.textColor = .systemGray

        title.translatesAutoresizingMaskIntoConstraints = false
        copyImageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(title)
        contentView.addSubview(copyImageView)

        title.anchorCenterYToSuperview()
        copyImageView.anchorCenterYToSuperview()

        NSLayoutConstraint.activate([
            copyImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hSpacing),
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hSpacing),
            title.trailingAnchor.constraint(equalTo: copyImageView.trailingAnchor, constant: -hSpacing),
        ])
    }
}
