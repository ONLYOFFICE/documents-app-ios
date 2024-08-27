//
//  ASCTransferPresenter.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 23.08.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import FileKit
import UIKit

enum ASCTransferType: Int {
    case copy
    case move
    case recover
    case select
}

protocol ASCTransferPresenterProtocol {
    func viewDidLoad()
    func fillRootFoldersWithProviders()
    func fetchData()
    func rebuild()
    func resetProvider()
    func onDone()
    func onClose()
}

final class ASCTransferPresenter {
    // MARK: Private vars

    private var view: ASCTransferView?
    private var provider: ASCFileProviderProtocol?
    private var transferType: ASCTransferType
    private var enableFillRootFolders: Bool
    private var items: [ASCTransferViewType] = []
    private var isActionButtonLocked: Bool = true
    private var path: String = "/"
    private var needLoadFirstPage: Bool

    private let idOnlyofficeRoot = "id-onlyoffice-root"
    private lazy var onlyofficeCategoryProviderFactory = ASCOnlyofficeCategoriesProviderFactory()

    var folder: ASCFolder?
    private let sourceFolder: ASCFolder?
    private let sourceProvider: ASCFileProviderProtocol?
    private let sourceItems: [ASCEntity]?

    // MARK: Lifecycle

    init(
        view: ASCTransferView? = nil,
        provider: ASCFileProviderProtocol? = nil,
        transferType: ASCTransferType,
        enableFillRootFolders: Bool = true,
        folder: ASCFolder? = nil,
        sourceFolder: ASCFolder?,
        sourceProvider: ASCFileProviderProtocol?,
        sourceItems: [ASCEntity]?,
        needLoadFirstPage: Bool = true
    ) {
        self.view = view
        self.provider = provider
        self.transferType = transferType
        self.enableFillRootFolders = enableFillRootFolders
        self.folder = folder
        self.sourceFolder = sourceFolder
        self.sourceProvider = sourceProvider
        self.sourceItems = sourceItems
        self.needLoadFirstPage = needLoadFirstPage
    }
}

// MARK: - ASCTransferPresenterProtocol

extension ASCTransferPresenter: ASCTransferPresenterProtocol {
    func viewDidLoad() {
        rebuild()

        if needLoadFirstPage {
            guard let provider = provider else {
                fillRootFoldersWithProviders()
                return
            }

            provider.reset()
            view?.showLoadingPage(true)
            fetchData()
        }
    }

    func rebuild() {
        build()
    }

    func resetProvider() {
        provider?.reset()
    }

    func fillRootFoldersWithProviders() {
        guard enableFillRootFolders else { return }
        items.removeAll()

        // Local Documents
        let folderDevice = ASCFolder()
        folderDevice.title = UIDevice.phone ? NSLocalizedString("On iPhone", comment: "") : NSLocalizedString("On iPad", comment: "")
        folderDevice.id = Path.userDocuments.rawValue
        folderDevice.rootFolderType = .deviceDocuments
        folderDevice.device = true

        items.append((ASCFileManager.localProvider, folderDevice))

        // ONLYOFFICE
        if let onlyofficeProvider = ASCFileManager.onlyofficeProvider?.copy() {
            let folderOnlyoffice = ASCFolder()
            folderOnlyoffice.title = ASCConstants.Name.appNameShort
            folderOnlyoffice.id = idOnlyofficeRoot
            items.append((onlyofficeProvider, folderOnlyoffice))
        }

        // Clouds
        for cloudProvider in ASCFileManager.cloudProviders {
            let folderCloud = cloudProvider.rootFolder
            items.append((cloudProvider, folderCloud))
        }

        build()
    }

    func fetchData() {
        guard let provider = provider, let folder = folder else { return }
        if provider.id == ASCFileManager.onlyofficeProvider?.id,
           folder.id == idOnlyofficeRoot
        {
            let categoryProvider = onlyofficeCategoryProviderFactory.get()
            categoryProvider.loadCategories { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(categories):
                    let categorFolders: [ASCFolder] = categories
                        .filter { ASCOnlyofficeCategory.allowToMoveAndCopy(category: $0) }
                        .compactMap { $0.folder }
                    var items: [ASCTransferViewType] = []
                    let fetchQueue = OperationQueue()
                    fetchQueue.maxConcurrentOperationCount = 1

                    for folder in categorFolders {
                        fetchQueue.addOperation {
                            let semaphore = DispatchSemaphore(value: 0)
                            let params: [String: Any] = [
                                "count": 1,
                                "filterType": ASCFilterType.foldersOnly.rawValue,
                            ]
                            provider.fetch(for: folder, parameters: params) { [weak self] provider, result, success, error in
                                if success, let folder = result as? ASCFolder {
                                    items.append((provider, folder))
                                }
                                if folder.id == categorFolders.last?.id {
                                    self?.items = items
                                    self?.build()
                                }
                                semaphore.signal()
                            }
                            semaphore.wait()
                        }
                    }

                    isActionButtonLocked = true
                case let .failure(error):
                    build()
                    if let view = view {
                        UIAlertController.showError(in: view, message: error.localizedDescription)
                    }
                }
            }
        } else {
            let params: [String: Any] = [
                "count": 1000,
                "filterType": ASCFilterType.foldersOnly.rawValue,
            ]
            provider.fetch(for: folder, parameters: params) { [weak self] provider, folder, success, error in
                guard let self else {
                    self?.build()
                    return
                }
                if let foldersOnly = (provider.items.filter { $0 is ASCFolder }) as? [ASCFolder] {
                    items = foldersOnly.map { (provider, $0) }
                }
                isActionButtonLocked = false
                build()
            }
        }
    }

    func onDone() {
        view?.dismiss(animated: true, completion: nil)
        if let nc = view?.navigationController as? ASCTransferNavigationController {
            nc.doneHandler?(provider, folder, path)
        }
    }

    func onClose() {
        view?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Private funcs

private extension ASCTransferPresenter {
    var navPrompt: String {
        switch transferType {
        case .copy:
            NSLocalizedString("Select the folder to copy the items", comment: "One line. Max 50 charasters")
        case .move:
            NSLocalizedString("Select the folder to move the items", comment: "One line. Max 50 charasters")
        case .recover:
            NSLocalizedString("Select the folder to recover the items", comment: "One line. Max 50 charasters")
        case .select:
            NSLocalizedString("Choose location with templates", comment: "One line. Max 50 charasters")
        }
    }

    var actionButtonTitle: String {
        switch transferType {
        case .copy:
            NSLocalizedString("Copy here", comment: "Button title")
        case .move:
            NSLocalizedString("Move here", comment: "Button title")
        case .recover:
            NSLocalizedString("Recover here", comment: "Button title")
        case .select:
            NSLocalizedString("Select location", comment: "Button title")
        }
    }

    var isActionButtonEnabled: Bool {
        guard sourceFolder != nil else { return true }
        return (sourceFolder?.id != folder?.id || sourceProvider?.id != provider?.id)
            && provider?.allowEdit(entity: folder) ?? false
            && !isActionButtonLocked
    }

    // MARK: Build

    func build() {
        DispatchQueue.main.async { [self] in
            view?.updateViewData(
                data: ASCTransferViewData(
                    title: folder?.title,
                    navPrompt: navPrompt,
                    actionButtonTitle: actionButtonTitle,
                    tableData: mapTableData(),
                    isActionButtonEnabled: isActionButtonEnabled
                )
            )
        }
    }

    func mapTableData() -> ASCTransferViewData.TableData {
        ASCTransferViewData.TableData(
            cells: items.compactMap { provider, entity in
                if let folder = entity as? ASCFolder {
                    return .folder(
                        ASCTransferFolderModel(
                            provider: provider,
                            folder: folder,
                            image: getImage(forFolder: folder, provider: provider),
                            title: getTitle(forFolder: folder, provider: provider),
                            isInteractable: isFolderInteractable(folder)
                        ) { [weak self] in
                            guard let self else { return }
                            let transferVC = ASCTransferViewController.instantiate(from: Storyboard.transfer)
                            let presenter: ASCTransferPresenterProtocol = self.copy(
                                forProvider: provider?.copy(),
                                folder: folder,
                                path: path.appendingPathComponent(folder.title)
                            )
                            transferVC.presenter = presenter
                            view?.navigationController?.pushViewController(transferVC, animated: true)
                        }
                    )
                }
                return nil
            }
        )
    }

    // MARK: Support funcs

    func getImage(forFolder folder: ASCFolder, provider: ASCFileProviderProtocol?) -> UIImage? {
        guard folder.parent == nil else { return nil }
        var folderImage: UIImage?

        if let provider = provider {
            folderImage = providerImage(provider.type)
        }

        if folder.id == idOnlyofficeRoot {
            folderImage = Asset.Images.tabOnlyoffice.image
        }

        switch folder.rootFolderType {
        case .deviceDocuments:
            let allowFaceId = UIDevice.device.isFaceIDCapable

            if UIDevice.pad {
                folderImage = allowFaceId ? Asset.Images.categoryIpadNew.image : Asset.Images.categoryIpad.image
            } else {
                folderImage = allowFaceId ? Asset.Images.categoryIphoneNew.image : Asset.Images.categoryIphone.image
            }
        case .onlyofficeUser:
            folderImage = Asset.Images.categoryMy.image
        case .onlyofficeShare:
            folderImage = Asset.Images.categoryShare.image
        case .onlyofficeCommon:
            folderImage = Asset.Images.categoryCommon.image
        case .onlyofficeBunch, .onlyofficeProjects:
            folderImage = Asset.Images.categoryProjects.image
        default:
            break
        }

        return folderImage
    }

    func getTitle(forFolder folder: ASCFolder, provider: ASCFileProviderProtocol?) -> String {
        if provider?.type == .local || provider?.type == .onlyoffice {
            return folder.title
        } else {
            return folder.parent != nil
                ? folder.title
                : provider?.user?.displayName ?? folder.title
        }
    }

    func providerImage(_ type: ASCFileProviderType) -> UIImage? {
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
        case .kdrive:
            return Asset.Images.cloudKdrive.image
        case .webdav:
            return Asset.Images.cloudWebdav.image
        case .icloud:
            return Asset.Images.cloudIcloud.image
        case .onedrive:
            return Asset.Images.cloudOnedrive.image
        default:
            return nil
        }
    }

    func providerName(_ type: ASCFileProviderType) -> String {
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
        case .kdrive:
            return NSLocalizedString("kDrive", comment: "")
        case .webdav:
            return NSLocalizedString("WebDAV", comment: "")
        default:
            return NSLocalizedString("Unknown", comment: "")
        }
    }

    func isFolderInteractable(_ folder: ASCFolder) -> Bool {
        guard let sourceItems = sourceItems else { return true }
        return sourceItems.first(where: { $0.id == folder.id }) == nil
    }

    func copy(forProvider provider: ASCFileProviderProtocol?, folder: ASCFolder, path: String) -> ASCTransferPresenter {
        ASCTransferPresenter(
            view: view,
            provider: provider,
            transferType: transferType,
            enableFillRootFolders: enableFillRootFolders,
            folder: folder,
            sourceFolder: sourceFolder,
            sourceProvider: sourceProvider,
            sourceItems: sourceItems,
            needLoadFirstPage: true
        )
    }
}
