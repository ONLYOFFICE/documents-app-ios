//
//  ASCSharingOptionsViewController.swift
//  Documents
//
//  Created by Павел Чернышев on 09.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingOptionsViewController: ASCBaseTableViewController {
    
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
    
    private var rightsHoldersDataProvider: [ASCSharingOptionsRightHolderViewModel] {
        return [
            ASCSharingOptionsRightHolderViewModel(avatar: Asset.Images.whatsnewFutureShare.image, name: "Pavel Chernyshev Pavel Chernyshev Pavel Chernyshev Pavel Chernyshev Pavel Chernyshev", isOwner: true, rightHolder: .manager, documetAccess: .full, accessEditable: false),
            ASCSharingOptionsRightHolderViewModel(avatar: Asset.Images.whatsnewFutureFavourite.image, name: "Dimitry Dmittrov", isOwner: false, rightHolder: .designer, documetAccess: .read, accessEditable: true),
            ASCSharingOptionsRightHolderViewModel(avatar: Asset.Images.whatsnewFutureIcloudDrive.image, name: "Admins", isOwner: true, rightHolder: .group, documetAccess: .review, accessEditable: true),
        ]
    }
    
    private var importantRightHolders: [ASCSharingOptionsRightHolderViewModel] {
        return [rightsHoldersDataProvider[0]]
    }
    
    private var otherRightHolders: [ASCSharingOptionsRightHolderViewModel] {
        var result: [ASCSharingOptionsRightHolderViewModel] = []
        for model in rightsHoldersDataProvider[1...] {
            result.append(model)
        }
        return result
    }
    
    private lazy var linkBarButtonItem: UIBarButtonItem = {
        var icon: UIImage?
        if #available(iOS 13.0, *) {
            icon = UIImage(systemName: "link")
        } else {
            icon = Asset.Images.barCopy.image // MARK: - todo replace the image
        }
        return UIBarButtonItem(image: icon, style: .plain, target: nil, action: nil)
    }()
    
    private lazy var addRightsBarButtonItem: UIBarButtonItem = {
        var icon: UIImage?
        if #available(iOS 13.0, *) {
            icon = UIImage(systemName: "person.crop.circle.fill.badge.plus")
        } else {
            icon = Asset.Images.navAdd.image // MARK: - todo replace the image
        }
        return UIBarButtonItem(image: icon, style: .plain, target: nil, action: nil)
    }()
    
    override init(style: UITableView.Style = .grouped) {
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        configureNavigationBar()
        configureTableView()
    }
    
    private func configureNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.backIndicatorImage = UIImage()
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage()
        navigationController?.navigationBar.backItem?.backButtonTitle = NSLocalizedString("Done", comment: "")
        navigationController?.navigationBar.topItem?.title = NSLocalizedString("Sharing settings", comment: "")

        navigationController?.navigationBar.topItem?.rightBarButtonItems = [
            addRightsBarButtonItem,
            linkBarButtonItem
        ]
    }
    
    private func configureTableView() {
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = Asset.Colors.tableBackground.color
        tableView.sectionFooterHeight = 0
        
        tableView.register(ASCSwitchTableViewCell.self,
                           forCellReuseIdentifier: ASCSwitchTableViewCell.reuseId)
        tableView.register(ASCAccessRowTableViewCell.self,
                           forCellReuseIdentifier: ASCAccessRowTableViewCell.reuseId)
        tableView.register(ASCCopyLinkTableViewCell.self,
                           forCellReuseIdentifier: ASCCopyLinkTableViewCell.reuseId)
        tableView.register(ASCSharingOptionsRightHolderTableViewCell.self,
                           forCellReuseIdentifier: ASCSharingOptionsRightHolderTableViewCell.reuseId)
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
             let cell: ASCSharingOptionsRightHolderTableViewCell = getCell()
             cell.viewModel = importantRightHolders[indexPath.row]
             return cell
         case .otherRightHolders:
            let cell: ASCSharingOptionsRightHolderTableViewCell = getCell()
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
