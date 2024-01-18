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
    private(set) lazy var uiSwitch = UISwitch()

    func configureContent() {
        guard let viewModel = viewModel else {
            return
        }

        selectionStyle = .none

        title.text = viewModel.title
        title.numberOfLines = 1
        title.minimumScaleFactor = 0.8
        title.adjustsFontSizeToFitWidth = true

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
            uiSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hSpacing),
            title.trailingAnchor.constraint(equalTo: uiSwitch.leadingAnchor, constant: -hSpacing),
        ])
    }

    @objc func switchChanged(uiSwitch: UISwitch) {
        viewModel?.toggleHandler(uiSwitch.isOn)
    }
}

@available(iOS 17.0, *)
#Preview("ASCSwitchTableViewCell", traits: .defaultLayout, body: {
    let cell = ASCSwitchTableViewCell()
    let viewModel = ASCSwitchRowViewModel(title: "Sample", isActive: false, toggleHandler: { _ in })
    cell.viewModel = viewModel
    return cell
})
