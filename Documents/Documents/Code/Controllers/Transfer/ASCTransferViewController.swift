//
//  ASCTransferViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 4/13/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import FileKit

typealias ASCTransferViewType = (provider: ASCFileProviderProtocol?, folder: ASCFolder)

class ASCTransferViewController: UITableViewController {
    static let identifier = String(describing: ASCTransferViewController.self)

    fileprivate let providerName: ((_ type: ASCFileProviderType) -> String) = { type in
        switch type {
        case .googledrive:
            return NSLocalizedString("Google Drive", comment: "")
        case .dropbox:
            return NSLocalizedString("Dropbox", comment: "")
        case .nextcloud:
            return NSLocalizedString("Nextcloud", comment: "")
        case .owncloud:
            return NSLocalizedString("ownCloud", comment: "")
        case .yandex:
            return NSLocalizedString("Yandex Disk", comment: "")
        case .webdav:
            return NSLocalizedString("WebDAV", comment: "")
        default:
            return NSLocalizedString("Unknown", comment: "")
        }
    }

    fileprivate let providerImage: ((_ type: ASCFileProviderType) -> UIImage?) = { type in
        switch type {
        case .googledrive:
            return Asset.Images.cloudGoogleDrive.image
        case .dropbox:
            return Asset.Images.cloudDropbox.image
        case .nextcloud:
            return Asset.Images.cloudNextcloud.image
        case .owncloud:
            return Asset.Images.cloudOwncloud.image
        case .yandex:
            return Asset.Images.cloudYandexDisk.image
        case .webdav:
            return Asset.Images.cloudWebdav.image
        case .icloud:
            return Asset.Images.cloudIcloud.image
        default:
            return nil
        }
    }

    // MARK: - Public

    var provider: ASCFileProviderProtocol?
    var folder: ASCFolder? = nil {
        didSet {
            if oldValue == nil {
                loadFirstPage()
            }
        }
    }
    
    // MARK: - Private

    private let kPageLoadingCellTag = 7777
    private var tableData: [ASCTransferViewType] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    private var transferType: ASCTransferType {
        get {
            if let navigationController = navigationController as? ASCTransferNavigationController {
                return navigationController.transferType
            }
            return .copy
        }
    }

    private var sourceFolder: ASCFolder? {
        get {
            if let navigationController = navigationController as? ASCTransferNavigationController {
                return navigationController.sourceFolder
            }
            return nil
        }
    }
    
    private var sourceItems: [ASCEntity]? {
        get {
            if let navigationController = navigationController as? ASCTransferNavigationController {
                return navigationController.sourceItems
            }
            return nil
        }
    }

    private var sourceProvider: ASCFileProviderProtocol? {
        get {
            if let navigationController = navigationController as? ASCTransferNavigationController {
                return navigationController.sourceProvider
            }
            return nil
        }
    }
    
    // MARK: - Outlets
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet var emptyView: UIView!
    @IBOutlet var loadingView: UIView!
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableView.backgroundView = UIView()
        tableView.tableFooterView = UIView()

        updateTransferType()
        
        if let refreshControl = refreshControl {
            refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateTransferType()
        
        // Layout loader        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            if let _ = strongSelf.loadingView?.superview {
                strongSelf.loadingView?.centerYAnchor.constraint(
                    equalTo: strongSelf.view.centerYAnchor,
                    constant: -strongSelf.view.safeAreaInsets.top
                ).isActive = true
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func refresh(_ refreshControl: UIRefreshControl) {
        fetchData({ success in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
                self.showEmptyView(self.tableData.count < 1)
            }
        })
    }

    // MARK: - Private

    private func fillRootFolders() {
        tableData = []

        // Local Documents
        let folderDevice = ASCFolder()
        folderDevice.title = UIDevice.phone ? NSLocalizedString("On iPhone", comment: "") : NSLocalizedString("On iPad", comment: "")
        folderDevice.id = Path.userDocuments.rawValue
        folderDevice.rootFolderType = .deviceDocuments
        folderDevice.device = true

        tableData.append((provider: ASCFileManager.localProvider, folder: folderDevice))

        // ONLYOFFICE
        if let onlyofficeProvider = ASCFileManager.onlyofficeProvider?.copy() {
            let folderOnlyoffice = ASCFolder()
            folderOnlyoffice.title = ASCConstants.Name.appNameShort
            folderOnlyoffice.id = "id-onlyoffice-root"
            tableData.append((provider: onlyofficeProvider, folder: folderOnlyoffice))
        }

        // Clouds
        for cloudProvider in ASCFileManager.cloudProviders {
            let folderCloud = cloudProvider.rootFolder
            tableData.append((provider: cloudProvider, folder: folderCloud))
        }

        updateTransferType()
        
        tableView.reloadData()
        refreshControl = nil
    }
    
    private func loadFirstPage() {
        guard let provider = provider else {
            fillRootFolders()
            return
        }
        
        provider.reset()
        showLoadingPage(true)
        
        fetchData({ success in
            DispatchQueue.main.async {
                // UI update
                self.showLoadingPage(false)
                self.showEmptyView(self.tableData.count < 1)
            }
        })
    }
    
    private func fetchData(_ completeon: ((Bool) -> ())? = nil) {
        title = title ?? folder?.title

        if let provider = provider, let folder = folder {
            if  provider.id == ASCFileManager.onlyofficeProvider?.id,
                folder.id == "id-onlyoffice-root"
            {
                let folderCloudMy = ASCOnlyofficeCategory.folder(of: .onlyofficeUser) ?? ASCFolder()
                let folderCloudCommon = ASCOnlyofficeCategory.folder(of: .onlyofficeCommon) ?? ASCFolder()
                let folderCloudProjects = ASCOnlyofficeCategory.folder(of: .onlyofficeProjects) ?? ASCFolder()
                let isPersonal = (ASCFileManager.provider as? ASCOnlyofficeProvider)?.api.baseUrl?.contains(ASCConstants.Urls.portalPersonal) ?? false

                let categorFolders: [ASCFolder] = isPersonal
                    ? [folderCloudMy]
                    : [folderCloudMy, folderCloudCommon, folderCloudProjects]

                var tableData: [ASCTransferViewType] = []

                let fetchQueue = OperationQueue()
                fetchQueue.maxConcurrentOperationCount = 1

                for folder in categorFolders {
                    fetchQueue.addOperation {
                        let semaphore = DispatchSemaphore(value: 0)
                        let params: [String: Any] = [
                            "count"        : 1,
                            "filterType"   : ASCFilterType.foldersOnly.rawValue
                        ]
                        provider.fetch(for: folder, parameters: params) { provider, result, success, error in
                            if success, let folder = result as? ASCFolder {
                                tableData.append(ASCTransferViewType(provider: provider, folder: folder))
                            }

                            if folder.id == categorFolders.last?.id {
                                DispatchQueue.main.async {
                                    self.tableData = tableData
                                    completeon?(true)
                                }
                            }

                            semaphore.signal()
                        }
                        semaphore.wait()
                    }
                }

                self.actionButton?.isEnabled = false
            } else {
                let params: [String: Any] = [
                    "count"        : 1000,
                    "filterType"   : ASCFilterType.foldersOnly.rawValue
                    ]
                provider.fetch(for: folder, parameters: params) { [weak self] provider, folder, success, error in
                    guard let strongSelf = self else {
                        completeon?(false)
                        return
                    }

                    if let foldersOnly = (provider.items.filter { $0 is ASCFolder }) as? [ASCFolder] {
                        strongSelf.tableData = foldersOnly.map { ASCTransferViewType(provider: provider, folder: $0) }
                    }

                    strongSelf.actionButton?.isEnabled = strongSelf.sourceFolder != nil
                        ? (strongSelf.sourceFolder?.id != strongSelf.folder?.id || strongSelf.sourceProvider?.id != strongSelf.provider?.id) && provider.allowEdit(entity: strongSelf.folder)
                        : true
                    completeon?(success)
                }
            }
        }
    }
    
    private func updateTransferType() {
        switch transferType {
        case .copy:
            navigationItem.prompt = NSLocalizedString("Select the folder to copy the items", comment: "One line. Max 50 charasters")
            actionButton?.title = NSLocalizedString("Copy here", comment: "Button title")
        case .move:
            navigationItem.prompt = NSLocalizedString("Select the folder to move the items", comment: "One line. Max 50 charasters")
            actionButton?.title = NSLocalizedString("Move here", comment: "Button title")
        case .recover:
            navigationItem.prompt = NSLocalizedString("Select the folder to recover the items", comment: "One line. Max 50 charasters")
            actionButton?.title = NSLocalizedString("Recover here", comment: "Button title")
        }
    }
    
    private func showLoadingPage(_ show: Bool) {
        if show {
            showEmptyView(false)
            view.addSubview(loadingView)
            
            loadingView.translatesAutoresizingMaskIntoConstraints = false
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -view.safeAreaInsets.top).isActive = true
            
            tableView.isUserInteractionEnabled = false
        } else {
            loadingView.removeFromSuperview()
            tableView.isUserInteractionEnabled = true
        }
    }
    
    private func showEmptyView(_ show: Bool) {
        if !show {
            emptyView.removeFromSuperview()
        } else  {
            view.addSubview(emptyView)
            
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -view.safeAreaInsets.top).isActive = true
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellFolderCellId = "TransferFolderCell"

        if tableData.count < 1 {
            showEmptyView(true)
        } else {
            showEmptyView(false)
            
            let itemInfo = tableData[indexPath.row]

            if let cell = tableView.dequeueReusableCell(withIdentifier: cellFolderCellId, for: indexPath) as? ASCTransferViewCell {
                if itemInfo.folder.parent == nil {
                    var folderImage: UIImage? = nil

                    if let provider = itemInfo.provider {
                        folderImage = providerImage(provider.type)
                    }

                    if itemInfo.folder.id == "id-onlyoffice-root" {
                        folderImage = Asset.Images.tabOnlyoffice.image
                    }

                    switch itemInfo.folder.rootFolderType {
                    case .deviceDocuments:
                        let allowFaceId = UIDevice.device.isFaceIDCapable

                        if UIDevice.pad {
                            folderImage = allowFaceId ? Asset.Images.categoryIpadNew.image : Asset.Images.categoryIpad.image
                        } else {
                            folderImage = allowFaceId ? Asset.Images.categoryIphoneNew.image : Asset.Images.categoryIphone.image
                        }
                        break
                    case .onlyofficeUser:
                        folderImage = Asset.Images.categoryMy.image
                        break
                    case .onlyofficeShare:
                        folderImage = Asset.Images.categoryShare.image
                        break
                    case .onlyofficeCommon:
                        folderImage = Asset.Images.categoryCommon.image
                        break
                    case .onlyofficeBunch, .onlyofficeProjects:
                        folderImage = Asset.Images.categoryProjects.image
                        break
                    default:
                        break
                    }

                    if let folderImage = folderImage {
                        cell.folderView.image = folderImage
                    }
                }

                if itemInfo.provider?.type == .local || itemInfo.provider?.type == .onlyoffice {
                    cell.titleLabel?.text = itemInfo.folder.title
                } else {
                    cell.titleLabel?.text = itemInfo.folder.parent != nil
                        ? itemInfo.folder.title
                        : itemInfo.provider?.user?.displayName ?? itemInfo.folder.title
                }
                
                cell.isUserInteractionEnabled = true
                cell.contentView.alpha = 1
                
                if let sourceItems = sourceItems {
                    if let _ = sourceItems.first(where: { $0.id == itemInfo.folder.id }) {
                        cell.isUserInteractionEnabled = false
                        cell.contentView.alpha = 0.5
                    }
                }

                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let itemInfo = tableData[indexPath.row]
        
        if let sourceItems = sourceItems {
            if let _ = sourceItems.first(where: { $0.id == itemInfo.folder.id }) {
                return
            }
        }
        
        let transferVC = ASCTransferViewController.instantiate(from: Storyboard.transfer)
        
        transferVC.provider = itemInfo.provider?.copy()
        transferVC.folder = itemInfo.folder

        navigationController?.pushViewController(transferVC, animated: true)
    }

    // MARK: - Actions
    
    @IBAction func onClose(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func onDone(_ sender: UIBarButtonItem) {
        if let navigationController = navigationController as? ASCTransferNavigationController {
            self.dismiss(animated: true, completion: nil)
            navigationController.doneHandler?(provider, folder)
        }
    }
}
