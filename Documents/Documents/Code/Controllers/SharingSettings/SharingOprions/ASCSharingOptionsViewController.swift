//
//  ASCSharingOptionsViewController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 09.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit
import MBProgressHUD

protocol ASCSharingOptionsDisplayLogic: AnyObject {
    func display(viewModel: ASCSharingOptions.Model.ViewModel.ViewModelData)
}

class ASCSharingOptionsViewController: ASCBaseTableViewController {
    
    private(set) var entity: ASCEntity?
    
    var interactor: ASCSharingOptionsBusinessLogic?
    var router: (NSObjectProtocol & ASCSharingOptionsRoutingLogic)?
    var viewConfigurator: ASCSharingView?
    var hud: MBProgressHUD?
    var rightHolderCurrentlyLoading = false
    
    var externalLink: String = "" {
        didSet {
            tableView.reloadSections(IndexSet(arrayLiteral: SharingOptionsSection.externalLink.rawValue), with: .automatic)
        }
    }
    
    private lazy var externalLinkSwitchHandler: (Bool) -> Void = { [weak self] activating in
        guard let self = self else {
            return
        }
        if activating {
            self.externalLink = "https://test.portal.com"
        } else {
            self.externalLink = ""
        }
    }
    
    private var importantRightHolders: [ASCSharingRightHolderViewModel] = []
    private var otherRightHolders: [ASCSharingRightHolderViewModel] = []
    
    fileprivate var isModuleConfigurated = false
    
    private lazy var accessViewController = ASCSharingSettingsAccessViewController()
    
    override init(style: UITableView.Style = .grouped) {
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let viewConfigurator = ASCSharingView(delegate: self)
        self.viewConfigurator = viewConfigurator
        viewConfigurator.configureNavigationBar(navigationController)
        viewConfigurator.configureTableView(tableView)
        if rightHolderCurrentlyLoading && !viewConfigurator.loadingTableActivityIndicator.isAnimating {
            viewConfigurator.showTableLoadingActivityIndicator(tableView: tableView)
        }
    }
    
    // MARK: Setup
    public func setup(entity: ASCEntity) {
        self.entity = entity
        if !isModuleConfigurated {
            let viewController        = self
            let interactor            = ASCSharingOptionsInteractor(entityLinkMaker: ASCOnlyofficeFileInternalLinkMaker())
            let presenter             = ASCSharingOptionsPresenter()
            let router                = ASCSharingOptionsRouter()
            viewController.interactor = interactor
            viewController.router     = router
            interactor.presenter      = presenter
            presenter.viewController  = viewController
            router.viewController     = viewController
            isModuleConfigurated      = true
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
        guard let _ = entity as? ASCFile else { return false }
        return true
    }
    
    // MARK: - Requests
    public func requestToLoadRightHolders() {
        rightHolderCurrentlyLoading = true
        viewConfigurator?.showTableLoadingActivityIndicator(tableView: tableView)
        self.interactor?.makeRequest(request: .loadRightHolders(entity: self.entity))
    }
    
    private func requestToChangeRightHolderAccess(rightHolder: ASCSharingRightHolderViewModel, access: ASCShareAccess) {
        guard let entity = entity else {
            return
        }
        hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Sharing", comment: "Caption of the process")
        interactor?.makeRequest(request: .changeRightHolderAccess(entity: entity, rightHolder: rightHolder, access: access))
    }
}

// MARK: - Sharing oprions display logic
extension ASCSharingOptionsViewController: ASCSharingOptionsDisplayLogic {
    func display(viewModel: ASCSharingOptions.Model.ViewModel.ViewModelData) {
        switch viewModel {
        case .displayRightHolders(importantRightHolders: let importantRightHolders, otherRightHolders: let otherRightHolders):
            self.importantRightHolders = importantRightHolders
            self.otherRightHolders = otherRightHolders
            viewConfigurator?.hideTableLoadingActivityIndicator()
            rightHolderCurrentlyLoading = false
            tableView.reloadData()
        case .displayChangeRightHolderAccess(rightHolder: let rightHolder, error: let error):
            if error == nil {
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: 1)
                hud = nil
                updateAndReloadRightHolderCell(by: rightHolder)
            } else if let errorMessage = error {
                hud?.hide(animated: false)
                hud = nil
                UIAlertController.showError(in: self, message: errorMessage)
            }
            
        }
    }
    
    private func updateAndReloadRightHolderCell(by rightHolder: ASCSharingRightHolderViewModel) {
        if let indexOfImportant = importantRightHolders.firstIndex(where: { $0.id == rightHolder.id }) {
            importantRightHolders[indexOfImportant] = rightHolder
            let sectionIndex = isSharingViaExternalLinkPossible()
                ? SharingOptionsSection.importantRightHolders.rawValue
                : SharingFolderOprinosSection.importantRightHolders.rawValue
            tableView.reloadRows(at: [IndexPath(row: indexOfImportant, section: sectionIndex)], with: .automatic)
            
        } else if let indexOfOther = otherRightHolders.firstIndex(where: { $0.id == rightHolder.id }) {
            otherRightHolders[indexOfOther] = rightHolder
            let sectionIndex = isSharingViaExternalLinkPossible()
                ? SharingOptionsSection.otherRightHolders.rawValue
                : SharingFolderOprinosSection.otherRightHolders.rawValue
            tableView.reloadRows(at: [IndexPath(row: indexOfOther, section: sectionIndex)], with: .automatic)
        }
    }
}
// MARK: - Routing
extension ASCSharingOptionsViewController: ASCSharingViewDelegate {
    func onLinkBarButtonTap() {
        
    }
    
    func onAddRightsBarButtonTap() {
        
    }
}

// MARK: - TableView data source and delegate
extension ASCSharingOptionsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isSharingViaExternalLinkPossible() {
            return SharingOptionsSection.allCases.count
        } else {
            return SharingFolderOprinosSection.allCases.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSharingViaExternalLinkPossible() {
            let section = getSharingOptionsSection(sectionRawValue: indexPath.section)
            switch section {
            case .externalLink: return externalLinkCell(cellForRowAt: indexPath)
            case .importantRightHolders: return importantRightHoldersCell(cellForRowAt: indexPath)
            case .otherRightHolders: return otherRightHoldersCell(cellForRowAt: indexPath)
            }
        } else {
            let section = getSharingFolderOprinosSection(sectionRawValue: indexPath.row)
            switch section {
            case .importantRightHolders: return importantRightHoldersCell(cellForRowAt: indexPath)
            case .otherRightHolders: return otherRightHoldersCell(cellForRowAt: indexPath)
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
            cell.viewModel = ASCSwitchRowViewModel(title: externalLinkRow.title(), isActive: !externalLink.isEmpty, toggleHandler: externalLinkSwitchHandler)
            return cell
        case .accessInfo:
            let cell: ASCAccessRowTableViewCell = getCell()
            cell.viewModel = ASCAccessRowViewModel(title: externalLinkRow.title(), access: .read)
            return cell
        case .link:
            let cell: ASCCopyLinkTableViewCell = getCell()
            cell.link = externalLink
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSharingViaExternalLinkPossible() {
            let section = getSharingOptionsSection(sectionRawValue: section)
            switch section {
            case .externalLink: return externalLink.isEmpty ? 1 : 3
            case .importantRightHolders: return importantRightHolders.count
            case .otherRightHolders: return otherRightHolders.count
            }
        } else {
            let section = getSharingFolderOprinosSection(sectionRawValue: section)
            switch section {
            case .importantRightHolders: return importantRightHolders.count
            case .otherRightHolders: return otherRightHolders.count
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return getSection(sectionRawValue: section).title().uppercased()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = getSection(sectionRawValue: indexPath.section)
        return section.heightForRow()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = getSection(sectionRawValue: section)
        return section.heightForSectionHeader()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var viewModel: ASCSharingRightHolderViewModel?
        if isSharingViaExternalLinkPossible() {
            let section = getSharingOptionsSection(sectionRawValue: indexPath.section)
            switch section {
            case .externalLink:
                if indexPath.row == ExternalLinkRow.accessInfo.rawValue {
                    viewConfigurator?.configureForLink(accessViewController: accessViewController, access: .read) // MARK: - TODO change fix .read
                    accessViewController.selectAccessDelegate = { [weak self] access in
                        
                    }
                    self.navigationController?.pushViewController(accessViewController, animated: true)
                }
            case .importantRightHolders: viewModel = importantRightHolders[indexPath.row]
            case .otherRightHolders: viewModel = otherRightHolders[indexPath.row]
            }
        } else {
            let section = getSharingFolderOprinosSection(sectionRawValue: indexPath.row)
            switch section {
            case .importantRightHolders: viewModel = importantRightHolders[indexPath.row]
            case .otherRightHolders: viewModel = otherRightHolders[indexPath.row]
            }
        }
        
        guard let unwrapedViewModel = viewModel else { return }
        
        guard let access = unwrapedViewModel.access, access.accessEditable else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        viewConfigurator?.configureForUser(accessViewController: accessViewController,
                                           userName: unwrapedViewModel.name,
                                           access: unwrapedViewModel.access?.documetAccess ?? .none)
        accessViewController.selectAccessDelegate = { [weak self] access in
            self?.requestToChangeRightHolderAccess(rightHolder: unwrapedViewModel, access: access)
        }
        self.navigationController?.pushViewController(accessViewController, animated: true)
        
    }
    
    private func getCell<T: UITableViewCell & ASCReusedIdentifierProtocol>() -> T {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: T.reuseId) as? T else {
            fatalError("couldn't cast cell to \(T.self)")
        }
        return cell
    }

    private func getSection(sectionRawValue: Int) -> ASCSharingOptionsSectionProtocol {
        if isSharingViaExternalLinkPossible() {
            return getSharingOptionsSection(sectionRawValue: sectionRawValue)
        } else {
            return getSharingFolderOprinosSection(sectionRawValue: sectionRawValue)
        }
    }
    
    private func getSharingOptionsSection(sectionRawValue: Int) -> SharingOptionsSection {
        guard let section = SharingOptionsSection(rawValue: sectionRawValue) else { fatalError("couldn't get SharingOptionsSection") }
        return section
    }
    
    private func getSharingFolderOprinosSection(sectionRawValue: Int) -> SharingFolderOprinosSection {
        guard let section = SharingFolderOprinosSection(rawValue: sectionRawValue) else { fatalError("couldn't get SharingFolderOprinosSection") }
        return section
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
    
    enum SharingOptionsSection: Int, CaseIterable, ASCSharingOptionsSectionProtocol {
        case externalLink
        case importantRightHolders
        case otherRightHolders
        
        func title() -> String {
            switch self {
            case .externalLink: return NSLocalizedString("Access by external link", comment: "")
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
            case .externalLink, .importantRightHolders: return 38
            case .otherRightHolders: return 16
            }
        }
    }
    
    enum SharingFolderOprinosSection: Int, CaseIterable, ASCSharingOptionsSectionProtocol {
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
    
}
