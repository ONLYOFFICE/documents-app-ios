//
//  ASCSharingOptionsViewController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 09.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import UIKit

protocol ASCSharingOptionsDisplayLogic: AnyObject {
    func display(viewModel: ASCSharingOptions.Model.ViewModel.ViewModelData)
}

class ASCSharingOptionsViewController: ASCBaseTableViewController {
    private(set) var entity: ASCEntity?
    private var isRoomFolder: Bool {
        guard let folder = entity as? ASCFolder else { return false }
        return folder.roomType != nil
    }

    private var isArchivedRoom: Bool {
        guard let folder = entity as? ASCFolder else { return false }
        return isRoomFolder && folder.rootFolderType == .onlyofficeRoomArchived
    }

    private var roomSecurity: ASCFolderSecurity {
        guard let folder = entity as? ASCFolder else { return ASCFolderSecurity() }
        return folder.security
    }

    var interactor: (ASCSharingOptionsBusinessLogic & ASCSharingOptionsDataStore)?
    var router: (NSObjectProtocol & ASCSharingOptionsRoutingLogic & ASCSharingOptionsDataPassing)?
    var viewConfigurator: ASCSharingView?
    var hud: MBProgressHUD?
    var rightHolderCurrentlyLoading = false

    lazy var portalDefinder: ASCPortalTypeDefinderProtocol = ASCPortalTypeDefinderByCurrentConnection()
    lazy var accessToAddRightHoldersChecker: ASCAccessToAddRightHoldersCheckerProtocol = {
        let defaultChecker = ASCAccessToAddRightHoldersCheckerByPortalDefinder(portalType: portalDefinder.definePortalType())
        guard isRoomFolder, let folder = entity as? ASCFolder else { return defaultChecker }
        return ASCAccessToAddRightHoldersRoomChecker(room: folder)
    }()

    private var internalLink: String?
    private var externalLink: ASCSharingOprionsExternalLink?
    private var isSwitchActive: Bool { (externalLink != nil) && (externalLink!.access != .deny) && (externalLink!.access != .none) }
    private(set) var accessProviderFactory = ASCSharingSettingsAccessProviderFactory()

    private lazy var externalLinkSwitchHandler: (Bool) -> Void = { [weak self] activating in
        guard let self = self else { return }
        self.onLinkSwitchTapped(activating: activating)
    }

    private var importantRightHolders: [ASCSharingRightHolderViewModel] = []
    private var otherRightHolders: [ASCSharingRightHolderViewModel] = []
    private var usersInRoom: [ASCSharingRightHolderViewModel] {
        importantRightHolders + otherRightHolders
    }

    private var isModuleConfigurated = false

    private lazy var accessViewController = ASCSharingSettingsAccessViewController()

    private var sectionStructType: SectionStructType {
        guard isSharingViaExternalLinkPossible() else {
            return .base
        }
        guard isRoomFolder else { return .baseWithLink }

        return roomSecurity.editAccess ? .room : isArchivedRoom ? .roomArchived : .base
    }

    private weak var sourceViewController: UIViewController?

    init(sourceViewController: UIViewController?) {
        self.sourceViewController = sourceViewController
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        let viewConfigurator = ASCSharingView(delegate: self)
        self.viewConfigurator = viewConfigurator
        let title = sectionStructType == .room || sectionStructType == .roomArchived
            ? (entity as? ASCFolder)?.title ?? NSLocalizedString("Sharing settings", comment: "")
            : NSLocalizedString("Sharing settings", comment: "")
        viewConfigurator.configureNavigationBar(navigationController)
        viewConfigurator.configureNavigationItem(navigationItem, allowAddRightHoders: accessToAddRightHoldersChecker.checkAccessToAddRightHolders(),
                                                 allowLinkBarButton: !isRoomFolder,
                                                 title: title)

        viewConfigurator.configureTableView(tableView)

        if rightHolderCurrentlyLoading, !viewConfigurator.loadingTableActivityIndicator.isAnimating {
            viewConfigurator.showTableLoadingActivityIndicator(tableView: tableView)
        }
    }

    // MARK: Setup

    public func setup(entity: ASCEntity) {
        self.entity = entity
        if !isModuleConfigurated {
            let viewController = self
            let interactor = ASCSharingOptionsInteractor(entityLinkMaker: ASCOnlyofficeFileInternalLinkMaker(),
                                                         entity: entity,
                                                         apiWorker: ASCShareSettingsAPIWorkerFactory().get(by: portalDefinder.definePortalType()),
                                                         networkingRequestManager: OnlyofficeApiClient.shared)
            let presenter = ASCSharingOptionsPresenter(entity: entity)
            let router = ASCSharingOptionsRouter()
            viewController.interactor = interactor
            viewController.router = router
            interactor.presenter = presenter
            presenter.viewController = viewController
            router.viewController = viewController
            router.dataStore = interactor
            isModuleConfigurated = true
        } else {
            importantRightHolders.removeAll()
            otherRightHolders.removeAll()
            interactor?.makeRequest(request: .clearData)
            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }

    private func isSharingViaExternalLinkPossible() -> Bool {
        guard let _ = entity as? ASCFile else {
            return isRoomFolder
        }
        return true
    }

    private func getStruct(indexPath: IndexPath) -> SectionStruct {
        getStruct(section: indexPath.section)
    }

    private func getStruct(section: Int) -> SectionStruct {
        switch sectionStructType {
        case .baseWithLink: return .baseWithLink(.init(rawValue: section)!)
        case .base: return .base(.init(rawValue: section)!)
        case .room: return .room(.init(rawValue: section)!)
        case .roomArchived: return .roomUsers(.init(rawValue: section)!)
        }
    }

    // MARK: - Button actions

    func onLinkSwitchTapped(activating: Bool) {
        guard let entity = entity, let externalLink = externalLink else {
            return
        }
        let rightHolder = ASCSharingRightHolder(id: externalLink.id, type: .link, access: externalLink.access, isOwner: false)
        var settingAccess: ASCShareAccess = .deny
        if activating {
            settingAccess = .read
        }
        interactor?.makeRequest(request: .changeRightHolderAccess(.init(entity: entity, rightHolder: rightHolder, access: settingAccess)))
    }

    // MARK: - Requests

    public func requestToLoadRightHolders() {
        rightHolderCurrentlyLoading = true
        viewConfigurator?.showTableLoadingActivityIndicator(tableView: tableView)
        interactor?.makeRequest(request: .loadRightHolders(.init(entity: entity)))
    }

    private func requestToChangeRightHolderAccess(rightHolder: ASCSharingRightHolder, access: ASCShareAccess) {
        guard let entity = entity else {
            return
        }
        hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Sharing", comment: "Caption of the process")
        interactor?.makeRequest(request: .changeRightHolderAccess(.init(entity: entity, rightHolder: rightHolder, access: access)))
    }

    private func requestToRemoveRightHolderAccess(rightHolder: ASCSharingRightHolder, byIndexPath indexPath: IndexPath) {
        guard let entity = entity else {
            return
        }

        if let indexOfImportant = importantRightHolders.firstIndex(where: { $0.id == rightHolder.id }) {
            importantRightHolders.remove(at: indexOfImportant)
        } else if let indexOfOther = otherRightHolders.firstIndex(where: { $0.id == rightHolder.id }) {
            otherRightHolders.remove(at: indexOfOther)
        }

        tableView.deleteRows(at: [indexPath], with: .fade)

        hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Removing", comment: "Caption of the process")
        interactor?.makeRequest(request: .removeRightHolderAccess(.init(entity: entity, indexPath: indexPath, rightHolder: rightHolder)))
    }

    // MARK: - Routing

    func onAddRightsBarButtonTap() {
        guard !isRoomFolder else {
            router?.routeToInviteRightHoldersViewController(segue: nil, sourceViewController: sourceViewController)
            return
        }
        router?.routeToAddRightHoldersViewController(segue: nil)
    }
}

// MARK: - Display logic

extension ASCSharingOptionsViewController: ASCSharingOptionsDisplayLogic {
    func display(viewModel: ASCSharingOptions.Model.ViewModel.ViewModelData) {
        switch viewModel {
        case let .displayRightHolders(viewModel: viewModel):
            internalLink = viewModel.internalLink
            externalLink = viewModel.externalLink
            importantRightHolders = viewModel.importantRightHolders
            otherRightHolders = viewModel.otherRightHolders
            viewConfigurator?.hideTableLoadingActivityIndicator()
            rightHolderCurrentlyLoading = false
            tableView.reloadData()
        case let .displayChangeRightHolderAccess(viewModel: viewModel):
            if viewModel.error == nil {
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: .oneSecondDelay)
                hud = nil
                updateAndReloadRightHolderCell(by: viewModel.rightHolder)
            } else if let errorMessage = viewModel.error {
                hud?.hide(animated: false)
                hud = nil
                UIAlertController.showError(in: self, message: errorMessage)
            }
        case let .displayRemoveRightHolderAccess(viewModel: viewModel):
            if viewModel.error == nil {
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: .oneSecondDelay)
                hud = nil
            } else if let errorMessage = viewModel.error {
                hud?.hide(animated: false)
                hud = nil
                UIAlertController.showError(in: self, message: errorMessage)
                /// restore viewModel
                guard let rightHolderViewModel = viewModel.rightHolderViewModel else { return }
                switch getStruct(indexPath: viewModel.indexPath) {
                case let .baseWithLink(sectionStruct):
                    switch sectionStruct {
                    case .externalLink: return
                    case .importantRightHolders: importantRightHolders.insert(rightHolderViewModel, at: viewModel.indexPath.row)
                    case .otherRightHolders: otherRightHolders.insert(rightHolderViewModel, at: viewModel.indexPath.row)
                    }
                case let .base(sectionStruct):
                    switch sectionStruct {
                    case .importantRightHolders: importantRightHolders.insert(rightHolderViewModel, at: viewModel.indexPath.row)
                    case .otherRightHolders: otherRightHolders.insert(rightHolderViewModel, at: viewModel.indexPath.row)
                    }
                case let .room(sectionStruct):
                    switch sectionStruct {
                    case .externalLink: return
                    case .roomUsers: rightHolderViewModel.isImportant
                        ? importantRightHolders.insert(rightHolderViewModel, at: viewModel.indexPath.row)
                        : otherRightHolders.insert(rightHolderViewModel, at: viewModel.indexPath.row)
                    }
                case let .roomUsers(sectionStruct):
                    switch sectionStruct {
                    case .roomUsers: rightHolderViewModel.isImportant
                        ? importantRightHolders.insert(rightHolderViewModel, at: viewModel.indexPath.row)
                        : otherRightHolders.insert(rightHolderViewModel, at: viewModel.indexPath.row)
                    }
                }
            }
        case let .displayError(errorMessage):
            UIAlertController.showError(in: self, message: errorMessage)
        }
    }

    private func updateAndReloadRightHolderCell(by rightHolder: ASCSharingRightHolder) {
        if rightHolder.type == .link {
            externalLink?.access = rightHolder.access
            tableView.reloadSections(IndexSet(arrayLiteral: SharingOptionsSection.externalLink.rawValue), with: .automatic)
        } else if let indexOfImportant = importantRightHolders.firstIndex(where: { $0.id == rightHolder.id }) {
            importantRightHolders[indexOfImportant].access?.entityAccess = rightHolder.access
            let sectionIndex: Int = {
                switch sectionStructType {
                case .baseWithLink: return SharingOptionsSection.importantRightHolders.rawValue
                case .base: return SharingFolderOptinosSection.importantRightHolders.rawValue
                case .room: return SharingRoomOptinosSection.roomUsers.rawValue
                case .roomArchived: return SharingRoomUsersSection.roomUsers.rawValue
                }
            }()
            tableView.reloadRows(at: [IndexPath(row: indexOfImportant, section: sectionIndex)], with: .automatic)

        } else if let indexOfOther = otherRightHolders.firstIndex(where: { $0.id == rightHolder.id }) {
            otherRightHolders[indexOfOther].access?.entityAccess = rightHolder.access
            let sectionIndex: Int = {
                switch sectionStructType {
                case .baseWithLink: return SharingOptionsSection.otherRightHolders.rawValue
                case .base: return SharingFolderOptinosSection.otherRightHolders.rawValue
                case .room: return SharingRoomOptinosSection.roomUsers.rawValue
                case .roomArchived: return SharingRoomUsersSection.roomUsers.rawValue
                }
            }()
            let rowIndex: Int = {
                guard sectionStructType == .roomArchived || sectionStructType == .room, !importantRightHolders.isEmpty else { return indexOfOther }
                return indexOfOther + importantRightHolders.count
            }()

            tableView.reloadRows(at: [IndexPath(row: rowIndex, section: sectionIndex)], with: .automatic)
        }
    }
}

// MARK: - ASCSharingViewDelegate

extension ASCSharingOptionsViewController: ASCSharingViewDelegate {
    func onLinkBarButtonTap() {
        if let link = internalLink {
            UIPasteboard.general.string = link
            hud = MBProgressHUD.showTopMost()
            hud?.label.numberOfLines = 0
            hud?.setSuccessState(title: NSLocalizedString("Link copied\nto the clipboard", comment: ""))
            hud?.hide(animated: true, afterDelay: .oneSecondDelay)
            hud = nil
        }
    }

    func onDoneBarBtnTapped() {
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - TableView data source and delegate

extension ASCSharingOptionsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch sectionStructType {
        case .baseWithLink: return SharingOptionsSection.allCases.count
        case .base: return SharingFolderOptinosSection.allCases.count
        case .room: return SharingRoomOptinosSection.allCases.count
        case .roomArchived: return SharingRoomUsersSection.allCases.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch getStruct(indexPath: indexPath) {
        case let .baseWithLink(sectionStruct):
            switch sectionStruct {
            case .externalLink: return externalLinkCell(cellForRowAt: indexPath)
            case .importantRightHolders: return importantRightHoldersCell(cellForRowAt: indexPath)
            case .otherRightHolders: return otherRightHoldersCell(cellForRowAt: indexPath)
            }
        case let .base(sectionStruct):
            switch sectionStruct {
            case .importantRightHolders: return importantRightHoldersCell(cellForRowAt: indexPath)
            case .otherRightHolders: return otherRightHoldersCell(cellForRowAt: indexPath)
            }
        case let .room(sectionStruct):
            switch sectionStruct {
            case .externalLink: return externalLinkCell(cellForRowAt: indexPath)
            case .roomUsers: return usersInRoomRightHoldersCell(cellForRowAt: indexPath)
            }
        case let .roomUsers(sectionStruct):
            switch sectionStruct {
            case .roomUsers: return usersInRoomRightHoldersCell(cellForRowAt: indexPath)
            }
        }
    }

    private func externalLinkCell(cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let externalLinkRow = ExternalLinkRow(rawValue: indexPath.row) else {
            fatalError("Couldn't find ExternalLinkRow for index \(indexPath.row)")
        }

        switch externalLinkRow {
        case .accessSwitch:
            let cell: ASCSwitchTableViewCell = getCell()
            cell.viewModel = ASCSwitchRowViewModel(title: externalLinkRow.title(), isActive: isSwitchActive, toggleHandler: externalLinkSwitchHandler)
            return cell
        case .accessInfo:
            let cell: ASCAccessRowTableViewCell = getCell()
            cell.viewModel = ASCAccessRowViewModel(title: externalLinkRow.title(), access: externalLink?.access ?? .none)
            return cell
        case .link:
            let cell: ASCCopyLinkTableViewCell = getCell()
            cell.link = externalLink?.link
            return cell
        }
    }

    private func importantRightHoldersCell(cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ASCSharingRightHolderTableViewCell = getCell()
        cell.viewModel = importantRightHolders[indexPath.row]
        return cell
    }

    private func otherRightHoldersCell(cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ASCSharingRightHolderTableViewCell = getCell()
        cell.viewModel = otherRightHolders[indexPath.row]
        return cell
    }

    private func usersInRoomRightHoldersCell(cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ASCSharingRightHolderTableViewCell = getCell()
        cell.viewModel = usersInRoom[indexPath.row]
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch getStruct(section: section) {
        case let .baseWithLink(sectionStruct):
            switch sectionStruct {
            case .externalLink: return isSwitchActive ? 3 : 1
            case .importantRightHolders: return importantRightHolders.count
            case .otherRightHolders: return otherRightHolders.count
            }
        case let .base(sectionStruct):
            switch sectionStruct {
            case .importantRightHolders: return importantRightHolders.count
            case .otherRightHolders: return otherRightHolders.count
            }
        case let .room(sectionStruct):
            switch sectionStruct {
            case .externalLink: return isSwitchActive ? 3 : 1
            case .roomUsers: return usersInRoom.count
            }
        case let .roomUsers(sectionStruct):
            switch sectionStruct {
            case .roomUsers: return usersInRoom.count
            }
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UITableViewHeaderFooterView()
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return getSection(sectionRawValue: section).title().uppercased()
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard needToShowFooterNotice(tableView, viewForFooterInSection: section),
              let view = tableView.dequeueReusableHeaderFooterView(
                  withIdentifier: ASCCentredLabelHeaderFooterView.reuseId) as? ASCCentredLabelHeaderFooterView
        else {
            return nil
        }

        if accessToAddRightHoldersChecker.checkAccessToAddRightHolders() {
            view.centredTextLabel.text = NSLocalizedString("Add users or groups and allow them to \n read, review or edit documents.", comment: "")
        }
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = getSection(sectionRawValue: section)
        return section.heightForSectionHeader()
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard needToShowFooterNotice(tableView, viewForFooterInSection: section) else {
            return CGFloat.zero
        }

        // Calculate empty space of table bottom
        let emptySpaceHeight = tableView.frame.size.height
            - tableView.contentSize.height
            - (navigationController?.navigationBar.height ?? 0)
            - view.safeAreaInsets.bottom
            - 20.0 // Magic number. For prevent display scroll bar on presenting the view controller

        return emptySpaceHeight > 0 ? emptySpaceHeight : tableView.footerView(forSection: section)?.frame.height ?? 0
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = getSection(sectionRawValue: indexPath.section)
        return section.heightForRow()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var viewModel: ASCSharingRightHolderViewModel?

        let selectLinkAction: () -> Void = { [self] in
            if indexPath.row == ExternalLinkRow.accessInfo.rawValue {
                guard let externalLink = externalLink else { return }
                let accessProvider = accessProviderFactory.get(entity: entity ?? ASCEntity(), isAccessExternal: true)
                viewConfigurator?.configureForLink(
                    accessViewController: accessViewController,
                    access: externalLink.access,
                    provider: accessProvider
                ) { [weak self] access in
                    guard let self = self, let entity = self.entity else { return }
                    let rightHolder = ASCSharingRightHolder(id: externalLink.id, type: .link, access: externalLink.access, isOwner: false)
                    self.interactor?.makeRequest(request: .changeRightHolderAccess(.init(entity: entity, rightHolder: rightHolder, access: access)))
                }
                navigationController?.pushViewController(accessViewController, animated: true)
            } else if indexPath.row == ExternalLinkRow.link.rawValue {
                if let link = externalLink?.link {
                    UIPasteboard.general.string = link
                    hud = MBProgressHUD.showTopMost()
                    hud?.label.numberOfLines = 0
                    hud?.setSuccessState(title: NSLocalizedString("The link for external\naccess is copied\nto the clipboard", comment: ""))
                    hud?.hide(animated: true, afterDelay: .standardDelay)
                    hud = nil
                }
            }
        }

        switch getStruct(indexPath: indexPath) {
        case let .baseWithLink(sectionStruct):
            switch sectionStruct {
            case .externalLink: selectLinkAction()
            case .importantRightHolders: viewModel = importantRightHolders[indexPath.row]
            case .otherRightHolders: viewModel = otherRightHolders[indexPath.row]
            }
        case let .base(sectionStruct):
            switch sectionStruct {
            case .importantRightHolders: viewModel = importantRightHolders[indexPath.row]
            case .otherRightHolders: viewModel = otherRightHolders[indexPath.row]
            }
        case let .room(sectionStruct):
            switch sectionStruct {
            case .externalLink: selectLinkAction()
            case .roomUsers: viewModel = usersInRoom[indexPath.row]
            }
        case let .roomUsers(sectionStruct):
            switch sectionStruct {
            case .roomUsers: viewModel = usersInRoom[indexPath.row]
            }
        }

        guard let unwrapedViewModel = viewModel else { return }

        guard let access = unwrapedViewModel.access, access.accessEditable else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }

        let accessProvider = accessProviderFactory.get(entity: entity ?? ASCEntity(), isAccessExternal: false)
        viewConfigurator?.configureForUser(
            accessViewController: accessViewController,
            userName: unwrapedViewModel.name,
            access: unwrapedViewModel.access?.entityAccess ?? .none,
            provider: accessProvider
        ) { [weak self] access in
            guard let rightHolder = self?.makeRightHolder(formViewModel: unwrapedViewModel) else { return }
            self?.requestToChangeRightHolderAccess(rightHolder: rightHolder, access: access)
        }
        navigationController?.pushViewController(accessViewController, animated: true)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard canCellBeDeleted(indexPath: indexPath) else { return nil }
        guard let viewModel = getRightHolderViewModel(by: indexPath),
              let rightHolder = makeRightHolder(formViewModel: viewModel)
        else { return nil }
        return UISwipeActionsConfiguration(actions: [.init(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { action, view, completion in
            self.requestToRemoveRightHolderAccess(rightHolder: rightHolder, byIndexPath: indexPath)
            completion(true)
        })])
    }

    // MARK: - Support table view methods

    private func needToShowFooterNotice(_ tableView: UITableView, viewForFooterInSection section: Int) -> Bool {
        let isLastSection = section == (numberOfSections(in: tableView) - 1)
        let isSectionEmpty = self.tableView(tableView, numberOfRowsInSection: section) == 0
        return !rightHolderCurrentlyLoading && isLastSection && isSectionEmpty
    }

    private func makeRightHolder(formViewModel viewModel: ASCSharingRightHolderViewModel) -> ASCSharingRightHolder? {
        guard let rightHolderType = viewModel.rightHolderType,
              let rightHolderAccess = viewModel.access?.entityAccess
        else {
            return nil
        }
        return ASCSharingRightHolder(id: viewModel.id,
                                     type: rightHolderType,
                                     access: rightHolderAccess,
                                     isOwner: viewModel.isOwner)
    }

    private func canCellBeDeleted(indexPath: IndexPath) -> Bool {
        if let viewModel = getRightHolderViewModel(by: indexPath),
           let access = viewModel.access,
           access.accessEditable
        {
            return true
        }
        return false
    }

    private func getRightHolderViewModel(by indexPath: IndexPath) -> ASCSharingRightHolderViewModel? {
        var viewModel: ASCSharingRightHolderViewModel?
        switch getStruct(indexPath: indexPath) {
        case let .baseWithLink(sectionStruct):
            switch sectionStruct {
            case .externalLink: viewModel = nil
            case .importantRightHolders: viewModel = importantRightHolders[indexPath.row]
            case .otherRightHolders: viewModel = otherRightHolders[indexPath.row]
            }
        case let .base(sectionStruct):
            switch sectionStruct {
            case .importantRightHolders: viewModel = importantRightHolders[indexPath.row]
            case .otherRightHolders: viewModel = otherRightHolders[indexPath.row]
            }
        case let .room(sectionStruct):
            switch sectionStruct {
            case .externalLink: viewModel = nil
            case .roomUsers: viewModel = usersInRoom[indexPath.row]
            }
        case let .roomUsers(sectionStruct):
            switch sectionStruct {
            case .roomUsers: viewModel = usersInRoom[indexPath.row]
            }
        }
        return viewModel
    }

    private func getCell<T: UITableViewCell & ASCReusedIdentifierProtocol>() -> T {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: T.reuseId) as? T else {
            fatalError("couldn't cast cell to \(T.self)")
        }
        return cell
    }

    private func getSection(sectionRawValue: Int) -> ASCSharingOptionsSectionProtocol {
        switch getStruct(section: sectionRawValue) {
        case let .baseWithLink(sectionStruct): return sectionStruct
        case let .base(sectionStruct): return sectionStruct
        case let .room(sectionStruct): return sectionStruct
        case let .roomUsers(sectionStruct): return sectionStruct
        }
    }
}

// MARK: - Sections

extension ASCSharingOptionsViewController {
    enum ExternalLinkRow: Int, CaseIterable {
        case accessSwitch
        case accessInfo
        case link

        func title() -> String {
            switch self {
            case .accessSwitch: return NSLocalizedString("Allow access via external link", comment: "")
            case .accessInfo: return NSLocalizedString("Access rights", comment: "")
            case .link: return ""
            }
        }
    }

    enum SectionStructType {
        case baseWithLink
        case base
        case room
        case roomArchived
    }

    enum SectionStruct {
        case baseWithLink(SharingOptionsSection)
        case base(SharingFolderOptinosSection)
        case room(SharingRoomOptinosSection)
        case roomUsers(SharingRoomUsersSection)
    }

    enum SharingOptionsSection: Int, CaseIterable, ASCSharingOptionsSectionProtocol {
        case externalLink
        case importantRightHolders
        case otherRightHolders

        func title() -> String {
            switch self {
            case .externalLink: return ""
            case .importantRightHolders: return NSLocalizedString("Access settings", comment: "")
            case .otherRightHolders: return ""
            }
        }

        func heightForRow() -> CGFloat {
            switch self {
            case .externalLink: return 44
            case .importantRightHolders, .otherRightHolders: return 60
            }
        }

        func heightForSectionHeader() -> CGFloat {
            switch self {
            case .externalLink, .otherRightHolders: return 18
            case .importantRightHolders: return 38
            }
        }
    }

    enum SharingFolderOptinosSection: Int, CaseIterable, ASCSharingOptionsSectionProtocol {
        case importantRightHolders
        case otherRightHolders

        private func map() -> ASCSharingOptionsSectionProtocol {
            switch self {
            case .importantRightHolders: return SharingOptionsSection.importantRightHolders
            case .otherRightHolders: return SharingOptionsSection.otherRightHolders
            }
        }

        func title() -> String {
            return map().title()
        }

        func heightForRow() -> CGFloat {
            return map().heightForRow()
        }

        func heightForSectionHeader() -> CGFloat {
            return map().heightForSectionHeader()
        }
    }

    enum SharingRoomUsersSection: Int, CaseIterable, ASCSharingOptionsSectionProtocol {
        case roomUsers

        func title() -> String {
            switch self {
            case .roomUsers: return NSLocalizedString("Users in room", comment: "")
            }
        }

        func heightForRow() -> CGFloat {
            switch self {
            case .roomUsers: return 60
            }
        }

        func heightForSectionHeader() -> CGFloat {
            switch self {
            case .roomUsers: return 38
            }
        }
    }

    enum SharingRoomOptinosSection: Int, CaseIterable, ASCSharingOptionsSectionProtocol {
        case externalLink
        case roomUsers

        func title() -> String {
            switch self {
            case .externalLink: return ""
            case .roomUsers: return SharingRoomUsersSection.roomUsers.title()
            }
        }

        func heightForRow() -> CGFloat {
            switch self {
            case .externalLink: return 44
            case .roomUsers: return SharingRoomUsersSection.roomUsers.heightForRow()
            }
        }

        func heightForSectionHeader() -> CGFloat {
            switch self {
            case .externalLink: return 18
            case .roomUsers: return SharingRoomUsersSection.roomUsers.heightForSectionHeader()
            }
        }
    }
}
