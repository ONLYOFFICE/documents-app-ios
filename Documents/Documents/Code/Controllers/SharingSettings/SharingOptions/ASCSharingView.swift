//
//  ASCSharingView.swift
//  Documents
//
//  Created by Павел Чернышев on 28.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingViewDelegate: AnyObject {
    func onLinkBarButtonTap()
    func onAddRightsBarButtonTap()
    func onDoneBarBtnTapped()
}

class ASCSharingView {
    private weak var delegate: ASCSharingViewDelegate?

    private lazy var doneBarBtn: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: .done, target: self, action: #selector(onDoneBarBtnTapped))

    private lazy var linkBarButtonItem: UIBarButtonItem = {
        var icon: UIImage?
        if #available(iOS 13.0, *) {
            icon = UIImage(systemName: "link")
        } else {
            icon = Asset.Images.barCopy.image // MARK: - todo replace the image
        }
        return UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(onLinkBarButtonTap))
    }()

    private var navBarHeigh: CGFloat = 0
    private lazy var addRightsBarButtonItem: UIBarButtonItem = {
        var icon: UIImage?
        if #available(iOS 13.0, *) {
            icon = UIImage(systemName: "person.crop.circle.fill.badge.plus")
        } else {
            icon = Asset.Images.navAdd.image
        }
        return UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(onAddRightsBarButtonTap))
    }()

    public lazy var loadingTableActivityIndicator = UIActivityIndicatorView()

    convenience init(delegate: ASCSharingViewDelegate?) {
        self.init()

        self.delegate = delegate
    }

    public func configureNavigationBar(_ navigationController: UINavigationController?) {
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navBarHeigh = navigationController?.navigationBar.height ?? 0
    }

    public func configureNavigationItem(_ navigationItem: UINavigationItem, allowAddRightHoders: Bool, allowLinkBarButton: Bool, title: String) {
        navigationItem.leftBarButtonItem = doneBarBtn
        navigationItem.title = title

        var items = [UIBarButtonItem]()
        if allowAddRightHoders {
            items.append(addRightsBarButtonItem)
        }
        if allowLinkBarButton {
            items.append(linkBarButtonItem)
        }

        navigationItem.rightBarButtonItems = items
    }

    public func configureTableView(_ tableView: UITableView) {
        tableView.tableFooterView = UIView()
        if #available(iOS 15.0, *) {} else {
            tableView.backgroundColor = Asset.Colors.tableBackground.color
        }
        tableView.sectionFooterHeight = 0

        tableView.register(ASCSwitchTableViewCell.self,
                           forCellReuseIdentifier: ASCSwitchTableViewCell.reuseId)
        tableView.register(ASCAccessRowTableViewCell.self,
                           forCellReuseIdentifier: ASCAccessRowTableViewCell.reuseId)
        tableView.register(ASCCopyLinkTableViewCell.self,
                           forCellReuseIdentifier: ASCCopyLinkTableViewCell.reuseId)
        tableView.register(ASCSharingRightHolderTableViewCell.self,
                           forCellReuseIdentifier: ASCSharingRightHolderTableViewCell.reuseId)
        tableView.register(ASCCentredLabelHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: ASCCentredLabelHeaderFooterView.reuseId)
    }

    public func configureForUser(accessViewController: ASCSharingSettingsAccessViewController, userName: String, access: ASCShareAccess, provider: ASCSharingSettingsAccessProvider, selectAccessDelegate: ((ASCShareAccess) -> Void)?) {
        let viewModel = ASCSharingSettingsAccessViewModel(title: userName,
                                                          currentlyAccess: access,
                                                          accessProvider: provider,
                                                          accessNoteProvider: ASCSharingSettingsAccessNotesProvidersFactory().get(accessType: .userOrGroup),
                                                          largeTitleDisplayMode: .automatic,
                                                          headerText: NSLocalizedString("Access settings", comment: ""),
                                                          selectAccessDelegate: selectAccessDelegate)
        accessViewController.viewModel = viewModel
    }

    public func configureForLink(accessViewController: ASCSharingSettingsAccessViewController, access: ASCShareAccess, provider: ASCSharingSettingsAccessProvider,
                                 selectAccessDelegate: ((ASCShareAccess) -> Void)?)
    {
        let viewModel = ASCSharingSettingsAccessViewModel(title: NSLocalizedString("Sharing settings", comment: ""),
                                                          currentlyAccess: access,
                                                          accessProvider: provider,
                                                          accessNoteProvider: ASCSharingSettingsAccessNotesProvidersFactory().get(accessType: .externalLink),
                                                          largeTitleDisplayMode: .never,
                                                          headerText: NSLocalizedString("Access by external link", comment: ""),
                                                          selectAccessDelegate: selectAccessDelegate)
        accessViewController.viewModel = viewModel
    }

    public func showTableLoadingActivityIndicator(tableView: UITableView) {
        let centerYOffset = navBarHeigh
        loadingTableActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingTableActivityIndicator.startAnimating()
        tableView.addSubview(loadingTableActivityIndicator)
        loadingTableActivityIndicator.anchorCenterXToSuperview()
        loadingTableActivityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -centerYOffset).isActive = true
    }

    public func hideTableLoadingActivityIndicator() {
        loadingTableActivityIndicator.stopAnimating()
        loadingTableActivityIndicator.removeFromSuperview()
    }

    @objc func onLinkBarButtonTap() {
        delegate?.onLinkBarButtonTap()
    }

    @objc func onAddRightsBarButtonTap() {
        delegate?.onAddRightsBarButtonTap()
    }

    @objc func onDoneBarBtnTapped() {
        delegate?.onDoneBarBtnTapped()
    }
}
