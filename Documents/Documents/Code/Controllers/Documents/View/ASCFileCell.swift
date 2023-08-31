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
    @IBOutlet var titleStackView: UIStackView!
    @IBOutlet var dateRight: UILabel!
    @IBOutlet var rightMarginConstraint: NSLayoutConstraint!

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

    private lazy var newBadge: ASCPaddingLabel = {
        $0.backgroundColor = Asset.Colors.badge.color
        $0.text = NSLocalizedString("new", comment: "Badge of file in file list").lowercased()
        $0.textStyle = .caption2White
        $0.padding = UIEdgeInsets(top: 2, left: 4, bottom: 3, right: 4)
        $0.layerCornerRadius = 4
        $0.sizeToFit()
        return $0
    }(ASCPaddingLabel(frame: .zero))

    fileprivate let transformWidth = 450.0

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

    override func layoutSubviews() {
        let isCompact = frame.width < transformWidth
        rightMarginConstraint.constant = isCompact ? 10 : 40
        date?.isHidden = !isCompact
        separaterLabel?.isHidden = !isCompact

        if let dateRight {
            dateRight.isHidden = isCompact
            dateRight.translatesAutoresizingMaskIntoConstraints = false
            dateRight.removeConstraints(dateRight.constraints)
            dateRight.widthAnchor.constraint(equalToConstant: 126).isActive = true
        }

        super.layoutSubviews()
    }

    func updateData() {
        guard let fileInfo = file else {
            title?.text = NSLocalizedString("Unknown", comment: "Invalid entity name")
            owner?.text = NSLocalizedString("none", comment: "Invalid entity owner")
            date?.text = NSLocalizedString("none", comment: "Invalid entity date")
            return
        }

        /// Display title

        for view in titleStackView?.arrangedSubviews ?? [] {
            view.removeFromSuperview()
        }
        titleStackView?.alignment = .center

        title?.text = fileInfo.title
        titleStackView?.addArrangedSubview(title)

        /// Status info in title

        if #available(iOS 13.0, *) {
            if fileInfo.isEditing {
                let editImage = UIImage(
                    systemName: "pencil",
                    withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 13, weight: .black))
                )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage()

                titleStackView?.addArrangedSubview(UIImageView(image: editImage))
            }

            if fileInfo.isFavorite {
                let favoriteImage = UIImage(
                    systemName: "star.fill",
                    withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 13, weight: .medium))
                )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage()

                titleStackView?.addArrangedSubview(UIImageView(image: favoriteImage))
            }

            if fileInfo.isNew, let badgeNewImage = newBadge.screenshot {
                titleStackView?.addArrangedSubview(UIImageView(image: badgeNewImage))
            }
        }

        /// Display owner

        owner?.text = fileInfo.createdBy?.displayName

        /// Display date

        date?.text = (fileInfo.updated != nil)
            ? dateFormatter.string(from: fileInfo.updated!)
            : nil
        dateRight?.text = date?.text

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
            if fileExt == ASCConstants.FileExtensions.docxf {
                icon?.image = Asset.Images.listFormatDocxf.image
            } else if fileExt == ASCConstants.FileExtensions.oform {
                icon?.image = Asset.Images.listFormatOform.image
            } else {
                icon?.image = Asset.Images.listFormatUnknown.image
            }
        } else if fileExt == ASCConstants.FileExtensions.pdf {
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
