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
    @IBOutlet var icon: UIImageView!
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
            icon.image = Asset.Images.roomArchived.image
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
        guard let provider = provider else { return }
        icon?.kf.setProviderImage(
            with: provider.absoluteUrl(from: folder?.largeLogo ?? ""),
            for: provider,
            placeholder: nil,
            completionHandler: { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(imageResult):
                    guard let image = imageResult.image.kf
                        .resize(to: .init(width: Constants.imageSize, height: Constants.imageSize), for: .aspectFill)
                        .applyCorenerRadious(Constants.cornerRadius)
                    else {
                        self.setDefaultIcon(roomType.image)
                        return
                    }
                    self.icon?.image = image
                    self.icon?.contentMode = .scaleAspectFit
                default:
                    self.setDefaultIcon(roomType.image)
                }
            }
        )
    }

    private func setDefaultIcon(_ image: UIImage) {
        icon?.contentMode = .center
        icon?.image = image
    }

    private func applyRoundedCorners(to image: UIImage, cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        let rect = CGRect(origin: .zero, size: image.size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()

        image.draw(in: rect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

private struct Constants {
    static let imageSize: CGFloat = 36
    static let cornerRadius: CGFloat = 8
}

private extension UIImage {
    func applyCorenerRadious(_ cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
