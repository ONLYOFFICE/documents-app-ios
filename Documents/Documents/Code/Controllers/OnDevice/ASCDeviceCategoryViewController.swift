//
//  ASCDeviceCategoryViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import FileKit
import UIKit

class ASCDeviceCategoryViewController: UITableViewController {
    // MARK: - Properties

    var deviceDocumentsCategory: ASCCategory = {
        let allowFaceId = UIDevice.device.isFaceIDCapable
        var image: UIImage?

        if UIDevice.pad {
            image = allowFaceId ? Asset.Images.categoryIpadNew.image : Asset.Images.categoryIpad.image
        } else {
            image = allowFaceId ? Asset.Images.categoryIphoneNew.image : Asset.Images.categoryIphone.image
        }

        $0.title = NSLocalizedString("Documents", comment: "Category title")
        $0.image = image
        $0.provider = ASCFileManager.localProvider
        $0.folder = ASCFileManager.localProvider.rootFolder
        return $0
    }(ASCCategory())

    var deviceTrashCategory: ASCCategory = {
        $0.title = NSLocalizedString("Trash", comment: "Category title")
        $0.image = Asset.Images.categoryTrash.image
        $0.provider = ASCFileManager.localProvider.copy()
        $0.folder = {
            $0.title = NSLocalizedString("Trash", comment: "Category title")
            $0.rootFolderType = .deviceTrash
            $0.id = Path.userTrash.rawValue
            $0.device = true
            return $0
        }(ASCFolder())
        return $0
    }(ASCCategory())

    private var categories: [ASCCategory] = []

    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        categories = [
            deviceDocumentsCategory,
            deviceTrashCategory,
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if UIDevice.pad, let documentsNC = navigationController as? ASCBaseNavigationController {
            documentsNC.hasShadow = true
            documentsNC.setToolbarHidden(true, animated: false)
        }

        title = UIDevice.pad
            ? NSLocalizedString("On iPad", comment: "Category title")
            : NSLocalizedString("On iPhone", comment: "Category title")
        clearsSelectionOnViewWillAppear = UIDevice.phone
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if ASCViewControllerManager.shared.rootController?.isEditing == true {
            ASCViewControllerManager.shared.rootController?.tabBar.isHidden = true
        }
        updateLargeTitlesSize()

        navigationController?.navigationBar.prefersLargeTitles = ASCAppSettings.Feature.allowLargeTitle
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.sizeToFit()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = ASCAppSettings.Feature.allowLargeTitle
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.sizeToFit()
    }

    func select(category: ASCCategory, animated: Bool = false) {
        if let splitVC = splitViewController {
            let documentsVC: ASCDocumentsViewController = ASCDocumentsViewController.instantiate(from: Storyboard.main)

            if animated {
                splitVC.showDetailViewController(ASCBaseNavigationController(rootASCViewController: documentsVC), sender: self)
            } else {
                let selectVC: (() -> Void) = { [weak self] in
                    if let documentsNC = splitVC.viewControllers.first as? ASCBaseNavigationController,
                       let categoryVC = documentsNC.viewControllers.first
                    {
                        documentsNC.viewControllers = [categoryVC]
                    }
                    splitVC.showDetailViewController(ASCBaseNavigationController(rootASCViewController: documentsVC), sender: self)
                }
                if UIDevice.pad {
                    UIView.performWithoutAnimation {
                        selectVC()
                    }
                } else {
                    DispatchQueue.main.async {
                        UIView.performWithoutAnimation {
                            selectVC()
                        }
                    }
                }
            }

            documentsVC.provider = category.provider
            documentsVC.folder = category.folder
            documentsVC.title = category.title

            documentsVC.navigationItem.leftBarButtonItem = splitVC.displayModeButtonItem
            documentsVC.navigationItem.leftItemsSupplementBackButton = UIDevice.pad

            if let index = categories.firstIndex(where: { $0.folder?.rootFolderType == documentsVC.folder?.rootFolderType }) {
                tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
            }
        }
    }
}

// MARK: - Table view data source

extension ASCDeviceCategoryViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ASCDeviceCategoryCell.identifier, for: indexPath) as? ASCDeviceCategoryCell {
            cell.category = categories[indexPath.row]
            cell.accessoryType = ASCViewControllerManager.shared.phoneLayout ? .disclosureIndicator : .none

            return cell
        }
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select(category: categories[indexPath.row], animated: true)
    }
}
