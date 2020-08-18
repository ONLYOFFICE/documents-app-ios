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
            logoImageView?.image = UIImage(named: "logo-boxnet-large")
        case .dropBox:
            logoImageView?.image = UIImage(named: "logo-dropbox-large")
        case .google,
             .googleDrive:
            logoImageView?.image = UIImage(named: "logo-googledrive-large")
        case .sharePoint:
            logoImageView?.image = UIImage(named: "logo-onedrivepro-large")
        case .skyDrive,
             .oneDrive:
            logoImageView?.image = UIImage(named: "logo-onedrive-large")
        case .webDav:
            logoImageView?.image = nil
            captionLabel?.text = NSLocalizedString("Other", comment: "")
        case .yandex:
            if Locale.preferredLanguages.first?.lowercased().contains("ru") ?? false {
                logoImageView?.image = UIImage(named: "logo-yandexdisk-ru-large")
            } else {
                logoImageView?.image = UIImage(named: "logo-yandexdisk-large")
            }
        case .nextCloud:
            logoImageView?.image = UIImage(named: "logo-nextcloud-large")
        case .ownCloud:
            logoImageView?.image = UIImage(named: "logo-owncloud-large")
        }
    }
    
}
