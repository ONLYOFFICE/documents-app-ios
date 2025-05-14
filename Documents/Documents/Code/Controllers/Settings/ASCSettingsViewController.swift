//
//  ASCSettingsViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.06.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import FileKit
import Kingfisher
import MBProgressHUD
import SDWebImage
import UIKit

class ASCSettingsViewController: ASCBaseTableViewController {
    // Section model

    struct SettingsSection {
        var items: [CellType]
        var header: String?
        var footer: String?

        init(items: [CellType], header: String? = nil, footer: String? = nil) {
            self.items = items
            self.header = header
            self.footer = footer
        }
    }

    // MARK: - Properties

    private var cacheSize: UInt64 = 0
    private var tableData: [SectionType] = []
    private var authorizationStatus: UNAuthorizationStatus = .authorized

    // MARK: - Lifecycle Methods

    init() {
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Settings", comment: "")

        configureTableView()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        build()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if UIDevice.pad {
            navigationController?.navigationBar.prefersLargeTitles = false

            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
        }

        build()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        calcCacheSize()

        checkNotifications { [weak self] authorizationStatus in
            self?.onCheckNotificationStatus(status: authorizationStatus)
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if UIDevice.pad {
            guard let navigationBar = navigationController?.navigationBar else { return }

            let transparent = (navigationBar.y + navigationBar.height + scrollView.contentOffset.y) > 0

            navigationBar.setBackgroundImage(transparent ? nil : UIImage(), for: .default)
            navigationBar.shadowImage = transparent ? nil : UIImage()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc func appWillEnterForeground() {
        checkNotifications { [weak self] authorizationStatus in
            self?.onCheckNotificationStatus(status: authorizationStatus)
        }
    }

    private func configureTableView() {
        view.backgroundColor = .systemGroupedBackground

        tableView.register(
            ASCSettingsNotificationCell.self,
            forCellReuseIdentifier: ASCSettingsNotificationCell.identifier
        )
    }

    private func build() {
        var data: [SectionType] = []

        // Settings and Security section
        let settingsSecuritySection = SettingsSection(
            items: [
                .notifications(
                    viewModel: ASCStandartCellViewModel(
                        title: NSLocalizedString("Notifications", comment: ""),
                        action: {
                            self.navigator.navigate(to: .notificationSettings)
                        },
                        accessoryType: .disclosureIndicator
                    ),
                    displayError: authorizationStatus != .authorized
                ),
                .detail(
                    viewModel: ASCDetailTabelViewCellViewModel(
                        title: NSLocalizedString("Theme", comment: ""),
                        detail: AppThemeService.theme.description,
                        accessoryType: .disclosureIndicator,
                        action: {
                            self.navigator.navigate(to: .themeOptions)
                        }
                    )
                ),
                .standart(
                    viewModel: ASCStandartCellViewModel(
                        title: NSLocalizedString("Passcode Lock", comment: ""),
                        action: {
                            self.navigator.navigate(to: .passcodeLockSettings)
                        },
                        accessoryType: .disclosureIndicator
                    )
                ),
            ],
            header: NSLocalizedString("Settings and Security", comment: "")
        )
        data.append(.standart(viewModel: settingsSecuritySection))

        // Storage section
        let storageSection = SettingsSection(
            items: [
                .cache(
                    viewModel: ASCStandartCellViewModel(
                        title: NSLocalizedString("Cache", comment: ""),
                        action: {
                            self.clearCache()
                        }
                    ),
                    processing: true,
                    detailText: nil
                ),
                .switchControl(viewModel: ASCSwitchCellViewModel(
                    title: NSLocalizedString("Files Preview", comment: ""),
                    isOn: ASCAppSettings.previewFiles,
                    valueChanged: { isOn in
                        ASCAppSettings.previewFiles = isOn
                        NotificationCenter.default.post(name: ASCConstants.Notifications.reloadData, object: nil)
                    }
                )),
                .switchControl(viewModel: ASCSwitchCellViewModel(
                    title: NSLocalizedString("Compress Images", comment: ""),
                    isOn: ASCAppSettings.compressImage,
                    valueChanged: { isOn in
                        ASCAppSettings.compressImage = isOn
                    }
                )),
            ],
            header: NSLocalizedString("Storage", comment: "")
        )
        data.append(.standart(viewModel: storageSection))

        // Information section
        let informationSection = SettingsSection(
            items: [
                .standart(viewModel: ASCStandartCellViewModel(
                    title: NSLocalizedString("About", comment: ""),
                    action: {
                        self.navigator.navigate(to: .about)
                    },
                    accessoryType: .disclosureIndicator
                )),
                .standart(viewModel: ASCStandartCellViewModel(
                    title: NSLocalizedString("Help & Feedback", comment: ""),
                    action: {
                        self.navigator.navigate(to: .helpAndFeedback)
                    },
                    accessoryType: .disclosureIndicator
                )),
            ],
            header: NSLocalizedString("Information", comment: "")
        )
        data.append(.standart(viewModel: informationSection))

        // Debug section
        if ASCDebugManager.shared.enabled {
            let debugSection = SettingsSection(
                items: [
                    .standart(viewModel: ASCStandartCellViewModel(
                        title: NSLocalizedString("Options", comment: ""),
                        action: {
                            self.navigator.navigate(to: .developerOptions)
                        },
                        accessoryType: .disclosureIndicator
                    )),
                    .standart(viewModel: ASCStandartCellViewModel(
                        title: NSLocalizedString("Console", comment: ""),
                        action: {
                            ASCDebugManager.shared.showDebugMenu()
                        },
                        accessoryType: .disclosureIndicator
                    )),
                ],
                header: "Developer menu"
            )
            data.append(.debug(viewModel: debugSection))
        }

        tableData = data
        tableView?.reloadData()
    }

    // MARK: - Private

    private func onCheckNotificationStatus(status: UNAuthorizationStatus) {
        authorizationStatus = status

        var notificationRowIndex: Int?

        if let sectionIndex = tableData.firstIndex(where: { section in
            if let rowIndex = section.toSection().items.firstIndex(where: { cell in
                guard case .notifications = cell else { return false }; return true
            }) {
                notificationRowIndex = rowIndex
                return true
            }
            return false
        }), let notificationRowIndex = notificationRowIndex {
            if let viewModel = tableData[sectionIndex].toSection().items[notificationRowIndex].viewModel() as? ASCStandartCellViewModel {
                var section = tableData[sectionIndex]
                var records = section.toSection().items

                records[notificationRowIndex] = .notifications(
                    viewModel: viewModel,
                    displayError: authorizationStatus != .authorized
                )

                section.viewModel = SettingsSection(
                    items: records,
                    header: section.viewModel.header,
                    footer: section.viewModel.footer
                )

                tableData[sectionIndex] = section
                tableView?.reloadRows(at: [IndexPath(row: notificationRowIndex, section: sectionIndex)], with: .none)
            }
        }
    }

    private func calcCacheSize() {
        // Search cache data model

        let updateCacheModel: (Bool, String?) -> Void = { [weak self] processing, detailText in
            guard let self = self else { return }

            var cacheRowIndex: Int?

            if let sectionIndex = self.tableData.firstIndex(where: { section in
                if let rowIndex = section.toSection().items.firstIndex(where: { cell in
                    guard case .cache = cell else { return false }; return true
                }) {
                    cacheRowIndex = rowIndex
                    return true
                }
                return false
            }), let rowIndex = cacheRowIndex {
                if let viewModel = self.tableData[sectionIndex].toSection().items[rowIndex].viewModel() as? ASCStandartCellViewModel {
                    var section = self.tableData[sectionIndex]
                    var records = section.toSection().items

                    records[rowIndex] = .cache(
                        viewModel: viewModel,
                        processing: processing,
                        detailText: detailText
                    )

                    section.viewModel = SettingsSection(
                        items: records,
                        header: section.viewModel.header,
                        footer: section.viewModel.footer
                    )

                    self.tableData[sectionIndex] = section
                    self.tableView?.reloadRows(at: [IndexPath(row: rowIndex, section: sectionIndex)], with: .none)
                }
            }
        }

        if cacheSize < 1 {
            updateCacheModel(true, "")
        } else {
            updateCacheModel(false, String.fileSizeToString(with: cacheSize))
        }

        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }

            var commonSize: UInt64 = 0

            for path in [Path.userTemporary, Path.userAutosavedInformation] {
                _ = path.find(searchDepth: 5) { path in
                    if path.isRegular {
                        commonSize += path.fileSize ?? 0
                    }

                    return path.isRegular
                }
            }

            strongSelf.cacheSize = commonSize

            ImageCache.default.calculateDiskStorageSize { [weak self] result in
                switch result {
                case let .success(size):
                    log.info("Disk cache size: \(String.fileSizeToString(with: UInt64(size)))")
                    guard let strongSelf = self else { return }

                    strongSelf.cacheSize += UInt64(size)

                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }

                        delay(seconds: 0.3) {
                            strongSelf.cacheSize += UInt64(SDImageCache.shared.totalDiskSize())
                            updateCacheModel(false, strongSelf.cacheSize < 1
                                ? NSLocalizedString("None", comment: "If the cache is empty")
                                : String.fileSizeToString(with: strongSelf.cacheSize))
                        }
                    }
                case let .failure(error):
                    print(error)
                    guard let strongSelf = self else { return }

                    strongSelf.cacheSize = 0
                    updateCacheModel(false, NSLocalizedString("None", comment: "If the cache is empty"))
                }
            }
        }
    }

    private func clearCache() {
        let alertController = UIAlertController(
            title: NSLocalizedString("Clear Cache?", comment: "Button title"),
            message: NSLocalizedString("This operation will free up space on your device by deleting temporary files. Your offline files and personal data won't be removed.", comment: ""),
            preferredStyle: UIDevice.pad ? .alert : .actionSheet,
            tintColor: nil
        )
        let deleteAction = UIAlertAction(title: NSLocalizedString("Clear Cache", comment: "Button title"), style: .destructive) { action in
            guard let hud = MBProgressHUD.showTopMost() else {
                return
            }

            hud.mode = .indeterminate
            hud.label.text = NSLocalizedString("Clearing", comment: "Caption of the processing")

            DispatchQueue.global().async { [weak self] in
                for path in [Path.userTemporary, Path.userAutosavedInformation] {
                    _ = path.find(searchDepth: 1) { path in
                        ASCLocalFileHelper.shared.removeFile(path)
                        return true
                    }
                }

                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }

                    // Clear avatar images
                    ImageCache.default.clearMemoryCache()
                    ImageCache.default.clearDiskCache()
                    ImageCache.default.cleanExpiredDiskCache()

                    // Clear images
                    SDImageCache.shared.clearMemory()
                    SDImageCache.shared.clearDisk()

                    // Clear categories
                    ASCOnlyofficeUserDefaultsCacheCategoriesProvider().clearCache()

                    hud.setSuccessState()
                    hud.hide(animated: true, afterDelay: .twoSecondsDelay)

                    strongSelf.calcCacheSize()
                }
            }
        }
        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel)

        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Table view data source

extension ASCSettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        tableData.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData[section].toSection().items.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellType(by: indexPath).toCell(tableView: tableView)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        tableData[section].toSection().header
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        tableData[section].toSection().footer
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch cellType(by: indexPath) {
        case let .standart(model),
             let .notifications(model, _),
             let .cache(model, _, _):
            model.action?()
        case let .detail(model):
            model.action?()
        default:
            break
        }
    }

    private func cellType(by indexPath: IndexPath) -> CellType {
        tableData[indexPath.section].toSection().items[indexPath.row]
    }
}

// MARK: - Cell types

extension ASCSettingsViewController {
    enum CellType {
        case standart(viewModel: ASCStandartCellViewModel)
        case detail(viewModel: ASCDetailTabelViewCellViewModel)
        case switchControl(viewModel: ASCSwitchCellViewModel)
        case cache(viewModel: ASCStandartCellViewModel, processing: Bool, detailText: String?)
        case notifications(viewModel: ASCStandartCellViewModel, displayError: Bool)

        public func viewModel() -> Any {
            switch self {
            case let .standart(viewModel):
                return viewModel
            case let .detail(viewModel):
                return viewModel
            case let .switchControl(viewModel):
                return viewModel
            case let .cache(viewModel, _, _):
                return viewModel
            case let .notifications(viewModel, _):
                return viewModel
            }
        }

        public func toCell(tableView: UITableView) -> UITableViewCell {
            switch self {
            case let .standart(viewModel):
                return makeStandartCell(viewModel, for: tableView) ?? makeDefaultCell()
            case let .detail(viewModel):
                return makeDetailCell(viewModel, for: tableView) ?? makeDefaultCell()
            case let .switchControl(viewModel):
                return makeSwitchCell(viewModel, for: tableView) ?? makeDefaultCell()
            case let .cache(viewModel, processing, detailText):
                return makeCacheCell(viewModel, processing: processing, detailText: detailText, for: tableView) ?? makeDefaultCell()
            case let .notifications(viewModel, displayError):
                return makeNotificationCell(viewModel, displayError: displayError, for: tableView) ?? makeDefaultCell()
            }
        }

        private func makeStandartCell(_ viewModel: ASCStandartCellViewModel, for tableView: UITableView) -> UITableViewCell? {
            guard let cell = ASCStandartCell.createForTableView(tableView) as? ASCStandartCell else { return nil }
            cell.viewModel = viewModel
            return cell
        }

        private func makeDetailCell(_ viewModel: ASCDetailTabelViewCellViewModel, for tableView: UITableView) -> UITableViewCell? {
            guard let cell = ASCDetailCell.createForTableView(tableView) as? ASCDetailCell else { return nil }
            cell.viewModel = viewModel
            return cell
        }

        private func makeNotificationCell(_ viewModel: ASCStandartCellViewModel, displayError: Bool, for tableView: UITableView) -> UITableViewCell? {
            guard let cell = ASCSettingsNotificationCell.createForTableView(tableView) as? ASCSettingsNotificationCell else { return nil }
            cell.textLabel?.text = viewModel.title
            cell.accessoryType = .disclosureIndicator
            cell.displayError = displayError
            return cell
        }

        private func makeCacheCell(_ viewModel: ASCStandartCellViewModel, processing: Bool, detailText: String?, for tableView: UITableView) -> UITableViewCell? {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)

            cell.textLabel?.text = viewModel.title
            cell.detailTextLabel?.textColor = tableView.tintColor

            let parentVC = tableView.parentViewController as? ASCSettingsViewController
            let cacheSize = parentVC?.cacheSize ?? 0

            if processing {
                let activityView = UIActivityIndicatorView(style: .medium)
                activityView.color = tableView.tintColor
                activityView.startAnimating()

                cell.detailTextLabel?.text = detailText
                cell.accessoryView = activityView
            } else {
                cell.accessoryView = nil
                cell.detailTextLabel?.text = detailText
            }

            cell.isUserInteractionEnabled = cacheSize > 0 && !processing

            return cell
        }

        private func makeSwitchCell(_ viewModel: ASCSwitchCellViewModel, for tableView: UITableView) -> UITableViewCell? {
            guard let switchCell = ASCSwitchCell.createForTableView(tableView) as? ASCSwitchCell else { return nil }
            switchCell.viewModel = viewModel
            switchCell.uiSwitch?.onTintColor = tableView.tintColor
            return switchCell
        }

        private func makeDefaultCell() -> UITableViewCell {
            UITableViewCell()
        }
    }
}

// MARK: - Section types

extension ASCSettingsViewController {
    enum SectionType {
        case standart(viewModel: SettingsSection)
        case debug(viewModel: SettingsSection)

        public func toSection() -> SettingsSection {
            switch self {
            case let .standart(viewModel),
                 let .debug(viewModel):
                return viewModel
            }
        }

        var viewModel: SettingsSection {
            get {
                switch self {
                case let .standart(viewModel),
                     let .debug(viewModel):
                    return viewModel
                }
            }

            set {
                switch self {
                case .standart:
                    self = .standart(viewModel: newValue)
                case .debug:
                    self = .debug(viewModel: newValue)
                }
            }
        }
    }
}
