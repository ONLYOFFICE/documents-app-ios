//
//  ASCSharingAddRightHoldersUserTableViewCell.swift
//  Documents
//
//  Created by Павел Чернышев on 15.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingAddRightHoldersUserTableViewCell: UITableViewCell, ASCReusedIdentifierProtocol, ASCViewModelSetter {
    
    static var reuseId: String = "UserRightHolderCell"
    
    var avatarSideSize: CGFloat = 40
    var titleStackHeigh: CGFloat = 40
    var hSpacing: CGFloat = 16
    var defaultLineLeftSpacing: CGFloat = 66
    
    private lazy var avatar: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: avatarSideSize, height: avatarSideSize))
        imageView.layer.cornerRadius = imageView.height / 2
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var title: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = label.font.withSize(15)
        return label
    }()
    
    private lazy var subtitle: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.font = label.font.withSize(13)
        return label
    }()
    
    private lazy var vStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }()
    
    var viewModel: ASCSharingAddRightHolderUserModel? {
        didSet {
            configureContent()
        }
    }
    
    func configureContent() {
        guard let viewModel = viewModel else {
            return
        }
    
        selectionStyle = .default
        selectedBackgroundView = UIView()
        separatorInset.left = defaultLineLeftSpacing
        editingAccessoryType = .none
        accessoryType = .none
        
        
        avatar.image = viewModel.image
        title.text = viewModel.name
        subtitle.text = viewModel.type

        avatar.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(avatar)
        contentView.addSubview(title)
        contentView.addSubview(subtitle)
        contentView.addSubview(vStack)
        
        vStack.addArrangedSubview(title)
        vStack.addArrangedSubview(subtitle)

        NSLayoutConstraint.activate([
        
            avatar.heightAnchor.constraint(equalToConstant: avatar.height),
            avatar.widthAnchor.constraint(equalToConstant: avatar.width),
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hSpacing),
            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            vStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: hSpacing),
            vStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hSpacing),
            vStack.heightAnchor.constraint(equalToConstant: titleStackHeigh),
            vStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
    }
}
