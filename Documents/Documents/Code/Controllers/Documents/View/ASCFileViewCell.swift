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

    var entity: ASCEntity? {
        didSet {
            updateData()
        }
    }

    var provider: ASCFileProviderProtocol?

    var dragAndDropState: Bool = false {
        didSet {
            buildView()
        }
    }

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
        $0.textAlignment = ASCCommon.isRTL ? .left : .right
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

    private lazy var filterBadge: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.image = Asset.Images.filterGreen.image
        $0.contentMode = .scaleAspectFit

        return $0
    }(UIImageView())

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

    private var isCompact: Bool {
        frame.width < Constants.transformWidth
    }

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

        if file.customFilterEnabled {
            items.append(filterBadge)
        }

        if file.isExpiredSoon {
            items.append({
                $0.contentMode = .center
                return $0
            }(UIImageView(
                image: UIImage(
                    named: "clock-cirlce-arrow"
                ) ?? UIImage()
            )))
        }

        if file.formFillingStatus != .none {
            items.append(
                buildTextBadge(
                    file.formFillingStatus.localizedString,
                    color: file.formFillingStatus.uiColor
                )
            )
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
            dateRightLabel.text = dateTimeFormatter.string(from: date)

            if !isCompact {
                dateLabel.text = nil
            }
        } else {
            dateLabel.text = nil
            dateRightLabel.text = nil
        }

        var items = [UIView]()

        // VDR index
        if let order = file.order {
            let orderLabel = buildLabel()
            let orderSeparator = buildLabel()

            orderLabel.text = [
                NSLocalizedString("Index", comment: "File order"),
                order,
            ].joined(separator: " ")
            orderSeparator.text = "|"

            items.append(orderLabel)
            items.append(orderSeparator)
        }

        if dateLabel.text != nil {
            items.append(dateLabel)
        }

        if items.contains(dateLabel) {
            separateLabel.text = "•"

            if !isCompact {
                separateLabel.text = nil
            }

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

        items.append(.spacer)

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
        items.append(dateRightLabel)
        items.append({
            $0.anchor(widthConstant: 20)
            return $0
        }(UIView()))
        if dragAndDropState {
            items.append({
                $0.contentMode = .center
                $0.anchor(widthConstant: 20)
                return $0
            }(UIImageView(image: UIImage(
                systemName: "line.3.horizontal"
            )?.withTintColor(.separator, renderingMode: .alwaysOriginal) ?? UIImage())))

            items.append({
                $0.anchor(widthConstant: 10)
                return $0
            }(UIView()))
        }

        checkmarkView.removeConstraints(checkmarkView.constraints)
        checkmarkView.anchor(widthConstant: Constants.checkmarkSize)
        displayCheckmark(show: configurationState.isEditing)
        displayRightInfo(show: !isCompact)

        let contentView = {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.distribution = .fill
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

        let contentView = {
            $0.axis = .vertical
            $0.alignment = .center
            $0.distribution = .fill
            $0.spacing = 2
            return $0
        }(UIStackView(arrangedSubviews: [
            iconView,
            titleLabel,
            dateLabel,
            sizeLabel,
        ]))

        let containerView = UIView()

        containerView.addSubview(contentView)
        contentView.anchor(
            top: containerView.topAnchor,
            leading: containerView.leadingAnchor,
            bottom: containerView.bottomAnchor,
            trailing: containerView.trailingAnchor,
            padding: UIEdgeInsets(top: 16, left: 0, bottom: 2, right: 0)
        )

        // Top left overlay markers
        let topLeftOverlayView = buildGridBadgesOverlayView(file: file)
        containerView.addSubview(topLeftOverlayView)
        topLeftOverlayView.anchor(
            top: containerView.topAnchor,
            leading: containerView.leadingAnchor,
            padding: UIEdgeInsets(top: 4, left: 6, bottom: 0, right: 0)
        )

        // Bottom right overlay markers
        let bottomRightOverlayView = buildGridFileTypeOverlay(file: file)
        containerView.addSubview(bottomRightOverlayView)
        bottomRightOverlayView.anchor(
            bottom: iconView.bottomAnchor,
            trailing: containerView.trailingAnchor,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 3, right: 10)
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

    private func buildGridBadgesOverlayView(file: ASCFile) -> UIView {
        var overlays = [UIView]()
        if file.isNew, let badgeNewImage = newBadge.screenshot {
            overlays.append(UIImageView(image: badgeNewImage))
        }

        if file.formFillingStatus != .none {
            overlays.append(
                buildTextBadge(
                    file.formFillingStatus.localizedString,
                    color: file.formFillingStatus.uiColor
                )
            )
        }

        if file.customFilterEnabled {
            overlays.append(filterBadge)
        }
        if file.isEditing {
            overlays.append(buildSymbolBadge("pencil"))
        }

        if file.isFavorite {
            overlays.append(buildSymbolBadge("star.fill"))
        }

        let overlayView = {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.distribution = .fill
            $0.spacing = 5
            return $0
        }(UIStackView(arrangedSubviews: overlays))

        return overlayView
    }

    private func buildGridFileTypeOverlay(file: ASCFile) -> UIView {
        let allowThumbnailPreview = file.allowThumbnailPreview(layoutType: layoutType)

        guard allowThumbnailPreview else { return UIView() }

        var overlays = [UIView]()

        let fileExt = file.title.fileExtension().lowercased()
        if ASCConstants.FileExtensions.spreadsheets.contains(fileExt) {
            overlays.append(UIImageView(image: Asset.Images.formatsSpreadsheet.image))
        } else if ASCConstants.FileExtensions.documents.contains(fileExt) {
            overlays.append(UIImageView(image: Asset.Images.formatsDocument.image))
        } else if ASCConstants.FileExtensions.presentations.contains(fileExt) {
            overlays.append(UIImageView(image: Asset.Images.formatsPresentation.image))
        } else if ASCConstants.FileExtensions.pdfs.contains(fileExt) {
            overlays.append(UIImageView(image: Asset.Images.formatsPdf.image))
        }

        let overlayView = {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.distribution = .fill
            $0.spacing = 5
            return $0
        }(UIStackView(arrangedSubviews: overlays))

        return overlayView
    }

    // MARK: - Common Layout

    private func buildIconView(preferredSize: CGSize) -> UIView {
        guard
            let file = entity as? ASCFile,
            let provider
        else { return UIView() }

        let fileExt = file.title.fileExtension().lowercased()
        let allowThumbnailPreview = file.allowThumbnailPreview(layoutType: layoutType)
        let defaultIconFormatImage = UIImage.getFileExtensionBasedImage(fileExt: fileExt, layoutType: layoutType)

        imageView.contentMode = .center
        imageView.alpha = 1
        imageView.layerBorderWidth = 0
        imageView.layerBorderColor = .clear
        imageView.layerCornerRadius = 5

        activityIndicator.isHidden = true

        if allowThumbnailPreview {
            if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.previewFiles) {
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()

                imageView.alpha = 0
                imageView.image = defaultIconFormatImage

                if ASCConstants.FileExtensions.images.contains(fileExt) {
                    imageView.contentMode = .scaleAspectFit
                } else {
                    imageView.contentMode = .scaleAspectFill
                }

                imageView.kf.setProviderImage(
                    with: provider.absoluteUrl(from: file.thumbnailUrl ?? file.viewUrl),
                    for: provider,
                    placeholder: defaultIconFormatImage,
                    completionHandler: { [weak self] result in
                        switch result {
                        case .success:
                            if ASCConstants.FileExtensions.images.contains(fileExt) {
                                self?.imageView.contentMode = .scaleAspectFit
                            } else {
                                self?.imageView.contentMode = .scaleAspectFill
                                self?.imageView.layerBorderWidth = 1
                                self?.imageView.layerBorderColor = .systemGray5
                            }
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
                imageView.image = defaultIconFormatImage
            }
        } else {
            imageView.image = defaultIconFormatImage
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

    private func buildTextBadge(_ text: String, color: UIColor) -> ASCPaddingLabel {
        {
            $0.backgroundColor = color
            $0.text = text.capitalized
            $0.textAlignment = .center
            $0.textStyle = .caption2White
            $0.padding = UIEdgeInsets(top: 2, left: 4, bottom: 3, right: 4)
            $0.layerCornerRadius = 4
            $0.sizeToFit()
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.heightAnchor.constraint(equalToConstant: 18).isActive = true
            return $0
        }(ASCPaddingLabel(frame: .zero))
    }

    // MARK: - Handlers

    private func updateData() {
        buildView()
    }

    private func updateSelected() {
        checkmarkView.image = isSelected ? Asset.Images.select.image : Asset.Images.unselect.image
        contentView.backgroundColor = isSelected ? .systemGray5 : .clear
        contentView.layerCornerRadius = cornerRadius
    }

    private func updateEditing() {
        displayCheckmark(show: configurationState.isEditing)
    }

    private func displayCheckmark(show: Bool) {
        checkmarkView.alpha = show ? 1 : 0
        checkmarkView.isHidden = !show
    }

    private func displayRightInfo(show: Bool) {
        dateRightLabel.alpha = show ? 1 : 0
        dateRightLabel.isHidden = !show
    }
}

extension ASCFileViewCell {
    private var cornerRadius: CGFloat {
        layoutType == .grid ? Constants.gridCornerRadius : Constants.listCornerRadius
    }

    private var iconSize: CGSize {
        layoutType == .grid ? Constants.gridIconSize : Constants.listIconSize
    }

    private var iconFormatImage: UIImage {
        layoutType == .list ? Asset.Images.listFormatImage.image : Asset.Images.gridFormatImage.image
    }

    private var iconFormatDocument: UIImage {
        layoutType == .list ? Asset.Images.listFormatDocument.image : Asset.Images.gridFormatDocument.image
    }

    private var iconFormatSpreadsheet: UIImage {
        layoutType == .list ? Asset.Images.listFormatSpreadsheet.image : Asset.Images.gridFormatSpreadsheet.image
    }

    private var iconFormatPresentation: UIImage {
        layoutType == .list ? Asset.Images.listFormatPresentation.image : Asset.Images.gridFormatPresentation.image
    }

    private var iconFormatVideo: UIImage {
        layoutType == .list ? Asset.Images.listFormatVideo.image : Asset.Images.gridFormatVideo.image
    }

    private var iconFormatDocxf: UIImage {
        layoutType == .list ? Asset.Images.listFormatDocxf.image : Asset.Images.gridFormatDocxf.image
    }

    private var iconFormatOform: UIImage {
        layoutType == .list ? Asset.Images.listFormatOform.image : Asset.Images.gridFormatOform.image
    }

    private var iconFormatUnknown: UIImage {
        layoutType == .list ? Asset.Images.listFormatUnknown.image : Asset.Images.gridFormatUnknown.image
    }

    private var iconFormatPdf: UIImage {
        layoutType == .list ? Asset.Images.listFormatPdf.image : Asset.Images.gridFormatPdf.image
    }
}

extension ASCFileViewCell {
    /// Circle icon badge
    private func buildSymbolBadge(
        _ systemName: String,
        tint: UIColor = Asset.Colors.brend.color,
        pointSize: CGFloat = Badge.pointSize,
        weight: UIFont.Weight = .black,
        padding: CGFloat = Badge.padding,
        bgColor: UIColor = .systemBackground,
        borderColor: UIColor? = nil,
        borderWidth: CGFloat = 0
    ) -> UIView {
        let config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: pointSize, weight: weight))
        let imageView = UIImageView(
            image: UIImage(systemName: systemName, withConfiguration: config)?
                .withTintColor(tint, renderingMode: .alwaysOriginal)
        )
        imageView.contentMode = UIView.ContentMode.center
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let diameter = pointSize + padding * 2
        let container = UIView(frame: CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter)))
        container.backgroundColor = bgColor
        container.isOpaque = true
        container.layer.cornerRadius = diameter / 2
        container.layer.masksToBounds = true
        if let borderColor { container.layer.borderColor = borderColor.cgColor; container.layer.borderWidth = borderWidth }
        container.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: diameter),
            container.heightAnchor.constraint(equalToConstant: diameter),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        return container
    }
}

private enum Badge {
    static let pointSize: CGFloat = Constants.overlayBagesFontSize
    static let padding: CGFloat = 3
}

private enum Constants {
    static let transformWidth: CGFloat = 450
    static let checkmarkSize: CGFloat = 16
    static let gridCornerRadius: CGFloat = 12
    static let listCornerRadius: CGFloat = 0
    static let overlayBagesFontSize: CGFloat = 13
    static let listIconSize = CGSize(width: 45, height: 50)
    static let gridIconSize = CGSize(width: 80, height: 104)
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

private extension ASCFile {
    func allowThumbnailPreview(layoutType: ASCEntityViewLayoutType) -> Bool {
        let fileExt = title.fileExtension().lowercased()
        return ASCConstants.FileExtensions.images.contains(fileExt) ||
            (layoutType == .grid && thumbnailStatus == .created && thumbnailUrl?.isEmpty == false)
    }
}
