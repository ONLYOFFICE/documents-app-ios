//
//  ASCNotificationSettingsViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 25.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCNotificationSettingsViewController: ASCBaseTableViewController {
    // Section model

    struct NotificationSection {
        var items: [CellType]
        var header: String?
        var footer: String?
    }

    // MARK: - Properties

    private var authorizationStatus: UNAuthorizationStatus = .authorized
    private var tableData: [SectionType] = []
    private var isPortalActive: Bool {
        ASCFileManager.onlyofficeProvider?.apiClient.active ?? false
    }

    // MARK: - Lifecycle Methods

    init() {
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Notifications", comment: "")

        tableView?.cellLayoutMarginsFollowReadableWidth = true

        build()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if UIDevice.pad {
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
        }

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

    @objc func appWillEnterForeground() {
        checkNotifications { [weak self] authorizationStatus in
            self?.onCheckNotificationStatus(status: authorizationStatus)
        }
    }

    private func onCheckNotificationStatus(status: UNAuthorizationStatus) {
        authorizationStatus = status
        build()
        tableView?.reloadData()
    }

    private func build() {
        var data: [SectionType] = []

        // Notifications section

        let notificationsFooterText: () -> String = {
            self.isPortalActive
                ? UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.pushAllNotification)
                ? String(format: NSLocalizedString("Disable if you do not want to receive notifications from the %@", comment: ""), ASCConstants.Name.brendPortalName)
                : String(format: NSLocalizedString("Enable if you want to receive notifications from the %@", comment: ""), ASCConstants.Name.brendPortalName)
                : String(format: NSLocalizedString("The setting will be available upon authorization on the %@.", comment: ""), ASCConstants.Name.brendPortalName)
        }

        var notificationsSection: NotificationSection?
        var commonNotification: CellType!

        commonNotification = .switchControl(
            viewModel: ASCSwitchCellViewModel(
                title: NSLocalizedString("All notifications", comment: ""),
                isOn: UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.pushAllNotification),
                enabled: isPortalActive,
                valueChanged: { [weak self] isOn in
                    guard let self = self else { return }

                    self.allowAllNotificetion(allow: isOn)

                    if let section = self.tableData.firstIndex(where: { item in
                        guard case .notifications = item else { return false }; return true
                    }) {
                        self.tableData[section].footer = notificationsFooterText()
                        self.tableView?.refreshFooterTitle(inSection: section)
                    }
                }
            )
        )

        notificationsSection = NotificationSection(
            items: [commonNotification],
            header: NSLocalizedString("Show notifications", comment: ""),
            footer: notificationsFooterText()
        )

        if let notificationsSection = notificationsSection {
            data.append(.notifications(viewModel: notificationsSection))
        }

        // Warning section
        if authorizationStatus != .authorized {
            let notificationsSection = NotificationSection(
                items: [
                    .warning(
                        viewModel: ASCNotificationWarningCellViewModel(action: { [weak self] in
                            self?.openSettings()
                        })
                    ),
                ],
                header: nil,
                footer: nil
            )
            data.insert(.warning(viewModel: notificationsSection), at: 0)
        }

        tableData = data
        tableView?.reloadData()
    }

    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private func allowAllNotificetion(allow: Bool) {
        UserDefaults.standard.set(allow, forKey: ASCConstants.SettingsKeys.pushAllNotification)

        guard
            let onlyofficeClient = ASCFileManager.onlyofficeProvider?.apiClient,
            let pushFCMToken = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.pushFCMToken)
        else { return }

        let params = ASCPushSubscribed()
        params.firebaseDeviceToken = pushFCMToken
        params.isSubscribed = allow

        onlyofficeClient.cancelAll()
        onlyofficeClient.request(OnlyofficeAPI.Endpoints.Push.pushSubscribe, params.toJSON())
    }
}

// MARK: - UITableViewController delegate

extension ASCNotificationSettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        tableData.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData[section].toSection().items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellType(by: indexPath).toCell(tableView: tableView)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        tableData[section].toSection().header
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        tableData[section].toSection().footer
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    private func cellType(by indexPath: IndexPath) -> CellType {
        tableData[indexPath.section].toSection().items[indexPath.row]
    }
}

// MARK: - Section types

extension ASCNotificationSettingsViewController {
    enum SectionType {
        case warning(viewModel: NotificationSection)
        case notifications(viewModel: NotificationSection)

        func toSection() -> NotificationSection {
            switch self {
            case let .warning(viewModel):
                return viewModel
            case let .notifications(viewModel):
                return viewModel
            }
        }

        var footer: String? {
            get {
                switch self {
                case let .warning(viewModel):
                    return viewModel.footer
                case let .notifications(viewModel):
                    return viewModel.footer
                }
            }

            set {
                switch self {
                case let .warning(viewModel):
                    var newViewModel = viewModel
                    newViewModel.footer = newValue
                    self = .warning(viewModel: newViewModel)
                case let .notifications(viewModel):
                    var newViewModel = viewModel
                    newViewModel.footer = newValue
                    self = .notifications(viewModel: newViewModel)
                }
            }
        }
    }
}

// MARK: - Cell types

extension ASCNotificationSettingsViewController {
    enum CellType {
        case warning(viewModel: ASCNotificationWarningCellViewModel)
        case switchControl(viewModel: ASCSwitchCellViewModel)

        func toCell(tableView: UITableView) -> UITableViewCell {
            switch self {
            case let .warning(viewModel):
                return makeNotificationTurnoff(viewModel, for: tableView) ?? makeDefaultCell()
            case let .switchControl(viewModel):
                return makeSwitchCell(viewModel, for: tableView) ?? makeDefaultCell()
            }
        }

        private func makeNotificationTurnoff(_ viewModel: ASCNotificationWarningCellViewModel, for tableView: UITableView) -> UITableViewCell? {
            guard let cell = ASCNotificationWarningCell.createForTableView(tableView) as? ASCNotificationWarningCell else { return nil }
            cell.viewModel = viewModel
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
