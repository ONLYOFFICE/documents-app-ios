//
//  ASCSwitchTableViewCell.swift
//  Documents
//
//  Created by Pavel Chernyshev on 11.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSwitchTableViewCell: UITableViewCell, ASCReusedIdentifierProtocol {
    
    static var reuseId: String = "SwitchTableViewCell"
    
    var viewModel: ASCSwitchRowViewModel? {
        didSet {
            configureContent()
        }
    }
    
    private var hSpacing: CGFloat = 16
    private lazy var title = UILabel()
    private lazy var uiSwitch = UISwitch()
    
    func configureContent() {
        guard let viewModel = viewModel else {
            return
        }
        
        selectionStyle = .none
        
        title.text = viewModel.title
        uiSwitch.isOn = viewModel.isActive
        uiSwitch.onTintColor = Asset.Colors.brend.color
        uiSwitch.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
        
        title.translatesAutoresizingMaskIntoConstraints = false
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(title)
        contentView.addSubview(uiSwitch)
        
        title.anchorCenterYToSuperview()
        uiSwitch.anchorCenterYToSuperview()
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hSpacing),
            
            uiSwitch.leadingAnchor.constraint(equalTo: title.trailingAnchor, constant: hSpacing),
            uiSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hSpacing)
        ])

    }

    @objc func switchChanged(uiSwitch: UISwitch) {
        viewModel?.toggleHandler(uiSwitch.isOn)
    }
}
