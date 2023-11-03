//
//  ASCAccessRowTableViewCell.swift
//  Documents
//
//  Created by Pavel Chernyshev on 11.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCAccessRowTableViewCell: UITableViewCell, ASCReusedIdentifierProtocol {
    static var reuseId: String = "AccessRow"

    var viewModel: ASCAccessRowViewModel? {
        didSet {
            configureContent()
        }
    }

    private var hSpacing: CGFloat = 16
    private lazy var title = UILabel()

    private lazy var access = UIImageView()

    func configureContent() {
        guard let viewModel = viewModel else {
            return
        }

        accessoryType = .disclosureIndicator

        title.text = viewModel.title
        access.image = viewModel.access.image()

        if #available(iOS 13.0, *) {
            access.image = access.image?.withTintColor(.lightGray)
        }

        contentView.addSubview(title)
        contentView.addSubview(access)
        
        title.translatesAutoresizingMaskIntoConstraints = false
        access.translatesAutoresizingMaskIntoConstraints = false

        title.anchorCenterYToSuperview()
        access.anchorCenterYToSuperview()
        
        let titleLeft = title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hSpacing)
        let titleRight = title.trailingAnchor.constraint(equalTo: access.leadingAnchor)

        let accessRight = access.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5)
        
        NSLayoutConstraint.activate([titleLeft, titleRight, accessRight])
    }
}
