//
//  ASCAccessRowTableViewCell.swift
//  Documents
//
//  Created by Павел Чернышев on 11.06.2021.
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
    
    var hSpacing: CGFloat = 16
    private lazy var title = UILabel()
    
    private lazy var access: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        return label
    }()
    
    func configureContent() {
        guard let viewModel = viewModel else {
            return
        }
        
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        
        title.text = viewModel.title
        access.text = viewModel.access.title()
        
        title.translatesAutoresizingMaskIntoConstraints = false
        access.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(title)
        contentView.addSubview(access)
        
        title.anchorCenterYToSuperview()
        access.anchorCenterYToSuperview()
        
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hSpacing),
            title.trailingAnchor.constraint(equalTo: title.trailingAnchor, constant: -hSpacing),
            
            access.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        ])

    }
}
