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

    var layoutType: ASCEntityViewLayoutType = .list {
        didSet {
            buildView()
        }
    }

    private lazy var imageView: UIImageView = {
        $0.clipsToBounds = true
        return $0
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
        formatter.timeStyle = .none
        return formatter
    }()

    fileprivate lazy var dateTimeFormatter: DateFormatter = {
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

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
    }

    private func buildView() {
//        contentView.backgroundColor = .red

        for view in contentView.subviews {
            view.removeFromSuperview()
        }

        let itemView = layoutType == .grid ? buildGridView() : buildListView()

        contentView.addSubview(itemView)
        itemView.fillToSuperview()

        updateEditing()
        updateSelected()
    }

    // MARK: - List Layout

    private func buildListTitleView() -> UIView {
        guard let file = entity as? ASCFile else { return UIView() }

        var items: [UIView] = [titleLabel]

        titleLabel.text = file.title

        if file.isEditing {
            items.append({
                $0.contentMode = .center
                return $0
            }(UIImageView(image: UIImage(
                systemName: "pencil",
                withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: Constants.overlayBagesFontSize, weight: .black))
            )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage())))
        }

        if file.isFavorite {
            items.append({
                $0.contentMode = .center
                return $0
            }(UIImageView(image: UIImage(
                systemName: "star.fill",
                withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: Constants.overlayBagesFontSize, weight: .black))
            )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage())))
        }

        if file.isNew, let badgeNewImage = newBadge.screenshot {
            items.append({
                $0.contentMode = .center
                return $0
            }(UIImageView(image: badgeNewImage)))
        }

        items.append(UIView(frame: CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: 0))))

        return {
            $0.axis = .horizontal
            $0.spacing = 2
            return $0
        }(UIStackView(arrangedSubviews: items))
    }

    private func buildListDateSizeView() -> UIView? {
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
            dateLabel.text = dateTimeFormatter.string(from: date)
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

    private func buildListView() -> UIView {
        var items = [UIView]()

        let middleStackView = UIStackView(arrangedSubviews: [buildListTitleView()])
        middleStackView.axis = .vertical
        middleStackView.spacing = 1

        if let ownerView = buildOwnerView() {
            middleStackView.addArrangedSubview(ownerView)
        }

        if let dateSizeView = buildListDateSizeView() {
            middleStackView.addArrangedSubview(dateSizeView)
        }

        items.append(checkmarkView)
        items.append(buildIconView(preferredSize: iconSize))
        items.append(middleStackView)

        checkmarkView.removeConstraints(checkmarkView.constraints)
        checkmarkView.anchor(widthConstant: Constants.checkmarkSize)
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
        separatorView.removeConstraints(separatorView.constraints)
        separatorView.anchor(
            leading: middleStackView.leadingAnchor,
            bottom: containerView.bottomAnchor,
            trailing: containerView.trailingAnchor,
            size: CGSize(width: 0, height: 1.0 / UIScreen.main.scale)
        )

        return containerView
    }

    // MARK: - Grid Layout

    private func buildGridView() -> UIView {
        guard let file = entity as? ASCFile else { return UIView() }

        let iconView = buildIconView(preferredSize: iconSize)

        let titleLabel = {
            $0.font = UIFont.preferredFont(forTextStyle: .subheadline)
            $0.textAlignment = .center
            $0.numberOfLines = 2
            $0.textColor = .label
            $0.text = file.title
            return $0
        }(UILabel())

        let dateLabel = {
            $0.font = UIFont.preferredFont(forTextStyle: .caption2)
            $0.textAlignment = .center
            $0.numberOfLines = 1
            $0.textColor = .secondaryLabel
            $0.text = dateFormatter.string(from: file.updated ?? Date())
            return $0
        }(UILabel())

        let sizeLabel = {
            $0.font = UIFont.preferredFont(forTextStyle: .caption2)
            $0.textAlignment = .center
            $0.numberOfLines = 1
            $0.textColor = .secondaryLabel
            $0.text = file.displayContentLength
            return $0
        }(UILabel())

        // Overlay markers
        var overlays: [UIView] = []

        if file.isNew, let badgeNewImage = newBadge.screenshot {
            overlays.append(UIImageView(image: badgeNewImage))
        }

        if file.isEditing {
            overlays.append(UIImageView(image: UIImage(
                systemName: "pencil",
                withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: Constants.overlayBagesFontSize, weight: .black))
            )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage()))
        }

        if file.isFavorite {
            overlays.append(UIImageView(image: UIImage(
                systemName: "star.fill",
                withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: Constants.overlayBagesFontSize, weight: .black))
            )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage()))
        }

        let overlayView = {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.distribution = .fill
            $0.spacing = 5
            return $0
        }(UIStackView(arrangedSubviews: overlays))

        let contentView = {
            $0.axis = .vertical
            $0.alignment = .center
            $0.distribution = .fill
            $0.spacing = 2
            return $0
        }(UIStackView(arrangedSubviews: [
            {
                $0.anchor(heightConstant: 10)
                return $0
            }(UIView()),
            iconView,
            {
                $0.anchor(heightConstant: 10)
                return $0
            }(UIView()),
            titleLabel,
            dateLabel,
            sizeLabel,
            UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 100))),
        ]))

        let containerView = UIView()

        containerView.addSubview(contentView)
        contentView.fillToSuperview()

        containerView.addSubview(overlayView)
        overlayView.anchor(
            top: contentView.topAnchor,
            leading: contentView.leadingAnchor,
            padding: UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 0)
        )

        checkmarkView.removeConstraints(checkmarkView.constraints)
        containerView.addSubview(checkmarkView)
        checkmarkView.anchor(
            top: containerView.topAnchor,
            trailing: containerView.trailingAnchor,
            padding: UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 10),
            size: CGSize(width: Constants.checkmarkSize, height: Constants.checkmarkSize)
        )
        displayCheckmark(show: configurationState.isEditing)

        return containerView
    }

    // MARK: - Common Layout

    private func buildIconView(preferredSize: CGSize) -> UIView {
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
                activityIndicator.startAnimating()

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

                        self?.activityIndicator.stopAnimating()
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

        imageView.removeConstraints(imageView.constraints)

        imageView.anchor(
            widthConstant: preferredSize.width,
            heightConstant: preferredSize.height
        )

        let parentView = UIView()

        parentView.addSubview(imageView)
        imageView.fillToSuperview()

        parentView.addSubview(activityIndicator)
        activityIndicator.anchorCenterSuperview()

        return parentView
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

    // MARK: - Handlers

    private func updateData() {
        buildView()
    }

    private func updateSelected() {
        checkmarkView.image = UIImage(
            systemName: isSelected ? "star.fill" : "star",
            withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: Constants.overlayBagesFontSize, weight: .medium))
        )?.withTintColor(Asset.Colors.brend.color, renderingMode: .alwaysOriginal) ?? UIImage()

        contentView.backgroundColor = isSelected ? .systemGray5 : .clear
        contentView.layerCornerRadius = cornerRadius
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

extension ASCFileViewCell {
    private var cornerRadius: CGFloat {
        layoutType == .grid ? Constants.gridCornerRadius : Constants.listCornerRadius
    }

    private var iconSize: CGSize {
        layoutType == .grid ? Constants.gridIconSize : Constants.listIconSize
    }
}

private enum Constants {
    static let checkmarkSize: CGFloat = 16
    static let gridCornerRadius: CGFloat = 12
    static let listCornerRadius: CGFloat = 0
    static let overlayBagesFontSize: CGFloat = 13
    static let listIconSize = CGSize(width: 45, height: 50)
    static let gridIconSize = CGSize(width: 80, height: 80)
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
