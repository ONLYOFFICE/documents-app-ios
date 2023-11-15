//
//  ASCFolderCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 21/08/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import MGSwipeTableCell
import UIKit

class ASCFolderCell: MGSwipeTableCell {
    // MARK: - Properties

    @IBOutlet var title: UILabel!
    @IBOutlet var titleImage: UIImageView!
    @IBOutlet var owner: UILabel!
    @IBOutlet var date: UILabel!
    @IBOutlet var icon: ASCFolderLogoAvatarView!
    @IBOutlet var privateIcon: UIImageView!
    @IBOutlet var titleStackView: UIStackView!
    @IBOutlet var dateRight: UILabel!

    var folder: ASCFolder? {
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
        $0.text = "0"
        $0.textStyle = .caption2White
        $0.padding = UIEdgeInsets(top: 2, left: 4, bottom: 3, right: 4)
        $0.layerCornerRadius = 4
        $0.sizeToFit()
        return $0
    }(ASCPaddingLabel(frame: .zero))

    private lazy var roomPlaceholderImage = UIImage(
        color: .clear,
        size: CGSize(width: Constants.imageSize, height: Constants.imageSize)
    )

    fileprivate let transformWidth = 450.0

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.clipsToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = Asset.Colors.tableCellSelected.color
    }

    override func layoutSubviews() {
        date?.isHidden = frame.width > transformWidth

        if let dateRight {
            dateRight.isHidden = frame.width <= transformWidth
            dateRight.translatesAutoresizingMaskIntoConstraints = false
            dateRight.removeConstraints(dateRight.constraints)
            dateRight.widthAnchor.constraint(equalToConstant: 126).isActive = true
        }

        super.layoutSubviews()
    }

    func updateData() {
        guard let folderInfo = folder else {
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

        title?.text = folderInfo.title
        titleStackView?.addArrangedSubview(title)

        /// Status info in title

        if #available(iOS 13.0, *) {
            if folderInfo.new > 0 {
                newBadge.text = String.compactNumeric(folderInfo.new)
                newBadge.sizeToFit()
                titleStackView?.addArrangedSubview(UIImageView(image: newBadge.screenshot))
            }
        }

        /// Display owner

        owner?.text = folderInfo.createdBy?.displayName ?? NSLocalizedString("Unknown", comment: "Invalid entity name")

        /// Display date

        date?.text = (folderInfo.created != nil) ? dateFormatter.string(from: folderInfo.created!) : nil
        dateRight?.text = (folderInfo.created != nil) ? dateFormatter.string(from: folderInfo.created!) : nil

        /// Thumb view
        if folder?.roomType != nil, folder?.rootFolderType == .onlyofficeRoomArchived {
            setDefaultIcon()
        } else if let roomType = folder?.roomType {
            setRoomIcon(roomType: roomType)
        } else {
            icon.image = Asset.Images.listFolder.image
        }

        if let folder = folder, folder.pinned {
            titleImage.image = Asset.Images.pin.image
        }

        if let provider = folder?.providerType {
            switch provider {
            case .boxNet:
                icon.image = Asset.Images.listFolderBoxnet.image
            case .dropBox:
                icon.image = Asset.Images.listFolderDropbox.image
            case .google,
                 .googleDrive:
                icon.image = Asset.Images.listFolderGoogledrive.image
            case .sharePoint,
                 .skyDrive,
                 .oneDrive:
                icon.image = Asset.Images.listFolderOnedrive.image
            case .webDav:
                icon.image = Asset.Images.listFolderWebdav.image
            case .yandex:
                icon.image = Asset.Images.listFolderYandexdisk.image
            case .kDrive:
                icon.image = Asset.Images.listFolderKdrive.image
            default:
                break
            }
        }

        if let rootFolderType = folder?.rootFolderType {
            switch rootFolderType {
            case .icloudAll:
                owner?.text = nil
            default:
                break
            }
        }

        if titleImage.image != nil {
            titleStackView?.addArrangedSubview(titleImage)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleImage.image = nil
    }

    private func setRoomIcon(roomType: ASCRoomType) {
        guard let provider else { return }

        let processor = RoundCornerImageProcessor(
            cornerRadius: Constants.cornerRadius,
            targetSize: CGSizeMake(Constants.imageSize, Constants.imageSize)
        )

        icon?.kf.setProviderImage(
            with: provider.absoluteUrl(from: folder?.logo.large ?? ""),
            for: provider,
            placeholder: roomPlaceholderImage,
            options: [
                .processor(processor),
            ],
            completionHandler: { [weak self] result in
                switch result {
                case .failure:
                    self?.setDefaultIcon()
                default:
                    break
                }
            }
        )

        setPrivateIcon()
    }

    private func setDefaultIcon() {
        if let icon = icon {
            icon.image = roomPlaceholderImage
            var color = UIColor()
            if folder?.rootFolderType == .onlyofficeRoomArchived {
                color = UIColor(hex: "#A3A9AE")
            } else {
                color = UIColor(hex: "#" + (folder?.logo.color ?? "FF6680"))
            }

            icon.titleInitials = formatFolderName(folderName: folder?.title ?? "")
            icon.backgroundColor = color
            icon.layerCornerRadius = Constants.cornerRadius
            icon.updateAppearance()
        }
    }

    private func setPrivateIcon() {
        if let folder = folder {
            if !folder.isPrivate {
                privateIcon.isHidden = true
            } else {
                privateIcon.isHidden = false
            }
        }
    }

    private func formatFolderName(folderName: String) -> String {
        let nameComponents = folderName.split(separator: " ")

        switch nameComponents.count {
        case 0:
            return ""
        case 1:
            if let firstInitial = nameComponents.first?.first {
                return String(firstInitial).uppercased()
            } else {
                return ""
            }
        default:
            let firstNameInitial = nameComponents.first?.first.map(String.init) ?? ""
            let lastNameInitial = nameComponents.last?.first.map(String.init) ?? ""
            return (firstNameInitial + lastNameInitial).uppercased()
        }
    }
}

private enum Constants {
    static let imageSize: CGFloat = 36
    static let cornerRadius: CGFloat = 8
}
