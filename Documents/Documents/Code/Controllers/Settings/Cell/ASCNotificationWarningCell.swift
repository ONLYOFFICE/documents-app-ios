//
//  ASCNotificationWarningCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 25.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCNotificationWarningCellViewModel {
    var action: ASCNotificationWarningCell.ActionClousure?

    convenience init(action: ASCNotificationWarningCell.ActionClousure?) {
        self.init()
        self.action = action
    }
}

class ASCNotificationWarningCell: UITableViewCell {
    typealias ActionClousure = () -> Void

    // MARK: - Properties

    @IBOutlet var warningImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var settingsButton: ASCButtonStyle!

    var viewModel: ASCNotificationWarningCellViewModel? {
        didSet {
            action = viewModel?.action
        }
    }

    private var action: ActionClousure?

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel?.text = NSLocalizedString("Push notifications disabled", comment: "")
        subtitleLabel?.text = NSLocalizedString("To receive push notifications from the ONLYOFFICE application, you need to allow receiving notifications for this application in the iOS settings", comment: "")
        settingsButton?.setTitleForAllStates(NSLocalizedString("Turn ON in Settings", comment: ""))
        settingsButton?.styleType = .default

        if #available(iOS 13.0, *) {
            warningImageView?.image = UIImage(systemName: "info.circle.fill")?
                .withTintColor(.systemPink, renderingMode: .alwaysOriginal)
        } else {
            warningImageView?.backgroundColor = .red
            warningImageView?.layerCornerRadius = 8
        }
    }

    @IBAction func onButtonTap(_ sender: Any) {
        action?()
    }
}
