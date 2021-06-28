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
}

class ASCSharingView {
    
    private weak var delegate: ASCSharingViewDelegate?

    private lazy var linkBarButtonItem: UIBarButtonItem = {
        var icon: UIImage?
        if #available(iOS 13.0, *) {
            icon = UIImage(systemName: "link")
        } else {
            icon = Asset.Images.barCopy.image // MARK: - todo replace the image
        }
        return UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(onLinkBarButtonTap))
    }()
    
    private lazy var addRightsBarButtonItem: UIBarButtonItem = {
        var icon: UIImage?
        if #available(iOS 13.0, *) {
            icon = UIImage(systemName: "person.crop.circle.fill.badge.plus")
        } else {
            icon = Asset.Images.navAdd.image // MARK: - todo replace the image
        }
        return UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(onAddRightsBarButtonTap))
    }()
    
    convenience init(delegate: ASCSharingViewDelegate?) {
        self.init()
        
        self.delegate = delegate
    }

    public func configureNavigationBar(_ navigationController: UINavigationController?) {
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.backIndicatorImage = UIImage()
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage()
        navigationController?.navigationBar.backItem?.backButtonTitle = NSLocalizedString("Done", comment: "")
        navigationController?.navigationBar.topItem?.title = NSLocalizedString("Sharing settings", comment: "")

        navigationController?.navigationBar.topItem?.rightBarButtonItems = [
            addRightsBarButtonItem,
            linkBarButtonItem
        ]
    }
    
    public func configureTableView(_ tableView: UITableView) {
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = Asset.Colors.tableBackground.color
        tableView.sectionFooterHeight = 0
        
        tableView.register(ASCSwitchTableViewCell.self,
                           forCellReuseIdentifier: ASCSwitchTableViewCell.reuseId)
        tableView.register(ASCAccessRowTableViewCell.self,
                           forCellReuseIdentifier: ASCAccessRowTableViewCell.reuseId)
        tableView.register(ASCCopyLinkTableViewCell.self,
                           forCellReuseIdentifier: ASCCopyLinkTableViewCell.reuseId)
        tableView.register(ASCSharingRightHolderTableViewCell.self,
                           forCellReuseIdentifier: ASCSharingRightHolderTableViewCell.reuseId)
    }
    
    @objc func onLinkBarButtonTap() {
        self.delegate?.onLinkBarButtonTap()
    }
    
    @objc func onAddRightsBarButtonTap() {
        self.delegate?.onAddRightsBarButtonTap()
    }
}
