//
//  ASCTransferPresenter.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 23.08.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import FileKit
import MBProgressHUD
import UIKit

enum ASCTransferType: Int {
    case copy
    case move
    case recover
    case select
    case selectFillForms
    case selectFillFormRoom
}

protocol ASCTransferPresenterProtocol {
    var transferType: ASCTransferType { get }
    var isLoading: Bool { get }

    func viewDidLoad()
    func fillRootFoldersWithProviders()
    func fetchData()
    func rebuild()
    func resetProvider()
    func onDone()
    func onClose()
}

struct ASCTransferFlowModel {
    let sourceFolder: ASCFolder?
    let sourceProvider: ASCFileProviderProtocol?
    let sourceItems: [ASCEntity]?
}

final class ASCTransferPresenter {
    // MARK: Private vars

    private let view: ASCTransferView?
    private let provider: ASCFileProviderProtocol?
    private let enableFillRootFolders: Bool
    private let enableDisplayNewFolderBarButton: Bool
    private let enableDisplayCreateFillFormRoomBarButton: Bool
    private var items: [ASCTransferViewType] = []
    private var isActionButtonLocked: Bool = true
    private let path: String
    private let needLoadFirstPage: Bool

    private let idOnlyofficeRoot = "id-onlyoffice-root"
    private lazy var onlyofficeCategoryProviderFactory = ASCOnlyofficeCategoriesProviderFactory()

    private let folder: ASCFolder?
    private let flowModel: ASCTransferFlowModel?

    private(set) var isLoading: Bool = false
    let transferType: ASCTransferType

    // MARK: Lifecycle

    init(
        view: ASCTransferView? = nil,
        provider: ASCFileProviderProtocol? = nil,
        transferType: ASCTransferType,
        enableFillRootFolders: Bool = true,
        enableDisplayNewFolderBarButton: Bool = true,
        enableDisplayCreateFillFormRoomBarButton: Bool = false,
        folder: ASCFolder? = nil,
        path: String = "/",
        flowModel: ASCTransferFlowModel? = nil,
        needLoadFirstPage: Bool = true
    ) {
        self.view = view
        self.provider = provider
        self.transferType = transferType
        self.enableFillRootFolders = enableFillRootFolders
        self.enableDisplayNewFolderBarButton = enableDisplayNewFolderBarButton
        self.enableDisplayCreateFillFormRoomBarButton = enableDisplayCreateFillFormRoomBarButton
        self.folder = folder
        self.path = path
        self.flowModel = flowModel
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
        isLoading = true
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
                                    self?.isLoading = false
                                    self?.build()
                                }
                                semaphore.signal()
                            }
                            semaphore.wait()
                        }
                    }

                    isActionButtonLocked = true
                case let .failure(error):
                    isLoading = false
                    build()
                    if let view = view {
                        UIAlertController.showError(in: view, message: error.localizedDescription)
                    }
                }
            }
        } else {
            let filterType: Int = {
                switch transferType {
                case .selectFillForms: return ASCFilterType.onlyFillingForms.rawValue
                default: return ASCFilterType.foldersOnly.rawValue
                }
            }()
            let params: [String: Any] = [
                "count": 1000,
                "filterType": filterType,
            ]
            let displayFoldersOnly = transferType != .selectFillForms
            provider.fetch(for: folder, parameters: params) { [weak self] provider, _, success, error in
                guard let self else {
                    return
                }
                var entities = provider.items

                if folder.isRoomListFolder, transferType == .selectFillFormRoom {
                    entities = entities.filter {
                        guard let folder = $0 as? ASCFolder else { return true }
                        return folder.roomType == .fillingForm
                    }
                }

                if displayFoldersOnly, let foldersOnly = (entities.filter { $0 is ASCFolder }) as? [ASCFolder] {
                    items = foldersOnly.map { (provider, $0) }
                } else if !displayFoldersOnly {
                    items = entities.compactMap {
                        if self.transferType == .selectFillForms, let file = $0 as? ASCFile {
                            return file.isForm ? (provider, $0) : nil
                        } else {
                            return (provider, $0)
                        }
                    }
                }
                isActionButtonLocked = false
                isLoading = false
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
        case .selectFillForms:
            NSLocalizedString("Select a PDF Form", comment: "One line. Max 50 charasters")
        case .selectFillFormRoom:
            NSLocalizedString("Choose Form filling room or create new", comment: "One line. Max 50 charasters")
        }
    }

    var actionButtonTitle: String {
        switch transferType {
        case .copy, .selectFillFormRoom:
            NSLocalizedString("Copy here", comment: "Button title")
        case .move:
            NSLocalizedString("Move here", comment: "Button title")
        case .recover:
            NSLocalizedString("Recover here", comment: "Button title")
        case .select:
            NSLocalizedString("Select location", comment: "Button title")
        case .selectFillForms:
            ""
        }
    }

    var isActionButtonEnabled: Bool {
        if transferType == .selectFillForms {
            return (folder?.isRoomListSubfolder ?? false) && !isActionButtonLocked
        }
        if folder?.isRoomListFolder == true {
            return false
        }
        guard flowModel?.sourceFolder != nil else { return true }
        return (flowModel?.sourceFolder?.id != folder?.id || flowModel?.sourceProvider?.id != provider?.id)
            && provider?.allowEdit(entity: folder) ?? false
            && !isActionButtonLocked
    }

    // MARK: Build

    func build() {
        let tableData = mapTableData()
        DispatchQueue.main.async { [self] in
            view?.updateViewData(
                data: ASCTransferViewModel(
                    title: folder?.title,
                    navPrompt: navPrompt,
                    toolBarItems: buildToolBarItems(),
                    tableData: tableData
                )
            )
        }
    }

    func buildToolBarItems() -> [ASCTransferViewModel.BarButtonItem] {
        var items = [ASCTransferViewModel.BarButtonItem]()
        if enableDisplayNewFolderBarButton {
            items.append(
                ASCTransferViewModel.BarButtonItem(
                    title: NSLocalizedString("New folder", comment: ""),
                    type: .plain,
                    isEnabled: (provider?.allowAdd(toFolder: folder) ?? false) && folder?.isRoomListFolder != true,
                    onTapHandler: { [weak self] in
                        self?.createFolder()
                    }
                )
            )
        }
        if enableDisplayCreateFillFormRoomBarButton {
            items.append(
                ASCTransferViewModel.BarButtonItem(
                    title: NSLocalizedString("New room", comment: ""),
                    type: .plain,
                    isEnabled: folder?.isRoomListFolder ?? false,
                    onTapHandler: { [weak self] in
                        self?.createFillFormRoom()
                    }
                )
            )
        }
        if !actionButtonTitle.isEmpty {
            items.append(
                ASCTransferViewModel.BarButtonItem(
                    title: actionButtonTitle,
                    type: .plain,
                    isEnabled: isActionButtonEnabled,
                    onTapHandler: { [weak self] in
                        self?.onDone()
                    }
                )
            )
        }
        return items
    }

    func mapTableData() -> ASCTransferViewModel.TableData {
        ASCTransferViewModel.TableData(
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
                                view: transferVC,
                                provider: provider?.copy(),
                                folder: folder,
                                path: path.appendingPathComponent(folder.title)
                            )
                            transferVC.presenter = presenter
                            view?.navigationController?.pushViewController(transferVC, animated: true)
                        }
                    )
                } else if let file = entity as? ASCFile {
                    return .file(
                        ASCTransferFileModel(
                            image: .getFileExtensionBasedImage(
                                fileExt: file.title.fileExtension().lowercased(),
                                layoutType: .list
                            ),
                            title: file.title,
                            onTapAction: { [weak self] in
                                guard let self else { return }
                                if let nc = view?.navigationController as? ASCTransferNavigationController {
                                    nc.onFileSelection?(file)
                                }
                                view?.dismiss(animated: true, completion: nil)
                            }
                        )
                    )
                }
                return nil
            }
        )
    }

    // MARK: Support funcs

    func getImage(forFolder folder: ASCFolder, provider: ASCFileProviderProtocol?) -> UIImage? {
        guard folder.parent == nil else {
            if folder.isRoom {
                return folder.roomType?.image ?? Asset.Images.listFolder.image
            }
            return Asset.Images.listFolder.image
        }
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
        case .onlyofficeRoomShared:
            folderImage = Asset.Images.categoryRoom.image
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
        guard let sourceItems = flowModel?.sourceItems else { return true }
        return sourceItems.first(where: { $0.id == folder.id }) == nil
    }

    func copy(view: ASCTransferView, provider: ASCFileProviderProtocol?, folder: ASCFolder, path: String) -> ASCTransferPresenter {
        ASCTransferPresenter(
            view: view,
            provider: provider,
            transferType: transferType,
            enableFillRootFolders: enableFillRootFolders,
            folder: folder,
            path: path,
            flowModel: flowModel,
            needLoadFirstPage: true
        )
    }

    func createFolder() {
        guard let provider, let viewController = view else { return }
        var hud: MBProgressHUD?

        ASCEntityManager.shared.createFolder(for: provider, in: folder, handler: { [weak self] status, entity, error in
            guard let self else { return }
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.label.text = NSLocalizedString("Creating", comment: "Caption of the process")
            } else if status == .error {
                hud?.hide(animated: true)

                if let error {
                    UIAlertController.showError(in: viewController, message: error.localizedDescription)
                }
            } else if status == .end {
                if let entity = entity as? ASCEntity {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: .standardDelay)
                    items.insert((provider, entity), at: 0)
                    build()
                } else {
                    hud?.hide(animated: false)
                }
            }
        })
    }

    func createFillFormRoom() {
        let roomName = NSLocalizedString("New form filling", comment: "Suggested a room name when create a new one")

        let alertController = UIAlertController(title: NSLocalizedString("New form filling room", comment: ""), message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel) { action in
            if let textField = alertController.textFields?.first {
                textField.selectedTextRange = nil
            }
        }
        var hud: MBProgressHUD?
        let createAction = UIAlertAction(title: NSLocalizedString("Create", comment: "")) { action in
            if let textField = alertController.textFields?.first {
                textField.selectedTextRange = nil

                if var folderTitle = textField.text?.validPathName {
                    if folderTitle.isEmpty {
                        folderTitle = roomName
                    }

                    hud = MBProgressHUD.showTopMost()
                    hud?.label.text = NSLocalizedString("Creating", comment: "Caption of the process")

                    ServicesProvider.shared.roomCreateService.createRoom(
                        model: CreatingRoomModel(
                            roomType: .fillingForm,
                            name: folderTitle,
                            tags: []
                        )
                    ) { [weak self] result in
                        guard let self else { return }
                        switch result {
                        case let .success(folder):
                            hud?.setSuccessState()
                            hud?.hide(animated: false, afterDelay: .standardDelay)
                            var folder = folder
                            folder.parent = self.folder?.parent
                            items.insert((provider, folder), at: 0)
                            build()
                        case let .failure(error):
                            hud?.hide(animated: false)
                            if let view {
                                UIAlertController.showError(in: view, message: error.localizedDescription)
                            }
                        }
                    }
                }
            }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(createAction)
        alertController.addTextField { textField in
            textField.delegate = ASCEntityManager.shared
            textField.text = roomName

            textField.add(for: .editingChanged) {
                let name = (textField.text ?? "").trimmed
                let isEnabled = !name.isEmpty && !(name == "." || name == "..")

                createAction.isEnabled = isEnabled
            }

            delay(seconds: 0.3) {
                textField.selectAll(nil)
            }
        }

        if let topVC = ASCViewControllerManager.shared.topViewController {
            alertController.view.tintColor = Asset.Colors.brend.color
            topVC.present(alertController, animated: true, completion: nil)
        }
    }
}
