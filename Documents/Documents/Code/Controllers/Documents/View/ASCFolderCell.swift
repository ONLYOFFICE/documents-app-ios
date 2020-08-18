//
//  ASCFolderCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 21/08/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class ASCFolderCell: MGSwipeTableCell {

    // MARK: - Properties

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var owner: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var icon: UIImageView!

    var folder: ASCFolder? = nil {
        didSet {
            updateData()
        }
    }

    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.clipsToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor(named: "table-cell-selected")
    }

    func updateData() {
        guard let folderInfo = folder else {
            title?.text = NSLocalizedString("Unknown", comment: "Invalid entity name")
            owner?.text = NSLocalizedString("none", comment: "Invalid entity owner")
            date?.text  = NSLocalizedString("none", comment: "Invalid entity date")
            return
        }

        title?.text = folderInfo.title
        owner?.text = folderInfo.createdBy?.displayName ?? NSLocalizedString("Unknown", comment: "Invalid entity name")
        date?.text = (folderInfo.created != nil) ? dateFormatter.string(from: folderInfo.created!) : nil

        icon.image = UIImage(named: "list-folder")

        if let provider = folder?.providerType {
            switch provider {
            case .boxNet:
                icon.image = UIImage(named: "list-folder-boxnet")
            case .dropBox:
                icon.image = UIImage(named: "list-folder-dropbox")
            case .google,
                 .googleDrive:
                icon.image = UIImage(named: "list-folder-googledrive")
            case .sharePoint,
                 .skyDrive,
                 .oneDrive:
                icon.image = UIImage(named: "list-folder-onedrive")
            case .webDav:
                icon.image = UIImage(named: "list-folder-webdav")
            case .yandex:
                icon.image = UIImage(named: "list-folder-yandexdisk")
            default:
                break
            }
        }
    }
}

