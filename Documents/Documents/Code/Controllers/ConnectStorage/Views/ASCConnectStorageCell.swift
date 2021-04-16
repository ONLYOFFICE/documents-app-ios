//
//  ASCConnectStorageCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 02/07/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCConnectStorageCell: UITableViewCell {
    static let identifier = String(describing: ASCConnectStorageCell.self)


    // MARK: - Properties

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!

    var type: ASCFolderProviderType? {
        didSet {
            updateInfo()
        }
    }
    var clientId: String?
    var redirectUrl: String?

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    private func updateInfo() {
        guard let type = type else { return }

        captionLabel?.text = ""

        switch type {
        case .boxNet:
            logoImageView?.image = Asset.Images.logoBoxnetLarge.image
        case .dropBox:
            logoImageView?.image = Asset.Images.logoDropboxLarge.image
        case .google,
             .googleDrive:
            logoImageView?.image = Asset.Images.logoGoogledriveLarge.image
        case .sharePoint:
            logoImageView?.image = Asset.Images.logoOnedriveproLarge.image
        case .skyDrive,
             .oneDrive:
            logoImageView?.image = Asset.Images.logoOnedriveLarge.image
        case .webDav:
            logoImageView?.image = nil
            captionLabel?.text = NSLocalizedString("Other", comment: "")
        case .yandex:
            if Locale.preferredLanguages.first?.lowercased().contains("ru") ?? false {
                logoImageView?.image = Asset.Images.logoYandexdiskRuLarge.image
            } else {
                logoImageView?.image = Asset.Images.logoYandexdiskLarge.image
            }
        case .nextCloud:
            logoImageView?.image = Asset.Images.logoNextcloudLarge.image
        case .ownCloud:
            logoImageView?.image = Asset.Images.logoOwncloudLarge.image
        case .iCloud:
            logoImageView?.image = UIImage(named: "logo-icloud-large") // TODO: check!
        }
    }
    
}
