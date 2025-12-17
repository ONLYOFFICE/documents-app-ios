//
//  ASCDocumentsViewController+NavBar.swift
//  Documents
//
//  Created by Pavel Chernyshev on 25.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import UIKit

extension ASCDocumentsViewController {
    // Sort
    private var defaultsSortTypes: [ASCDocumentSortType] {
        [.dateandtime, .az, .type, .size]
    }

    // MARK: Configure

    func configureNavigationItem() {
        if displaySegmentTabs {
            let appearance = UINavigationBarAppearance()
            if navigationBarExtendPanelView.isHidden {
                appearance.configureWithDefaultBackground()
            } else {
                appearance.configureWithTransparentBackground()
            }
            navigationItem.compactAppearance = appearance
            navigationItem.standardAppearance = appearance
            navigationItem.scrollEdgeAppearance = appearance
            if #available(iOS 15.0, *) {
                navigationItem.compactScrollEdgeAppearance = appearance
            }
        }
    }

    func configureNavigationBar(animated: Bool = true) {
        addBarButton = addBarButton
            ?? createAddBarButton()
        sortSelectBarButton = sortSelectBarButton
            ?? createSortSelectBarButton()
        sortBarButton = sortBarButton
            ?? createSortBarButton()
        filterBarButton = createFilterBarButton()
        selectBarButton = selectBarButton
            ?? ASCStyles.createBarButton(image: Asset.Images.navSelect.image, target: self, action: #selector(onSelectAction))
        cancelBarButton = cancelBarButton
            ?? ASCStyles.createBarButton(title: ASCLocalization.Common.cancel, target: self, action: #selector(onCancelAction))
        selectAllBarButton = selectAllBarButton
            ?? ASCStyles.createBarButton(title: NSLocalizedString("Select", comment: "Button title"), target: self, action: #selector(onSelectAll))
        reorderIndexButton = reorderIndexButton ?? ASCStyles.createBarButton(title: NSLocalizedString("Reorder", comment: "Button title"), target: self, action: #selector(onReorderAction))
        if let folder = folder,
           !folder.isRoom
        {
            sortSelectBarButton?.isEnabled = total > 0
        }
        sortBarButton?.isEnabled = total > 0
        selectBarButton?.isEnabled = total > 0
        selectAllBarButton?.isEnabled = total > 0
        filterBarButton?.isEnabled = total > 0 || provider?.filterController?.isReset == false

        if #available(iOS 14.0, *) {
            for barButton in [sortSelectBarButton, sortBarButton] {
                if let button = barButton?.customView as? UIButton {
                    button.showsMenuAsPrimaryAction = true
                    button.menu = currentFolderActionMenu(for: button)
                }
            }

            selectAllBarButton = ASCStyles.createBarButton(title: NSLocalizedString("Select", comment: "Button title"), menu: selectAllMenu())
        }

        if isEditingIndexMode {
            navigationItem.setLeftBarButtonItems([reorderIndexButton!], animated: animated)
            navigationItem.setRightBarButtonItems([cancelBarButton!], animated: animated)
        } else if collectionView.isEditing {
            navigationItem.setLeftBarButtonItems([selectAllBarButton!], animated: animated)
            navigationItem.setRightBarButtonItems([cancelBarButton!], animated: animated)
        } else {
            navigationItem.setLeftBarButtonItems(nil, animated: animated)

            var rightBarBtnItems = [ASCStyles.barFixedSpace]

            if let sortSelectBarBtn = sortSelectBarButton {
                rightBarBtnItems.append(sortSelectBarBtn)
            }

            if let filterBarBtn = filterBarButton, provider?.filterController != nil {
                rightBarBtnItems.append(filterBarBtn)
            }

            if let addBarBtn = addBarButton {
                rightBarBtnItems.append(addBarBtn)
            }

            navigationItem.setRightBarButtonItems(rightBarBtnItems, animated: animated)
        }

        navigationController?.navigationBar.prefersLargeTitles = ASCAppSettings.Feature.allowLargeTitle
        navigationItem.largeTitleDisplayMode = .automatic
        updateTitle()
    }

    // MARK: Update nav bar

    func updateNavBar() {
        guard let folder else { return }

        let hasError = errorView?.superview != nil

        addBarButton?.isEnabled = !hasError && provider?.allowAdd(toFolder: folder) ?? false
        sortSelectBarButton?.isEnabled = !hasError && (folder.isRoom || total > 0)
        sortBarButton?.isEnabled = !hasError && total > 0
        selectBarButton?.isEnabled = !hasError && total > 0
        filterBarButton?.isEnabled = !hasError && total > 0

        configureNavigationBar(animated: false)
    }
}

// MARK: - NavBar Title

extension ASCDocumentsViewController {
    func updateTitle() {
        if !collectionView.isEditing {
            title = provider?.title(for: folder)
        } else {
            updateSelectedInfo()
        }

        setTitleBadgeIfNeeded()
    }

    func setTitleBadgeIfNeeded() {
        if let folder, !folder.isTemplateRoom {
            return
        }

        if !collectionView.isEditing {
            let templateBadgeView: (() -> ASCPaddingLabel) = {
                let badgeLabel = ASCPaddingLabel()
                badgeLabel.text = NSLocalizedString("Template", comment: "")
                badgeLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
                badgeLabel.textColor = .white
                badgeLabel.backgroundColor = .systemGray
                badgeLabel.layer.cornerRadius = 10
                badgeLabel.layer.masksToBounds = true
                badgeLabel.padding = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
                badgeLabel.textAlignment = .center
                badgeLabel.setContentHuggingPriority(.required, for: .horizontal)
                badgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
                badgeLabel.heightAnchor.constraint(equalToConstant: 22).isActive = true
                return badgeLabel
            }

            titleBadgeView = (
                large: templateBadgeView(),
                inline: {
                    $0.padding = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
                    $0.layer.cornerRadius = 8
                    $0.heightAnchor.constraint(equalToConstant: 17).isActive = true
                    return $0
                }(templateBadgeView())
            )
        } else {
            titleBadgeView = nil
        }
    }

    func updateSelectedInfo() {
        let fileCount = tableData
            .filter { $0 is ASCFile }
            .filter { selectedIds.contains($0.uid) }
            .count
        let folderCount = tableData
            .filter { $0 is ASCFolder }
            .filter { selectedIds.contains($0.uid) }
            .count
        let roomsCount = tableData
            .filter { $0 is ASCFolder }
            .filter { selectedIds.contains($0.uid) }
            .filter { $0.isRoom }
            .count

        if fileCount + folderCount > 0 {
            if UIDevice.phone {
                title = String(format: NSLocalizedString("Selected: %ld", comment: ""), fileCount + folderCount)
            } else {
                if roomsCount > 0 {
                    title = String(format: NSLocalizedString("Selected: %ld", comment: ""), roomsCount)
                } else if folderCount > 0, fileCount > 0 {
                    title = String.localizedStringWithFormat(NSLocalizedString("%lu Folder and %lu File selected", comment: ""), folderCount, fileCount)
                } else if folderCount > 0 {
                    title = String.localizedStringWithFormat(NSLocalizedString("%lu Folder selected", comment: ""), folderCount)
                } else if fileCount > 0 {
                    title = String.localizedStringWithFormat(NSLocalizedString("%lu File selected", comment: ""), fileCount)
                } else {
                    title = folder?.title
                }
            }
        } else {
            title = provider?.title(for: folder)
        }
    }
}

// MARK: - NavBar menu actions

extension ASCDocumentsViewController {
    // MARK: Select All

    func selectAllMenu() -> UIMenu? {
        let uiActions: [UIAction] = {
            var uiActions = [UIAction]()
            uiActions.append(UIAction(
                title: NSLocalizedString("All", comment: ""),
                image: UIImage(systemName: "checkmark.circle"),
                handler: { [weak self] action in
                    self?.selectAllItems(type: AnyObject.self)
                }
            ))

            provider?.contentTypes.forEach { contentType in
                switch contentType {
                case .files:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Files", comment: ""),
                        image: Asset.Images.menuFiles.image,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFile.self)
                        }
                    ))
                case .folders:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Folders", comment: ""),
                        image: UIImage(systemName: "folder"),
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self)
                        }
                    ))
                case .documents:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Documents", comment: ""),
                        image: Asset.Images.menuDocuments.image,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.documents)
                        }
                    ))
                case .spreadsheets:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Spreadsheets", comment: ""),
                        image: Asset.Images.menuSpreadsheet.image,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.spreadsheets)
                        }
                    ))
                case .presentations:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Presentations", comment: ""),
                        image: Asset.Images.menuPresentation.image,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.presentations)
                        }
                    ))
                case .images:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Images", comment: ""),
                        image: UIImage(systemName: "photo"),
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.images)
                        }
                    ))
                case .public:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Public", comment: ""),
                        image: nil,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self, roomTypes: [.public])
                        }
                    ))
                case .collaboration:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Collaboration", comment: ""),
                        image: nil,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self, roomTypes: [.colobaration])
                        }
                    ))
                case .custom:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Custom", comment: ""),
                        image: nil,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self, roomTypes: [.custom])
                        }
                    ))
                case .viewOnly:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("View-only", comment: ""),
                        image: nil,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self, roomTypes: [.viewOnly])
                        }
                    ))
                case .fillingForms:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Filling form", comment: ""),
                        image: nil,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self, roomTypes: [.fillingForm])
                        }
                    ))
                }
            }

            return uiActions
        }()

        return UIMenu(title: "", options: .displayInline, children: uiActions)
    }

    private func selectAllItems<T>(type: T.Type, extensions: [String]? = nil, roomTypes: [ASCRoomType]? = nil) {
        if type == ASCFile.self {
            var files: [ASCEntity] = []
            if let extensions = extensions {
                files = tableData.filter { $0 is ASCFile && extensions.contains(($0 as? ASCFile)?.title.fileExtension().lowercased() ?? "") }
            } else {
                files = tableData.filter { $0 is ASCFile }
            }
            let selectedFiles = files.filter { selectedIds.contains($0.uid) }
            selectedIds = (
                (selectedFiles.count == selectedIds.count)
                    && (selectedFiles.count == files.count)
                    && selectedFiles.count > 0)
                ? []
                : Set(files.map { $0.uid }
                )
        } else if type == ASCFolder.self {
            let folders = tableData.filter {
                guard let folder = $0 as? ASCFolder else { return false }
                guard let roomTypes = roomTypes, let roomType = folder.roomType else {
                    return $0 is ASCFolder
                }
                return roomTypes.contains(roomType)
            }
            let selectedFolders = folders.filter { selectedIds.contains($0.uid) }
            selectedIds = (
                (selectedFolders.count == selectedIds.count)
                    && (selectedFolders.count == folders.count)
                    && selectedFolders.count > 0)
                ? []
                : Set(folders.map { $0.uid }
                )
        } else {
            selectedIds = selectedIds.count == tableData.count
                ? []
                : Set(tableData.map { $0.uid })
        }

        updateSelectedInfo()
        collectionView.reloadSections(IndexSet(integer: 0))
        events.trigger(eventName: "item:didSelect")
    }

    @objc func onSelectAll(_ sender: Any) {
        let selectController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )

        selectController.addAction(UIAlertAction(title: NSLocalizedString("All", comment: ""), handler: { [weak self] action in
            self?.selectAllItems(type: AnyObject.self)
        }))

        provider?.contentTypes.forEach { contentType in
            switch contentType {
            case .files:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Files", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFile.self)
                }))
            case .folders:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Folders", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self)
                }))
            case .documents:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Documents", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.documents)
                }))
            case .spreadsheets:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Spreadsheets", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.spreadsheets)
                }))
            case .presentations:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Presentations", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.presentations)
                }))
            case .images:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Images", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.images)
                }))
            case .public:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Public", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self, roomTypes: [.public])
                }))
            case .collaboration:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Collaboration", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self, roomTypes: [.colobaration])
                }))
            case .custom:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Custom", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self, roomTypes: [.custom])
                }))
            case .viewOnly:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("View-only", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self, roomTypes: [.viewOnly])
                }))
            case .fillingForms:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Filling form", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self, roomTypes: [.fillingForm])
                }))
            }
        }

        selectController.addAction(UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel, handler: nil))

        if UIDevice.pad {
            selectController.modalPresentationStyle = .popover

            if let barButtonItem = sender as? UIBarButtonItem {
                selectController.popoverPresentationController?.barButtonItem = barButtonItem
            }
        }

        present(selectController, animated: true, completion: nil)
    }
}

// MARK: - Objc func actions

extension ASCDocumentsViewController {
    @objc func onFilterAction() {
        let providerCopy = provider?.copy()
        provider?.filterController?.folder = folder
        provider?.filterController?.provider = providerCopy
        provider?.filterController?.onAction = { [weak self] in
            self?.loadFirstPage()
            self?.configureNavigationBar(animated: false)
        }
        provider?.filterController?.prepareForDisplay(total: total)

        if let filtersViewController = provider?.filterController?.filtersViewController {
            let navigationVC = UINavigationController(rootASCViewController: filtersViewController)

            if UIDevice.pad {
                navigationVC.preferredContentSize = CGSize(width: 380, height: 714)
                navigationVC.modalPresentationStyle = .popover
                navigationVC.popoverPresentationController?.barButtonItem = filterBarButton
                present(navigationVC, animated: true) {}
            } else {
                navigationController?.present(navigationVC, animated: true)
            }
        }
    }

    @objc func onAddEntityAction() {
        guard let provider = provider else { return }
        flashBlockInteration()
        ASCCreateEntity().showCreateController(for: provider, in: self, sender: addBarButton)
    }

    @objc func onActionSelect(_ sender: Any) {
        if #available(iOS 14.0, *) {
            if let button = sender as? UIButton {
                button.showsMenuAsPrimaryAction = true
                button.menu = currentFolderActionMenu(for: button)
            }
        } else {
            guard let folder, let sender = sender as? UIView else { return }
            let actionSheet = CurrentFolderMenu().actionSheet(for: folder, sender: sender, in: self)
            present(actionSheet, animated: true, completion: nil)
        }
    }

    @objc func onCancelAction() {
        if isEditingIndexMode {
            let continueAction = UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default) { [weak self] _ in
                guard let self else { return }
                self.cancelEditOrderIndex()
            }

            UIAlertController.showCancelableWarning(in: self, message: NSLocalizedString("Exit without saving? You have made changes in the index. If you proceed without saving, those changes will not be applied.", comment: ""), actions: [continueAction])
        } else {
            setEditMode(false)
        }
    }

    @objc func onSortAction(_ sender: Any) {
        if #available(iOS 14.0, *) {
            if let button = sender as? UIButton {
                button.showsMenuAsPrimaryAction = true
                button.menu = currentFolderActionMenu(for: button)
            }
        } else {
            var sortType: ASCDocumentSortType = .dateandtime
            var sortAscending = false
            var sortStates: [ASCDocumentSortStateType] = defaultsSortTypes.map { ($0, $0 == sortType) }

            if let sortInfo = UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any] {
                if let sortBy = sortInfo["type"] as? String, !sortBy.isEmpty {
                    sortType = ASCDocumentSortType(sortBy)
                    sortStates = defaultsSortTypes.map { ($0, $0 == sortType) }
                }

                if let sortOrder = sortInfo["order"] as? String, !sortOrder.isEmpty {
                    sortAscending = sortOrder == "ascending"
                }
            }

            if ![.deviceDocuments, .deviceTrash].contains(folder?.rootFolderType) {
                sortStates.append((.author, sortType == .author))
            }

            navigator.navigate(to: .sort(types: sortStates, ascending: sortAscending, complation: { type, ascending in
                if (sortType != type) || (ascending != sortAscending) {
                    let sortInfo = [
                        "type": type.rawValue,
                        "order": ascending ? "ascending" : "descending",
                    ]

                    UserDefaults.standard.set(sortInfo, forKey: ASCConstants.SettingsKeys.sortDocuments)
                }
            }))
        }
    }

    @objc func onSelectAction() {
        guard view.isUserInteractionEnabled else { return }
        setEditMode(true)
        flashBlockInteration()
    }

    @objc func onReorderAction() {
        let reorderAction = UIAlertAction(title: NSLocalizedString("Reorder", comment: ""), style: .default) { [weak self] _ in
            guard let self else { return }
            self.reoreder()
        }

        UIAlertController.showCancelableWarning(in: self, message: NSLocalizedString("The Reorder action will remove spaces in the indexes. The files will be re-indexed in order with offset to fill in missing indexes.", comment: ""), actions: [reorderAction])
    }
}

// MARK: - Private

private extension ASCDocumentsViewController {
    func reoreder() {
        guard let folder else { return }
        let hud = MBProgressHUD.showTopMost()
        provider?.handle(
            action: .reorderIndex,
            folder: folder
        ) { [weak self] status, result, error in
            guard let self else {
                hud?.hide(animated: false)
                return
            }
            switch status {
            case .begin, .progress:
                break
            case .end:
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: .standardDelay)
                setEditMode(false)
                loadFirstPage()
            case .error:
                hud?.setState(result: .failure(error?.localizedDescription))
                hud?.hide(animated: true, afterDelay: .standardDelay)
                setEditMode(false)
            }
        }
    }

    func cancelEditOrderIndex() {
        if isEditingIndexMode, let editOrderDelegate = provider as? ProviderEditIndexDelegate {
            editOrderDelegate.cancleEditOrderIndex()
        }
        isEditingIndexMode = false
        collectionView.reloadData()
        setEditMode(false)
    }

    func createAddBarButton() -> UIBarButtonItem? {
        guard (provider?.allowAdd(toFolder: folder)) != nil, folder?.rootFolderType != .archive else { return nil }

        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)

        let icon: UIImage? = {
            guard folder?.isRoomListFolder == true else {
                return UIImage(systemName: "plus", withConfiguration: config)
            }
            return Asset.Images.barRectanglesAdd.image
        }()

        return ASCStyles.createBarButton(
            image: icon,
            target: self,
            action: #selector(onAddEntityAction)
        )
    }

    func createFilterBarButton() -> UIBarButtonItem {
        let isReset = provider?.filterController?.isReset ?? true

        return ASCStyles.createBarButton(
            image: isReset ? Asset.Images.barFilter.image : Asset.Images.barFilterOn.image,
            target: self,
            action: #selector(onFilterAction)
        )
    }

    func createSortSelectBarButton() -> UIBarButtonItem {
        guard categoryIsRecent else {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)

            return ASCStyles.createBarButton(
                image: UIImage(systemName: "ellipsis.circle", withConfiguration: config),
                target: self,
                action: #selector(onActionSelect)
            )
        }

        return ASCStyles.createBarButton(
            title: NSLocalizedString("Select", comment: "Navigation bar button title"),
            target: self,
            action: #selector(onSelectAction)
        )
    }

    func createSortBarButton() -> UIBarButtonItem? {
        guard !categoryIsRecent else {
            return nil
        }

        return ASCStyles.createBarButton(image: Asset.Images.navSort.image, target: self, action: #selector(onSortAction))
    }
}

// MARK: - Title

@MainActor
extension ASCDocumentsViewController {
    @MainActor
    private struct AssociatedKeys {
        static var largeTitleBadgeViewId: Int = 0
        static var titleBadgeViewId: Int = 1
        static var largeTitleLabelId: Int = 2
    }

    public var titleBadgeView: (large: UIView, inline: UIView)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.titleBadgeViewId) as? (large: UIView, inline: UIView)
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.titleBadgeViewId, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            updateTitleView(collectionView)
        }
    }

    private var largeTitleBadgeView: UIView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.largeTitleBadgeViewId) as? UIView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.largeTitleBadgeViewId, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private weak var largeTitleLabel: UIView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.largeTitleLabelId) as? UIView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.largeTitleLabelId, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func findLargeTitleLabel(in view: UIView?) -> UILabel? {
        guard let view else { return nil }

        for subview in view.subviews {
            if let label = subview as? UILabel, label.font.pointSize > 30 {
                return label
            }
            if let found = findLargeTitleLabel(in: subview) {
                return found
            }
        }
        return nil
    }

    private func addBadgeToLargeTitleView(view: UIView) {
        largeTitleBadgeView?.removeFromSuperview()

        guard
            let largeTitleLabel = findLargeTitleLabel(in: navigationController?.navigationBar),
            let largeTitleLabelParent = largeTitleLabel.superview
        else { return }

        self.largeTitleLabel = largeTitleLabel

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = largeTitleLabel.font
        titleLabel.lineBreakMode = .byTruncatingTail

        let badgeLabel = view

        let stackView = UIStackView(arrangedSubviews: [titleLabel, badgeLabel, UIView()])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        largeTitleLabel.alpha = 0
//        stackView.alpha = 0

        largeTitleLabelParent.addSubview(stackView)

//        let isViewPresented = collectionView.refreshControl != nil

//        UIView.animate(withDuration: isViewPresented ? 0 : 0.4, delay: isViewPresented ? 0 : 0.3, options: [.curveEaseIn]) {
//            largeTitleLabel.alpha = 0
//            stackView.alpha = 1
//        }

        largeTitleBadgeView = stackView

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: largeTitleLabelParent.leadingAnchor, constant: largeTitleLabel.x),
            stackView.trailingAnchor.constraint(equalTo: largeTitleLabelParent.safeAreaLayoutGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: largeTitleLabel.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: largeTitleLabel.bottomAnchor),
        ])
    }

    private func makeInlineTitleWithBadge(view: UIView) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.lineBreakMode = .byTruncatingTail

        let badgeLabel = view

        let stackView = UIStackView(arrangedSubviews: [titleLabel, badgeLabel])
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .center

        return stackView
    }

    func updateTitleView(_ scrollView: UIScrollView) {
        if let titleBadgeView {
            guard let navBar = navigationController?.navigationBar else { return }
            let navHeight = navBar.frame.height
            let threshold: CGFloat = 80

            largeTitleLabel?.alpha = 0

            if navHeight > threshold {
                if largeTitleBadgeView != nil { return }
                addBadgeToLargeTitleView(view: titleBadgeView.large)
                navigationItem.titleView = nil
            } else {
                largeTitleBadgeView?.removeFromSuperview()
                largeTitleBadgeView = nil
                if navigationItem.titleView != nil { return }
                navigationItem.titleView = makeInlineTitleWithBadge(view: titleBadgeView.inline)
            }
        } else {
            largeTitleBadgeView?.removeFromSuperview()
            largeTitleBadgeView = nil
            navigationItem.titleView = nil

            largeTitleLabel?.alpha = 1
        }
    }

    func cleanupTitleView() {
        largeTitleBadgeView?.removeFromSuperview()
        largeTitleBadgeView = nil
        largeTitleLabel?.alpha = 1
    }
}
