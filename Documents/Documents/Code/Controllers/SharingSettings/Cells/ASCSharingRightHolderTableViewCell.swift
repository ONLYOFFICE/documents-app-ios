//
//  ASCSharingRightHolderTableViewCell.swift
//  Documents
//
//  Created by Pavel Chernyshev on 10.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import UIKit

class ASCSharingRightHolderTableViewCell: UITableViewCell, ASCReusedIdentifierProtocol, ASCViewModelSetter {
    static var reuseId: String = "SharingRightHolderCell"

    var viewModel: ASCSharingRightHolderViewModel? {
        didSet {
            clear()
            configureContent()
        }
    }

    var avatarSideSize: CGFloat = 40
    var titleStackHeigh: CGFloat = 40
    var hSpacing: CGFloat = 16
    var defaultLineLeftSpacing: CGFloat = 60

    private lazy var avatar: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: avatarSideSize, height: avatarSideSize))
        imageView.layer.cornerRadius = imageView.height / 2
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var title: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .natural
        label.font = label.font.withSize(15)
        return label
    }()

    private lazy var subtitle: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.font = label.font.withSize(13)
        label.textAlignment = .natural
        return label
    }()

    private lazy var accessLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.textAlignment = .natural
        return label
    }()

    private lazy var vStack: UIStackView = makeVStack()

    func configureContent() {
        guard let viewModel = viewModel else {
            return
        }

        if let access = viewModel.access, !access.accessEditable {
            selectionStyle = .none
        } else {
            selectionStyle = .default
        }

        separatorInset.left = defaultLineLeftSpacing

        if let avatarUrlStr = viewModel.avatarUrl,
           !avatarUrlStr.contains("/skins/default/images/default_user_photo_size_"),
           let avatarUrl = OnlyofficeApiClient.shared.absoluteUrl(from: URL(string: avatarUrlStr))
        {
            avatar.kf.indicatorType = .activity
            avatar.kf.apiSetImage(with: avatarUrl,
                                  placeholder: Asset.Images.avatarDefault.image)
        } else if viewModel.rightHolderType == .group {
            avatar.image = Asset.Images.avatarDefaultGroup.image
        } else if viewModel.name.isValidEmail {
            avatar.image = UIImage(systemName: "at.circle.fill")
            avatar.tintColor = .secondaryLabel
        } else {
            avatar.image = Asset.Images.avatarDefault.image
        }

        title.text = viewModel.name

        if let email = viewModel.email {
            subtitle.text = email
        } else if let department = viewModel.department {
            subtitle.text = department
        }

        let access = viewModel.access
        if access != nil, !viewModel.isOwner {
            accessLabel.text = access?.entityAccess.title()
        } else if viewModel.isOwner {
            accessLabel.text = NSLocalizedString("Owner", comment: "Table cell right holder acces text")
        }

        if viewModel.access?.accessEditable ?? false {
            accessoryType = .disclosureIndicator
        } else {
            accessoryType = .none
        }

        avatar.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        accessLabel.translatesAutoresizingMaskIntoConstraints = false
        vStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatar)
        contentView.addSubview(accessLabel)
        contentView.addSubview(title)
        contentView.addSubview(subtitle)
        contentView.addSubview(vStack)

        vStack.addArrangedSubview(title)
        vStack.addArrangedSubview(subtitle)

        let isAccessEditable = viewModel.access?.accessEditable ?? false

        NSLayoutConstraint.activate([
            accessLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: isAccessEditable ? -10 : -18),
            accessLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            avatar.heightAnchor.constraint(equalToConstant: avatar.height),
            avatar.widthAnchor.constraint(equalToConstant: avatar.width),
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hSpacing),
            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            vStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: hSpacing),
            vStack.trailingAnchor.constraint(equalTo: accessLabel.leadingAnchor, constant: -hSpacing),
            vStack.heightAnchor.constraint(equalToConstant: titleStackHeigh),
            vStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    func clear() {
        avatar.removeFromSuperview()
        accessLabel.removeFromSuperview()
        title.removeFromSuperview()
        subtitle.removeFromSuperview()
        vStack.removeFromSuperview()

        avatar.image = nil
        title.text = nil
        subtitle.text = nil
        accessLabel.text = nil
        vStack = makeVStack()
        selectionStyle = .default
    }

    func makeVStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }
}
