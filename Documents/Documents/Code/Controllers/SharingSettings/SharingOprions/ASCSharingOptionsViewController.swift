//
//  ASCSharingOptionsViewController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 09.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingOptionsDisplayLogic: AnyObject {
    func displayRightHolders(viewModel: ASCSharingOptions.Model.ViewModel.ViewModelData)
}

class ASCSharingOptionsViewController: ASCBaseTableViewController {
    
    var entity: ASCEntity?
    
    var interactor: ASCSharingOptionsBusinessLogic?
    var router: (NSObjectProtocol & ASCSharingOptionsRoutingLogic)?
    var viewConfigurator: ASCSharingView?
    
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
        viewConfigurator.configureNavigationBar(navigationController)
        viewConfigurator.configureTableView(tableView)
        self.viewConfigurator = viewConfigurator
    }

    // MARK: Setup
    public func setup() {
        if !isModuleConfigurated {
            let viewController        = self
            let interactor            = ASCSharingOptionsInteractor()
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
    
    // MARK: - Requests
    public func requestToLoadRightHolders() {
        interactor?.makeRequest(request: .loadRightHolders(entity: entity))
    }
}

// MARK: - Sharing oprions display logic
extension ASCSharingOptionsViewController: ASCSharingOptionsDisplayLogic {
    func displayRightHolders(viewModel: ASCSharingOptions.Model.ViewModel.ViewModelData) {
        switch viewModel {
        case .displayRightHolders(importantRightHolders: let importantRightHolders, otherRightHolders: let otherRightHolders):
            self.importantRightHolders = importantRightHolders
            self.otherRightHolders = otherRightHolders
            tableView.reloadData()
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
        SharingOptionsSection.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = getSection(sectionRawValue: indexPath.section)

        
        switch section {
        case .externalLink:
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
        case .importantRightHolders:
             let cell: ASCSharingRightHolderTableViewCell = getCell()
             cell.viewModel = importantRightHolders[indexPath.row]
             return cell
         case .otherRightHolders:
            let cell: ASCSharingRightHolderTableViewCell = getCell()
            cell.viewModel = otherRightHolders[indexPath.row]
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = getSection(sectionRawValue: section)
        switch section {
        case .externalLink:
            return externalLink.isEmpty ? 1 : 3
        case .importantRightHolders:
            return importantRightHolders.count
        case .otherRightHolders:
            return otherRightHolders.count
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
    
    private func getCell<T: UITableViewCell & ASCReusedIdentifierProtocol>() -> T {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: T.reuseId) as? T else {
            fatalError("couldn't cast cell to \(T.self)")
        }
        return cell
    }
    
    private func getSection(sectionRawValue: Int) -> SharingOptionsSection {
        guard let section = SharingOptionsSection.init(rawValue: sectionRawValue) else { fatalError("Couldn't find a section") }
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
    
    enum SharingOptionsSection: Int, CaseIterable {
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
    
}
