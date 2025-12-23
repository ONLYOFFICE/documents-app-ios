//
//  ASCFolderViewCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 25.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import UIKit

final class ASCFolderViewCell: UICollectionViewCell & ASCEntityViewCellProtocol {
    static let identifier = String(describing: ASCFolderViewCell.self)

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
        $0.contentMode = .center
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

    private lazy var sharedBadge: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.image = Asset.Images.listSharedLink.image
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

    private var badgeInsets: UIEdgeInsets {
        guard let folder = entity as? ASCFolder else { return .zero }

        if folder.isPublicRoom {
            return layoutType == .grid
                ? UIEdgeInsets(top: 0, left: 0, bottom: -7, right: -7)
                : UIEdgeInsets(top: 0, left: 0, bottom: 3, right: 0)
        }

        if folder.isPrivate {
            return layoutType == .grid
                ? UIEdgeInsets(top: 0, left: 0, bottom: -7, right: -7)
                : UIEdgeInsets(top: 0, left: 0, bottom: 3, right: -3)
        }

        return .zero
    }

    static let listRoomTemplateFrameImage = UIImage.createFrameTexture(
        size: ASCFolder.Constants.listRoomIconSize,
        cornerRadius: ASCFolder.Constants.listRoomIconRadius,
        lineWidth: 2,
        gapBetweenCorners: 10
    )

    static let gridRoomTemplateFrameImage = UIImage.createFrameTexture(
        size: ASCFolder.Constants.gridRoomIconSize,
        cornerRadius: ASCFolder.Constants.gridRoomIconRadius,
        lineWidth: 4,
        gapBetweenCorners: 20
    )

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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            buildView()
        }
    }

    private func buildView() {
        for view in contentView.subviews {
            view.removeFromSuperview()
        }

        let itemView = layoutType == .grid ? buildGridView() : buildListView()

        contentView.addSubview(itemView)

        itemView.anchor(
            top: contentView.topAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: contentView.bottomAnchor,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor
        )

        updateEditing()
        updateSelected()
    }

    // MARK: - Common Layout

    private func buildIconView(preferredSize: CGSize) -> UIView {
        guard
            let folder = entity as? ASCFolder,
            let provider
        else { return UIView() }

        if folder.isTemplateRoom {
            return buildRoomTemplateIconView(preferredSize: preferredSize)
        }

        let badgeImageView: UIImageView = {
            $0.contentMode = .center
            return $0
        }(UIImageView())

        let roomPlaceholderImage = UIImage(
            color: .clear,
            size: preferredSize
        )

        imageView.layerCornerRadius = 0

        // Set icon image
        if let _ = folder.roomType {
            if folder.rootFolderType == .archive {
                imageView.image = roomImageDefault()
            } else {
                let processor = RoundCornerImageProcessor(
                    cornerRadius: folder.roomIconRadius(layoutType: layoutType),
                    targetSize: folder.roomIconSize(layoutType: layoutType)
                )
                imageView.kf.setProviderImage(
                    with: provider.absoluteUrl(from: folder.logo?.large ?? ""),
                    for: provider,
                    placeholder: roomPlaceholderImage,
                    options: [
                        .processor(processor),
                    ],
                    completionHandler: { [weak self] result in
                        switch result {
                        case .success:
                            break
                        case .failure:
                            self?.imageView.image = self?.roomImageDefault()
                        }
                    }
                )
            }
            imageView.layerCornerRadius = folder.roomIconRadius(layoutType: layoutType)
        } else {
            imageView.image = iconFolder
        }

        if let provider = folder.providerType, folder.roomType == nil {
            switch provider {
            case .boxNet:
                imageView.image = iconFolderBoxnet
            case .dropBox:
                imageView.image = iconFolderDropbox
            case .google,
                 .googleDrive:
                imageView.image = iconFolderGoogledrive
            case .sharePoint,
                 .skyDrive,
                 .oneDrive:
                imageView.image = iconFolderOnedrive
            case .webDav:
                imageView.image = iconFolderWebdav
            case .yandex:
                imageView.image = iconFolderYandexdisk
            case .kDrive:
                imageView.image = iconFolderKdrive
            default:
                break
            }
        }

        if let fillFormFolderType = folder.type {
            switch fillFormFolderType {
            case .readyFormFolder:
                imageView.image = iconFillFormRoomFolderDone
            case .inProcessFormFolder:
                imageView.image = iconFillFormRoomFolderInProgress
            default:
                break
            }
        }

        // Set badge icon image if neede

        if folder.isPublicRoom || folder.roomType == .fillingForm {
            badgeImageView.image = iconWorld
        }

        if folder.isPrivate {
            badgeImageView.image = iconSecurity
        }

        // Layout

        imageView.removeConstraints(imageView.constraints)

        imageView.anchor(
            widthConstant: preferredSize.width,
            heightConstant: preferredSize.height
        )

        let parentView = UIView()

        parentView.addSubview(imageView)
        imageView.fillToSuperview()

        if badgeImageView.image != nil {
            parentView.addSubview(badgeImageView)
            badgeImageView.anchor(
                bottom: parentView.bottomAnchor,
                trailing: parentView.trailingAnchor,
                padding: badgeInsets
            )
        }

        parentView.addSubview(activityIndicator)
        activityIndicator.anchorCenterSuperview()

        return parentView
    }

    func buildRoomTemplateIconView(preferredSize: CGSize) -> UIView {
        guard
            let folder = entity as? ASCFolder,
            let provider
        else { return UIView() }

        let badgeImageView: UIImageView = {
            $0.contentMode = .center
            return $0
        }(UIImageView())

        let roomPlaceholderImage = UIImage(
            color: .clear,
            size: preferredSize
        )

        imageView.layerCornerRadius = 0

        // Set icon image

        var roomColor = Asset.Colors.roomDefault.color

        if let hexColor = folder.logo?.color {
            roomColor = UIColor(hex: "#\(hexColor)")
        }

        let literalLabel = {
            $0.font = UIFont.systemFont(ofSize: layoutType == .grid ? 36 : 17, weight: .semibold)
            $0.textColor = roomColor
            $0.textAlignment = .center
            $0.text = folder.formatFolderName(folderName: folder.title)
            return $0
        }(UILabel(frame: CGRect(origin: .zero, size: preferredSize)))

        let roomIconRadius = folder.roomIconRadius(layoutType: layoutType)
        let roomIconSize = folder.roomIconSize(layoutType: layoutType)

        let processor = RoundCornerImageProcessor(
            cornerRadius: roomIconRadius,
            targetSize: CGSize(
                width: roomIconSize.width - iconRoomTemplateOffset * 2,
                height: roomIconSize.height - iconRoomTemplateOffset * 2
            )
        )
        imageView.kf.setProviderImage(
            with: provider.absoluteUrl(from: folder.logo?.large ?? ""),
            for: provider,
            placeholder: roomPlaceholderImage,
            options: [
                .processor(processor),
            ],
            completionHandler: { [weak self] result in
                switch result {
                case .success:
                    break
                case .failure:
                    self?.imageView.image = literalLabel.screenshot
                }
            }
        )

        imageView.layerCornerRadius = folder.roomIconRadius(layoutType: layoutType) * 0.66

        // Layout

        let frameView = {
            $0.contentMode = .center
            $0.tintColor = roomColor
            return $0
        }(UIImageView(image: frameRoomTemplateImage.withRenderingMode(.alwaysTemplate)))

        imageView.removeConstraints(imageView.constraints)

        frameView.anchor(
            widthConstant: roomIconSize.width,
            heightConstant: roomIconSize.height
        )

        imageView.anchor(
            widthConstant: roomIconSize.width - iconRoomTemplateOffset * 2,
            heightConstant: roomIconSize.height - iconRoomTemplateOffset * 2
        )

        let parentView = UIView()

        parentView.addSubview(imageView)
        imageView.anchorCenterSuperview()

        parentView.insertSubview(frameView, at: 0)
        frameView.fillToSuperview()

        if badgeImageView.image != nil {
            parentView.addSubview(badgeImageView)
            badgeImageView.anchor(
                bottom: parentView.bottomAnchor,
                trailing: parentView.trailingAnchor,
                padding: badgeInsets
            )
        }

        parentView.addSubview(activityIndicator)
        activityIndicator.anchorCenterSuperview()

        return parentView
    }

    // MARK: - Handlers

    private func roomImageDefault() -> UIImage? {
        guard let folder = entity as? ASCFolder else { return UIImage() }
        return folder.defaultRoomImage(layoutType: layoutType)
    }

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

// MARK: - List Layout

extension ASCFolderViewCell {
    private func buildListView() -> UIView {
        guard let folder = entity as? ASCFolder else { return UIView() }

        let containerView = UIView()

        var items = [UIView]()

        // Checkmark
        checkmarkView.removeConstraints(checkmarkView.constraints)
        checkmarkView.anchor(widthConstant: Constants.checkmarkSize)
        displayCheckmark(show: configurationState.isEditing)

        // Icon
        let iconView = buildIconView(preferredSize: iconSize)

        // Info
        let middleStackView = {
            $0.axis = .vertical
            $0.spacing = 1
            return $0
        }(UIStackView(arrangedSubviews: [buildListTitleView()]))

        if let ownerView = buildOwnerView() {
            middleStackView.addArrangedSubview(ownerView)
        }

        var dateStackItems = [UIView]()

        // VDR index
        if let order = folder.order {
            dateStackItems.append(buildCaption1ScondaryLabel(
                [
                    NSLocalizedString("Index", comment: "Folder order"),
                    order,
                ].joined(separator: " ")
            ))
            dateStackItems.append(buildCaption1ScondaryLabel("|"))
        }

        // Right info
        dateRightLabel.text = nil
        if let createdDate = folder.created {
            dateStackItems.append(
                buildCaption1ScondaryLabel(isCompact
                    ? dateFormatter.string(from: createdDate)
                    : nil
                )
            )

            dateRightLabel.text = dateTimeFormatter.string(from: createdDate)
        }

        dateStackItems.append(.spacer)

        if !dateStackItems.isEmpty {
            middleStackView.addArrangedSubview({
                $0.axis = .horizontal
                $0.alignment = .fill
                $0.distribution = .fill
                $0.spacing = 4
                return $0
            }(UIStackView(arrangedSubviews: dateStackItems)))
        }

        displayRightInfo(show: !isCompact)

        items.append(checkmarkView)
        items.append(iconView)
        items.append(middleStackView)
        items.append(dateRightLabel)

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
        } else {
            items.append({
                $0.contentMode = .center
                $0.anchor(widthConstant: 20)
                return $0
            }(UIImageView(image: UIImage(
                systemName: "chevron.forward",
                withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 12, weight: .medium))
            )?.withTintColor(.separator, renderingMode: .alwaysOriginal) ?? UIImage())))
        }

        let contentView = {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.distribution = .fill
            $0.spacing = 10
            return $0
        }(UIStackView(arrangedSubviews: items))

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

    private func buildListTitleView() -> UIView {
        guard let folder = entity as? ASCFolder else { return UIView() }

        var items: [UIView] = [titleLabel]

        titleLabel.text = folder.title

        if folder.shared, !folder.isRoom {
            items.append({
                $0.contentMode = .center
                return $0
            }(sharedBadge))
        }

        if folder.pinned {
            items.append({
                $0.contentMode = .center
                return $0
            }(UIImageView(image: Asset.Images.pin.image)))
        }

        if let _ = folder.isFavorite, !folder.isRoom {
            items.append({
                $0.contentMode = .center
                return $0
            }(UIImageView(image: Asset.Images.listFavoritesSmall.image)))
        }

        items.append(UIView(frame: CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: 0))))

        return {
            $0.axis = .horizontal
            $0.spacing = 2
            return $0
        }(UIStackView(arrangedSubviews: items))
    }

    private func buildOwnerView() -> UIView? {
        guard let folder = entity as? ASCFolder else { return nil }
        let roomTypeDescription = folder.roomType?.description

        authorLabel.text = [
            roomTypeDescription,
            folder.createdBy?.displayName,
            folder.originRoomTitle
        ]
            .compactMap {
                guard let str = $0?.trimmed.truncated(toLength: 25), !str.isEmpty else { return nil }
                return str
            }
            .joined(separator: " • ")

        if authorLabel.text?.isEmpty == true {
            return nil
        }

        return authorLabel
    }

    private func buildCaption1ScondaryLabel(_ text: String?) -> UILabel {
        return {
            $0.font = UIFont.preferredFont(forTextStyle: .caption1)
            $0.textColor = .secondaryLabel
            $0.text = text
            return $0
        }(UILabel())
    }
}

// MARK: - Grid Layout

private extension ASCFolderViewCell {
    func buildGridView() -> UIView {
        guard let folder = entity as? ASCFolder else { return UIView() }

        let iconView = buildIconView(preferredSize: iconSize)

        let titleLabel = {
            $0.font = UIFont.preferredFont(forTextStyle: .subheadline)
            $0.textAlignment = .center
            $0.numberOfLines = 2
            $0.textColor = .label
            $0.text = folder.title
            return $0
        }(UILabel())

        let subtitle: String? = folder.isRoom
            ? folder.roomType?.description
            : dateFormatter.string(from: folder.updated ?? Date())
        let subtitleLabel = {
            $0.font = UIFont.preferredFont(forTextStyle: .caption2)
            $0.textAlignment = .center
            $0.numberOfLines = 1
            $0.textColor = .secondaryLabel
            $0.text = subtitle
            return $0
        }(UILabel())

        // Overlay markers
        var overlays: [UIView] = []

        if folder.shared, !folder.isRoom {
            overlays.append(buildSymbolBadge(imageView: sharedBadge))
        }

        if folder.pinned {
            overlays.append(buildSymbolBadge(imageView: UIImageView(image: Asset.Images.listPinSmall.image)))
        }

        if let _ = folder.isFavorite, !folder.isRoom {
            overlays.append(buildSymbolBadge(imageView: UIImageView(image: Asset.Images.listFavoritesSmall.image)))
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
            subtitleLabel,
            UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 100))),
        ]))

        let containerView = UIView()

        containerView.addSubview(contentView)
        contentView.fillToSuperview()

        containerView.addSubview(overlayView)
        overlayView.anchor(
            top: contentView.topAnchor,
            leading: contentView.leadingAnchor,
            padding: UIEdgeInsets(top: 4, left: 8, bottom: 0, right: 0)
        )

        checkmarkView.removeConstraints(checkmarkView.constraints)
        containerView.addSubview(checkmarkView)
        checkmarkView.anchor(
            top: containerView.topAnchor,
            trailing: containerView.trailingAnchor,
            padding: UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8),
            size: CGSize(width: Constants.checkmarkSize, height: Constants.checkmarkSize)
        )
        displayCheckmark(show: configurationState.isEditing)

        return containerView
    }

    private func buildSymbolBadge(
        imageView: UIImageView,
        tint: UIColor = Asset.Colors.brend.color,
        pointSize: CGFloat = Badge.pointSize,
        weight: UIFont.Weight = .black,
        padding: CGFloat = Badge.padding,
        bgColor: UIColor = .systemBackground,
        borderColor: UIColor? = nil,
        borderWidth: CGFloat = 0
    ) -> UIView {
        imageView.contentMode = UIView.ContentMode.center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

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

extension ASCFolderViewCell {
    private var cornerRadius: CGFloat {
        layoutType == .grid ? Constants.gridCornerRadius : Constants.listCornerRadius
    }

    private var iconSize: CGSize {
        layoutType == .grid ? Constants.gridIconSize : Constants.listIconSize
    }

    private var iconFolder: UIImage {
        layoutType == .list ? Asset.Images.listFolder.image : Asset.Images.gridFolder.image
    }

    private var iconFolderBoxnet: UIImage {
        layoutType == .list ? Asset.Images.listFolderBox.image : Asset.Images.gridFolderBox.image
    }

    private var iconFolderDropbox: UIImage {
        layoutType == .list ? Asset.Images.listFolderDropbox.image : Asset.Images.gridFolderDropbox.image
    }

    private var iconFolderGoogledrive: UIImage {
        layoutType == .list ? Asset.Images.listFolderGoogledrive.image : Asset.Images.gridFolderGoogledrive.image
    }

    private var iconFolderOnedrive: UIImage {
        layoutType == .list ? Asset.Images.listFolderOnedrive.image : Asset.Images.gridFolderOnedrive.image
    }

    private var iconFolderWebdav: UIImage {
        layoutType == .list ? Asset.Images.listFolderWebdav.image : Asset.Images.gridFolderWebdav.image
    }

    private var iconFolderYandexdisk: UIImage {
        layoutType == .list ? Asset.Images.listFolderYandexdisk.image : Asset.Images.gridFolderYandexdisk.image
    }

    private var iconFolderKdrive: UIImage {
        layoutType == .list ? Asset.Images.listFolderKdrive.image : Asset.Images.gridFolderKdrive.image
    }

    private var iconWorld: UIImage {
        layoutType == .list ? Asset.Images.world.image : Asset.Images.worldLarge.image
    }

    private var iconSecurity: UIImage {
        layoutType == .list ? Asset.Images.security.image : Asset.Images.securityLarge.image
    }

    private var iconFillFormRoomFolderInProgress: UIImage {
        layoutType == .list ? Asset.Images.listRoomInprogress.image : Asset.Images.gridRoomInprogress.image
    }

    private var iconFillFormRoomFolderDone: UIImage {
        layoutType == .list ? Asset.Images.listRoomComplete.image : Asset.Images.gridRoomComplete.image
    }

    private var iconRoomTemplateOffset: CGFloat {
        layoutType == .list ? Constants.listIconRoomTemplateOffset : Constants.gridIconRoomTemplateOffset
    }

    private var frameRoomTemplateImage: UIImage {
        layoutType == .list ? ASCFolderViewCell.listRoomTemplateFrameImage : ASCFolderViewCell.gridRoomTemplateFrameImage
    }
}

private enum Constants {
    static let transformWidth: CGFloat = 450
    static let checkmarkSize: CGFloat = 16
    static let gridCornerRadius: CGFloat = 12
    static let listCornerRadius: CGFloat = 0
    static let overlayBagesFontSize: CGFloat = 13
    static let listIconSize = CGSize(width: 45, height: 50)
    static let gridIconSize = CGSize(width: 80, height: 80)
    static let listIconRadius: CGFloat = 8
    static let listIconRoomTemplateOffset: CGFloat = 6
    static let gridIconRoomTemplateOffset: CGFloat = 10
}

extension UIImage {
    /// Creates a frame texture with rounded corners and semi-spherical ends
    /// - Parameters:
    ///   - size: The size of the resulting texture
    ///   - cornerRadius: The radius of the corners
    ///   - lineWidth: The thickness of the frame lines
    ///   - gapBetweenCorners: The distance between corners (length of the gap)
    ///   - color: The color of the frame
    /// - Returns: UIImage containing the frame texture
    static func createFrameTexture(size: CGSize,
                                   cornerRadius: CGFloat,
                                   lineWidth: CGFloat,
                                   gapBetweenCorners: CGFloat,
                                   color: UIColor = .black) -> UIImage
    {
        // Create a context to draw into
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }

        // Set up drawing parameters
        context.setLineWidth(lineWidth * 2)
        context.setStrokeColor(color.cgColor)
        context.setLineCap(.round)

        // Calculate inner rectangle that accounts for the line width
        let insetRect = CGRect(x: 0,
                               y: 0,
                               width: size.width,
                               height: size.height)

        // Path of mask
        let clipPath = UIBezierPath(roundedRect: insetRect, cornerRadius: cornerRadius).cgPath
        context.addPath(clipPath)
        context.closePath()
        context.clip()

        // Calculate the length of each side minus corners and gaps
        let horizontalSideLength = max(0, (insetRect.width - 2 * cornerRadius - gapBetweenCorners) / 2)
        let verticalSideLength = max(0, (insetRect.height - 2 * cornerRadius - gapBetweenCorners) / 2)

        // Top-left corner
        context.move(to: CGPoint(x: insetRect.minX + cornerRadius, y: insetRect.minY))
        context.addArc(tangent1End: CGPoint(x: insetRect.minX, y: insetRect.minY),
                       tangent2End: CGPoint(x: insetRect.minX, y: insetRect.minY + cornerRadius),
                       radius: cornerRadius)

        // Left vertical line after top-left corner
        context.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY + cornerRadius + verticalSideLength))
        context.strokePath()

        // Top horizontal line after top-left corner
        context.move(to: CGPoint(x: insetRect.minX + cornerRadius, y: insetRect.minY))
        context.addLine(to: CGPoint(x: insetRect.minX + cornerRadius + horizontalSideLength, y: insetRect.minY))
        context.strokePath()

        // Top-right corner
        context.move(to: CGPoint(x: insetRect.maxX - cornerRadius, y: insetRect.minY))
        context.addArc(tangent1End: CGPoint(x: insetRect.maxX, y: insetRect.minY),
                       tangent2End: CGPoint(x: insetRect.maxX, y: insetRect.minY + cornerRadius),
                       radius: cornerRadius)

        // Right vertical line after top-right corner
        context.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.minY + cornerRadius + verticalSideLength))
        context.strokePath()

        // Top horizontal line before top-right corner
        context.move(to: CGPoint(x: insetRect.maxX - cornerRadius, y: insetRect.minY))
        context.addLine(to: CGPoint(x: insetRect.maxX - cornerRadius - horizontalSideLength, y: insetRect.minY))
        context.strokePath()

        // Bottom-left corner
        context.move(to: CGPoint(x: insetRect.minX, y: insetRect.maxY - cornerRadius))
        context.addArc(tangent1End: CGPoint(x: insetRect.minX, y: insetRect.maxY),
                       tangent2End: CGPoint(x: insetRect.minX + cornerRadius, y: insetRect.maxY),
                       radius: cornerRadius)

        // Left vertical line before bottom-left corner
        context.move(to: CGPoint(x: insetRect.minX, y: insetRect.maxY - cornerRadius))
        context.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY - cornerRadius - verticalSideLength))
        context.strokePath()

        // Bottom horizontal line after bottom-left corner
        context.move(to: CGPoint(x: insetRect.minX + cornerRadius, y: insetRect.maxY))
        context.addLine(to: CGPoint(x: insetRect.minX + cornerRadius + horizontalSideLength, y: insetRect.maxY))
        context.strokePath()

        // Bottom-right corner
        context.move(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - cornerRadius))
        context.addArc(tangent1End: CGPoint(x: insetRect.maxX, y: insetRect.maxY),
                       tangent2End: CGPoint(x: insetRect.maxX - cornerRadius, y: insetRect.maxY),
                       radius: cornerRadius)

        // Right vertical line before bottom-right corner
        context.move(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - cornerRadius))
        context.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - cornerRadius - verticalSideLength))
        context.strokePath()

        // Bottom horizontal line before bottom-right corner
        context.move(to: CGPoint(x: insetRect.maxX - cornerRadius, y: insetRect.maxY))
        context.addLine(to: CGPoint(x: insetRect.maxX - cornerRadius - horizontalSideLength, y: insetRect.maxY))
        context.strokePath()

        // Get the image from the context
        let resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()

        return resultImage
    }
}

@available(iOS 17, *)
#Preview {
    ASCFolderViewCell().buildRoomTemplateIconView(preferredSize: Constants.gridIconSize)
}
