//
//  ASCFileViewCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 26.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

final class ASCFileViewCell: UICollectionViewCell & ASCEntityViewCellProtocol {
    static let identifier = String(describing: ASCFileViewCell.self)

    // MARK: - Properties

    override var isSelected: Bool {
        didSet {
            updateSelected()
        }
    }

    var entity: ASCEntity? {
        didSet {
            updateData()
        }
    }

    var provider: ASCFileProviderProtocol?

    private lazy var imageView: UIImageView = {
        $0
    }(UIImageView())

    private lazy var activityIndicator: UIActivityIndicatorView = {
        $0
    }(UIActivityIndicatorView(style: .medium))

    private lazy var titleLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = UIFont.preferredFont(forTextStyle: .callout)
        $0.textColor = .label
        return $0
    }(UILabel())

    private lazy var authorLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = UIFont.preferredFont(forTextStyle: .caption1)
        $0.textColor = .secondaryLabel
        return $0
    }(UILabel())

    private lazy var dateRightLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = UIFont.preferredFont(forTextStyle: .subheadline)
        $0.textColor = .secondaryLabel
        return $0
    }(UILabel())

    private lazy var newBadge: ASCPaddingLabel = {
        $0.backgroundColor = Asset.Colors.badge.color
        $0.text = NSLocalizedString("new", comment: "Badge of file in file list").lowercased()
        $0.textStyle = .caption2White
        $0.padding = UIEdgeInsets(top: 2, left: 4, bottom: 3, right: 4)
        $0.layerCornerRadius = 4
        $0.sizeToFit()
        return $0
    }(ASCPaddingLabel(frame: .zero))

    private lazy var separatorView: UIView = {
        $0.backgroundColor = .separator
        return $0
    }(UIView())

    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private lazy var checkmarkView: UIImageView = {
        $0.contentMode = .center
        return $0
    }(UIImageView())

    // MARK: - Lifecycle Methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)

        updateEditing()
        updateSelected()
    }

    private func buildView() {
//        contentView.backgroundColor = .red

        for view in contentView.subviews {
            view.removeFromSuperview()
        }

        let itemView = buildListView()
        contentView.addSubview(itemView)
        itemView.fillToSuperview()
    }

    private func buildTitleListView() -> UIView {
        guard let file = entity as? ASCFile else { return UIView() }

        var items: [UIView] = [titleLabel]

        titleLabel.text = file.title

        if file.isEditing {
            items.append(
                UIImageView(image: UIImage(
                    systemName: "pencil",
                    withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 13, weight: .black))
                )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage())
            )
        }

        if file.isFavorite {
            items.append(
                UIImageView(image: UIImage(
                    systemName: "star.fill",
                    withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 13, weight: .medium))
                )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage())
            )
        }

        if file.isNew, let badgeNewImage = newBadge.screenshot {
            items.append(
                UIImageView(image: badgeNewImage)
            )
        }

        return {
            $0.axis = .horizontal
            return $0
        }(UIStackView(arrangedSubviews: items))
    }

    private func buildOwnerView() -> UIView? {
        guard let file = entity as? ASCFile else { return nil }

        if let rootFolderType = file.parent?.rootFolderType {
            switch rootFolderType {
            case .icloudAll:
                return nil
            default:
                break
            }
        }

        authorLabel.text = file.createdBy?.displayName

        return authorLabel
    }

    private func buildDateSizeView() -> UIView? {
        guard let file = entity as? ASCFile else { return nil }

        let buildLabel: (() -> UILabel) = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = UIFont.preferredFont(forTextStyle: .caption1)
            label.textColor = .secondaryLabel
            return label
        }

        let dateLabel = buildLabel()
        let separateLabel = buildLabel()
        let sizeLabel = buildLabel()

        if let date = file.updated {
            dateLabel.text = dateFormatter.string(from: date)
        } else {
            dateLabel.text = nil
        }

        var items = [UIView]()

        if dateLabel.text != nil {
            items.append(dateLabel)
        }

        if items.contains(dateLabel) {
            separateLabel.text = "•"
            items.append(separateLabel)
        }

        if file.pureContentLength < 1 {
            if file.device {
                sizeLabel.text = file.displayContentLength
                items.append(sizeLabel)
            }
        } else {
            sizeLabel.text = file.displayContentLength
            items.append(sizeLabel)
        }

        // Spacer
        items.append(UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: UIScreen.main.bounds.width))))

        return {
            $0.axis = .horizontal
            $0.alignment = .fill
            $0.distribution = .fill
            $0.spacing = 4
            return $0
        }(UIStackView(arrangedSubviews: items))
    }

    private func buildIconViewView() -> UIView {
        guard
            let file = entity as? ASCFile,
            let provider
        else { return UIView() }

        let fileExt = file.title.fileExtension().lowercased()

        imageView.contentMode = .center
        imageView.alpha = 1
        activityIndicator.isHidden = true

        if ASCConstants.FileExtensions.images.contains(fileExt) {
            if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.previewFiles) {
                activityIndicator.isHidden = false
                imageView.alpha = 0
                imageView.image = Asset.Images.listFormatImage.image

                imageView.kf.setProviderImage(
                    with: provider.absoluteUrl(from: file.viewUrl),
                    for: provider,
                    placeholder: Asset.Images.listFormatImage.image,
                    completionHandler: { [weak self] result in
                        switch result {
                        case .success:
                            self?.imageView.contentMode = .scaleAspectFit
                        default:
                            self?.imageView.contentMode = .center
                        }

                        self?.activityIndicator.isHidden = true
                        UIView.animate(withDuration: 0.2) { [weak self] in
                            self?.imageView.alpha = 1
                        }
                    }
                )
            } else {
                imageView.image = Asset.Images.listFormatImage.image
            }
        } else if ASCConstants.FileExtensions.documents.contains(fileExt) {
            imageView.image = Asset.Images.listFormatDocument.image
        } else if ASCConstants.FileExtensions.spreadsheets.contains(fileExt) {
            imageView.image = Asset.Images.listFormatSpreadsheet.image
        } else if ASCConstants.FileExtensions.presentations.contains(fileExt) {
            imageView.image = Asset.Images.listFormatPresentation.image
        } else if ASCConstants.FileExtensions.videos.contains(fileExt) {
            imageView.image = Asset.Images.listFormatVideo.image
        } else if ASCConstants.FileExtensions.forms.contains(fileExt) {
            if fileExt == ASCConstants.FileExtensions.docxf {
                imageView.image = Asset.Images.listFormatDocxf.image
            } else if fileExt == ASCConstants.FileExtensions.oform {
                imageView.image = Asset.Images.listFormatOform.image
            } else {
                imageView.image = Asset.Images.listFormatUnknown.image
            }
        } else if fileExt == ASCConstants.FileExtensions.pdf {
            imageView.image = Asset.Images.listFormatPdf.image
        } else {
            imageView.image = Asset.Images.listFormatUnknown.image
        }

        imageView.anchor(widthConstant: 45)

        let parentView = UIView()

        parentView.addSubview(imageView)
        imageView.fillToSuperview()

        parentView.addSubview(activityIndicator)
        activityIndicator.anchorCenterSuperview()

        return parentView
    }

    private func buildListView() -> UIView {
        var items = [UIView]()

        let middleStackView = UIStackView(arrangedSubviews: [buildTitleListView()])
        middleStackView.axis = .vertical
        middleStackView.spacing = 1

        if let ownerView = buildOwnerView() {
            middleStackView.addArrangedSubview(ownerView)
        }

        if let dateSizeView = buildDateSizeView() {
            middleStackView.addArrangedSubview(dateSizeView)
        }

        items.append(checkmarkView)
        items.append(buildIconViewView())
        items.append(middleStackView)

        checkmarkView.anchor(widthConstant: 16)
        displayCheckmark(show: configurationState.isEditing)

        let contentView = {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.distribution = .fillProportionally
            $0.spacing = 10
            return $0
        }(UIStackView(arrangedSubviews: items))

        let containerView = UIView()

        containerView.addSubview(contentView)
        containerView.addSubview(separatorView)

        contentView.fillToSuperview(padding: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 5))
        separatorView.anchor(
            leading: middleStackView.leadingAnchor,
            bottom: containerView.bottomAnchor,
            trailing: containerView.trailingAnchor,
            size: CGSize(width: 0, height: 1.0 / UIScreen.main.scale)
        )

        return containerView
    }

    private func buildGridView() {
        //
    }

    private func updateData() {
//        guard let file = entity as? ASCFile else { return }
        buildView()
    }

    private func updateSelected() {
        checkmarkView.image = UIImage(
            systemName: isSelected ? "star.fill" : "star",
            withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 13, weight: .medium))
        )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage()
    }

    private func updateEditing() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self else { return }
            self.displayCheckmark(show: self.configurationState.isEditing)
        }
    }

    private func displayCheckmark(show: Bool) {
        checkmarkView.alpha = show ? 1 : 0
        checkmarkView.isHidden = !show
    }
}

// @available(iOS 17, *)
// #Preview {
//    let user = ASCUser()
//    user.displayName = "Jameson Kortney"
//
//    let file = ASCFile()
//    file.title = "Sample Document.docx"
//    file.device = true
//    file.createdBy = user
//    file.updated = Date()
//    file.pureContentLength = 43_542_234
//    file.displayContentLength = String.fileSizeToString(with: 43_542_234)
//
//    let cell = ASCFileViewCell()
//    cell.provider = ASCLocalProvider()
//    cell.entity = file
//    cell.isSelected = true
//
//    return cell
// }
