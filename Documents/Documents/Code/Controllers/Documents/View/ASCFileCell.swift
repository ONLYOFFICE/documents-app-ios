//
//  ASCFileCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 21/08/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import MGSwipeTableCell
import UIKit

class ASCFileCell: MGSwipeTableCell {
    // MARK: - Properties

    @IBOutlet var title: UILabel!
    @IBOutlet var date: UILabel!
    @IBOutlet var owner: UILabel!
    @IBOutlet var sizeLabel: UILabel!
    @IBOutlet var separaterLabel: UILabel!
    @IBOutlet var icon: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    var file: ASCFile? {
        didSet {
            updateData()
        }
    }

    var provider: ASCFileProviderProtocol?

    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        contentView.clipsToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = Asset.Colors.tableCellSelected.color
    }

    func updateData() {
        guard let fileInfo = file else {
            title?.text = NSLocalizedString("Unknown", comment: "Invalid entity name")
            owner?.text = NSLocalizedString("none", comment: "Invalid entity owner")
            date?.text = NSLocalizedString("none", comment: "Invalid entity date")
            return
        }

        title?.text = fileInfo.title
        owner?.text = fileInfo.createdBy?.displayName
        date?.text = (fileInfo.updated != nil)
            ? dateFormatter.string(from: fileInfo.updated!)
            : nil

        if fileInfo.pureContentLength < 1 {
            if fileInfo.device {
                separaterLabel?.text = "•"
                sizeLabel?.text = fileInfo.displayContentLength
            } else {
                separaterLabel?.text = ""
                sizeLabel?.text = ""
            }
        } else {
            separaterLabel?.text = "•"
            sizeLabel?.text = fileInfo.displayContentLength
        }

        /// Status info

        if #available(iOS 13.0, *) {
            if fileInfo.isEditing {
                let editImage = UIImage(
                    systemName: "pencil",
                    withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 13, weight: .black))
                )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage()

                title?.addTrailing(image: editImage)
            }

            if fileInfo.isFavorite {
                let favoriteImage = UIImage(
                    systemName: "star.fill",
                    withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 13, weight: .medium))
                )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage()

                title?.addTrailing(image: favoriteImage)
            }
        }

        /// Thumb view
        let fileExt = fileInfo.title.fileExtension().lowercased()

        icon?.contentMode = .center
        icon?.alpha = 1
        activityIndicator?.isHidden = true

        if ASCConstants.FileExtensions.images.contains(fileExt) {
            if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.previewFiles) {
                activityIndicator?.isHidden = false
                icon?.alpha = 0

                guard let provider = provider else {
                    icon?.image = Asset.Images.listFormatImage.image
                    return
                }

                icon?.kf.setProviderImage(
                    with: provider.absoluteUrl(from: fileInfo.viewUrl),
                    for: provider,
                    placeholder: Asset.Images.listFormatImage.image,
                    completionHandler: { [weak self] result in
                        switch result {
                        case .success:
                            self?.icon?.contentMode = .scaleAspectFit
                        default:
                            self?.icon?.contentMode = .center
                        }

                        self?.activityIndicator?.isHidden = true
                        UIView.animate(withDuration: 0.2) { [weak self] in
                            self?.icon?.alpha = 1
                        }
                    }
                )
            } else {
                icon?.image = Asset.Images.listFormatImage.image
            }
        } else if ASCConstants.FileExtensions.documents.contains(fileExt) {
            icon?.image = Asset.Images.listFormatDocument.image
        } else if ASCConstants.FileExtensions.spreadsheets.contains(fileExt) {
            icon?.image = Asset.Images.listFormatSpreadsheet.image
        } else if ASCConstants.FileExtensions.presentations.contains(fileExt) {
            icon?.image = Asset.Images.listFormatPresentation.image
        } else if ASCConstants.FileExtensions.videos.contains(fileExt) {
            icon?.image = Asset.Images.listFormatVideo.image
        } else if ASCConstants.FileExtensions.forms.contains(fileExt) {
            if fileExt == "docxf" {
                icon?.image = Asset.Images.listFormatDocxf.image
            } else if fileExt == "oform" {
                icon?.image = Asset.Images.listFormatOform.image
            } else {
                icon?.image = Asset.Images.listFormatUnknown.image
            }
        } else if fileExt == "pdf" {
            icon?.image = Asset.Images.listFormatPdf.image
        } else {
            icon?.image = Asset.Images.listFormatUnknown.image
        }

        if let rootFolderType = file?.parent?.rootFolderType {
            switch rootFolderType {
            case .icloudAll:
                owner?.text = nil
            default:
                break
            }
        }
    }
}
