//
//  ManageRoomViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 23.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import UIKit
import MBProgressHUD

enum ManageRoomScreenMode {
    case create
    case edit(ASCFolder)
    case saveAsTemplate(ASCFolder)
}

class ManageRoomViewModel: ObservableObject {
    // MARK: Published vars

    @Published var roomName: String = ""
    @Published var roomOwnerName: String = ""
    @Published var isSaving = false
    @Published var isConnecting = false
    @Published var hideHud = false
    @Published var isSavedSuccessfully = false
    @Published var errorMessage: String?
    @Published var selectedRoomType: RoomTypeModel
    @Published var selectedImage: UIImage?
    @Published var tags: Set<String> = []
    @Published var activeAlert: ManageRoomView.ActiveAlert?
    @Published var resultModalModel: ResultViewModel?

    // Stroage quota
    @Published var allowChangeStorageQuota: Bool = false
    @Published var isStorateQuotaEnabled: Bool = false
    @Published var sizeQuota: Double = 40
    @Published var selectedSizeUnit: SizeUnit = .mb

    // MARK: Published Virtual data room only vars

    @Published var isAutomaticIndexing: Bool = false

    // File lifetime
    @Published var isFileLifetimeEnabled: Bool = false
    @Published var fileAge = 12
    @Published var selectedTemePeriod: FilesTimePeriod = .days
    @Published var actionOnFiles: ActionOnFile = .trash

    @Published var isRestrictContentCopy: Bool = false

    // Watermark
    @Published var isWatermarkEnabled: Bool = false
    @Published var selectedWatermarkType: WatermarkType = .viewerInfo
    @Published var selectedWatermarkPosition: WatermarkPosition = .diagonal
    @Published var watermarkElementButtons: [ToggleButtonView.ViewModel] = []
    @Published var watermarkStaticText: String = ""
    @Published var watermarkImage: UIImage?
    @Published var selectedWatermarkImageScale: WatermarkImageScale = .x1
    @Published var selectedWatermarkImageRotationAngle: WatermarkImageRotationAngle = .a0

    // MARK: Published Public room only vars

    // Thirdpart
    @Published var selectedStorage: String?
    @Published var isCreateNewFolderEnabled: Bool = false
    @Published var selectedLocation: String = NSLocalizedString("Root folder", comment: "")

    // MARK: Published Navigation vars

    @Published var isRoomSelectionPresenting = false
    @Published var isUserSelectionPresenting = false
    @Published var isStorageSelectionPresenting = false
    @Published var isFolderSelectionPresenting = false

    // MARK: - Public vars

    var newRoomOwner: ASCUser?
    var ignoreUserId: String?

    var isRoomOwnerCellTappable: Bool {
        editingRoom?.security.changeOwner == true
    }

    private(set) var sizeQuotaFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        formatter.minimum = 1
        return formatter
    }()

    var quotaSizeUnitMenuItems: [MenuViewItem] {
        SizeUnit.allCases.map { value in
            MenuViewItem(
                text: value.localizedDesc,
                systemImageName: selectedSizeUnit == value ? "checkmark" : nil
            ) { [unowned self] in
                selectedSizeUnit = value
            }
        }
    }

    lazy var menuItems: [MenuViewItem] = makeImageMenuItems()
    let hideActivityOnSuccess: Bool
    var isEditMode: Bool { editingRoom != nil }
    var editingRoomImage: URL? {
        if let urlStr = editingRoom?.logo?.small,
           !urlStr.isEmpty,
           let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed
        {
            return URL(string: portal + urlStr)
        }
        return nil
    }
    var screenMode: ManageRoomScreenMode

    var isSaveBtnEnabled: Bool {
        roomName.isEmpty || isSaving
    }

    var isThirdPartyStorageEnabled: Bool {
        provider != nil
    }

    // MARK: Virtual data room menu vars

    private(set) var fileAgeNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        formatter.usesGroupingSeparator = false
        formatter.minimum = 1
        return formatter
    }()

    var filesTimePeriodMenuItems: [MenuViewItem] {
        FilesTimePeriod.allCases.map { value in
            MenuViewItem(
                text: value.localizedDesc,
                systemImageName: selectedTemePeriod == value ? "checkmark" : nil
            ) { [unowned self] in
                selectedTemePeriod = value
            }
        }
    }

    var actionOnFilesMenuItems: [MenuViewItem] {
        ActionOnFile.allCases.map { value in
            MenuViewItem(
                text: value.localizedDesc,
                systemImageName: actionOnFiles == value ? "checkmark" : nil
            ) { [unowned self] in
                actionOnFiles = value
            }
        }
    }

    var watermarkTypeMenuItems: [MenuViewItem] {
        WatermarkType.allCases.map { type in
            MenuViewItem(
                text: type.localizedDesc,
                systemImageName: selectedWatermarkType == type ? "checkmark" : nil
            ) { [unowned self] in
                selectedWatermarkType = type
            }
        }
    }

    var watermarkPositionMenuItems: [MenuViewItem] {
        WatermarkPosition.allCases.map { position in
            MenuViewItem(
                text: position.localizedDesc,
                systemImageName: selectedWatermarkPosition == position ? "checkmark" : nil
            ) { [unowned self] in
                selectedWatermarkPosition = position
            }
        }
    }

    var watermarkImageScaleMenuItems: [MenuViewItem] {
        WatermarkImageScale.allCases.map { scale in
            MenuViewItem(
                text: scale.localizedDesc,
                systemImageName: selectedWatermarkImageScale == scale ? "checkmark" : nil
            ) { [unowned self] in
                selectedWatermarkImageScale = scale
            }
        }
    }

    var watermarkImageRotationMenuItems: [MenuViewItem] {
        WatermarkImageRotationAngle.allCases.map { angle in
            MenuViewItem(
                text: angle.localizedDesc,
                systemImageName: selectedWatermarkImageRotationAngle == angle ? "checkmark" : nil
            ) { [unowned self] in
                selectedWatermarkImageRotationAngle = angle
            }
        }
    }

    @Published var selectedWatermarkElements: Set<WatermarkElement> = []

    // MARK: - Private vars

    private var onCreate: (ASCFolder) -> Void
    private let editingRoom: ASCRoom?
    private(set) var provider: ASCFileProviderProtocol?
    private(set) var thirdPartyFolder: ASCFolder?
    private var selectedSubfolder: ASCFolder?
    private var selectedLocationPath: String = ""
    private var cancelable = Set<AnyCancellable>()
    private var watermarkImageWasChanged: Bool = false
    private var isFilesLifetimeWarningViewed: Bool = false
    private var quotaSizeInBytes: Double? {
        guard allowChangeStorageQuota else { return nil }
        return isStorateQuotaEnabled
            ? SizeUnit.bytes(from: sizeQuota, unit: selectedSizeUnit)
            : -1
    }

    private lazy var creatingRoomService = ServicesProvider.shared.roomCreateService
    private lazy var roomQuotaNetworkService = ServicesProvider.shared.roomQuotaNetworkService
    private lazy var roomTemplatesNetworkService = ServicesProvider.shared.roomTemplatesNetworkService

    // MARK: - Init

    init(
        screenMode: ManageRoomScreenMode,
        selectedRoomType: RoomTypeModel,
        roomName: String = "",
        hideActivityOnSuccess: Bool = true,
        onCreate: @escaping (ASCFolder) -> Void
    ) {
        self.selectedRoomType = selectedRoomType
        self.hideActivityOnSuccess = hideActivityOnSuccess
        self.onCreate = onCreate
        self.screenMode = screenMode

        switch screenMode {
        case .edit(let editingRoom), .saveAsTemplate(let editingRoom):
            self.editingRoom = editingRoom
            self.selectedRoomType.showDisclosureIndicator = false
            self.roomName = editingRoom.title
            roomOwnerName = editingRoom.createdBy?.displayName ?? ""
            ignoreUserId = editingRoom.createdBy?.userId
            tags = Set(editingRoom.tags ?? [])
            isAutomaticIndexing = editingRoom.indexing
            isRestrictContentCopy = editingRoom.denyDownload
            isFileLifetimeEnabled = editingRoom.lifetime != nil
            fileAge = editingRoom.lifetime?.value ?? fileAge
            selectedTemePeriod = FilesTimePeriod(
                rawValue: editingRoom.lifetime?.period ?? selectedTemePeriod.rawValue
            ) ?? selectedTemePeriod
            actionOnFiles = editingRoom.lifetime?.deletePermanently == true ? .remove : .trash
            if let watermark = editingRoom.watermark {
                isWatermarkEnabled = true
                if let watermarkImageUrl = watermark.imageUrl {
                    selectedWatermarkType = .image
                    watermarkImage = {
                        guard let url = URL(string: watermarkImageUrl),
                              let image = UIImage(url: url)
                        else { return watermarkImage }
                        return image
                    }()
                    selectedWatermarkPosition = {
                        guard let rotate = watermark.rotate,
                              let position = WatermarkPosition(rawValue: rotate)
                        else { return selectedWatermarkPosition }
                        return position
                    }()
                    selectedWatermarkImageScale = {
                        guard let scaleValue = watermark.imageScale,
                              let imageScale = WatermarkImageScale(rawValue: Double(scaleValue))
                        else { return selectedWatermarkImageScale }
                        return imageScale
                    }()
                    selectedWatermarkImageRotationAngle = {
                        guard let angleValue = watermark.rotate,
                              let rotationAngle = WatermarkImageRotationAngle(rawValue: Double(angleValue))
                        else { return selectedWatermarkImageRotationAngle }
                        return rotationAngle
                    }()
                } else {
                    selectedWatermarkType = .viewerInfo
                    if let additions = watermark.additions {
                        for selectedElement in WatermarkElement.selectedElements(from: additions) {
                            selectedWatermarkElements.insert(selectedElement)
                        }
                    }
                    watermarkStaticText = {
                        guard let text = watermark.text else {
                            return watermarkStaticText
                        }
                        return text
                    }()
                }
            }

        default:
            self.roomName = roomName
            self.editingRoom = nil
        }

        selectedWatermarkElements.insert(.userName)
        setupWatermarkElementButtons()

        $isCreateNewFolderEnabled
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.configureSelectedLocation()
            })
            .store(in: &cancelable)

        $isFileLifetimeEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] isOn in
                guard let self, isOn, isEditMode, !isFilesLifetimeWarningViewed
                else { return }
                isFilesLifetimeWarningViewed = true
                activeAlert = .filesLifetimeWarning
            }
            .store(in: &cancelable)

        $errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                guard let self else { return }
                if let message, !message.isEmpty {
                    activeAlert = .errorMessage
                } else {
                    activeAlert = nil
                }
            }
            .store(in: &cancelable)

        $roomName
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.configureSelectedLocation()
            })
            .store(in: &cancelable)

        $isStorateQuotaEnabled
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] isOn in
                guard let self else { return }
                if isOn, sizeQuota < 0 {
                    sizeQuota = 40
                }
            })
            .store(in: &cancelable)

        $selectedWatermarkType
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                guard let self else { return }
                if value != .viewerInfo {
                    watermarkElementButtons.inoutForEach { $0.isActive = false }
                    watermarkStaticText = ""
                    selectedWatermarkPosition = .diagonal
                }
            }
            .store(in: &cancelable)

        Task { @MainActor in
            if let roomsQuota = await roomQuotaNetworkService.loadRoomsQouta(),
               let roomsQuotaValue = roomsQuota.defaultQuota
            {
                let currentRoomQuote = editingRoom?.quotaLimit
                let bytes = {
                    guard let currentRoomQuote, currentRoomQuote >= 0 else { return roomsQuotaValue }
                    return currentRoomQuote
                }()
                let (size, unit) = SizeUnit.formatBytes(bytes)
                allowChangeStorageQuota = roomsQuota.enableQuota == true
                    && selectedRoomType.type == .virtualData
                isStorateQuotaEnabled = {
                    guard let room = editingRoom else { return true }
                    return room.isCustomQuota == true
                        && (currentRoomQuote ?? -1) >= 0
                }()
                sizeQuota = size
                selectedSizeUnit = unit
            }
        }
    }

    // MARK: - Public func

    func save(ignoreNoWatermark: Bool = false) {
        guard ignoreNoWatermark
            || selectedRoomType.type != .virtualData
            || selectedWatermarkType != .image
            || watermarkImage != nil
        else {
            activeAlert = .saveWithoutWatermark
            return
        }

        isSaving = true
        
        switch screenMode {
        case .create:
            createRoom()
        case .edit(_):
            updateRoom()
        case .saveAsTemplate(_):
            createTemplate()
        }
    }

    func configureSelectedLocation() {
        let basePath: String = selectedLocationPath.isEmpty
            ? NSLocalizedString("Root folder", comment: "")
            : selectedLocationPath
        var location = basePath
        if isCreateNewFolderEnabled {
            let newFolderName = roomName.isEmpty
                ? NSLocalizedString("New folder", comment: "")
                : roomName
            location = location.appendingPathComponent(newFolderName)
        }
        selectedLocation = location
    }
}

// MARK: - Handlers

extension ManageRoomViewModel {
    func didTapRoomOwnerCell() {
        guard isRoomOwnerCellTappable else { return }
        isUserSelectionPresenting = true
    }

    func didTapStorageSelectionCell() {
        isStorageSelectionPresenting = true
    }

    func didTapSelectedFolderCell() {
        isFolderSelectionPresenting = true
    }

    func didCloudProviderLoad(info: [String: Any]) {
        var info = info
        let providerType: ASCFolderProviderType? = {
            guard let providerKey = info["providerKey"] as? String else { return nil }
            return ASCFolderProviderType(rawValue: providerKey)
        }()
        if let providerType, ASCConnectPortalThirdPartyViewController.webDavProviderTypes.contains(providerType) {
            info["providerKey"] = ASCFolderProviderType.webDav.rawValue
        }
        isConnecting = true
        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.ThirdPartyIntegration.connect, info) { [weak self] response, error in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if let error = error {
                    log.error(error)
                    selectedStorage = nil
                    thirdPartyFolder = nil
                    errorMessage = error.localizedDescription
                } else if let folder = response?.result {
                    let provider = ASCThirdpartySelectFolderProvider(
                        rootFolder: folder,
                        type: providerType?.fileProviderType ?? .webdav
                    )
                    self.provider = provider
                    self.selectedStorage = providerType?.rawValue ?? folder.title
                    thirdPartyFolder = folder
                }
                isConnecting = false
            }
        }
    }

    func selectFolder(subfolder: ASCFolder?, path: String?) {
        guard let subfolder, let thirdPartyFolder else { return }
        if subfolder.id == thirdPartyFolder.id {
            selectedLocation = NSLocalizedString("Root folder", comment: "")
            selectedSubfolder = nil
            selectedLocationPath = ""
        } else {
            selectedLocationPath = path ?? ""
            selectedLocation = path ?? subfolder.title
            selectedSubfolder = subfolder
        }
        configureSelectedLocation()
    }

    func didTapThirdPartyStorageSwitch(isOn: Bool) {
        if isOn {
            isStorageSelectionPresenting = true
        } else {
            provider = nil
            isStorageSelectionPresenting = false
        }
    }

    func didTapWatermarkImage() {
        imageFromLibraryAction { [weak self] in
            self?.watermarkImage = $0
            self?.watermarkImageWasChanged = true
        }
    }

    func didTapRemoveWatemarkImage() {
        watermarkImage = nil
        editingRoom?.watermark?.imageUrl = nil
    }

    func didPrimaryActionTappedOnNoWatermarkAlert() {
        save(ignoreNoWatermark: true)
    }
}

// MARK: - Private func

private extension ManageRoomViewModel {
    func setupWatermarkElementButtons() {
        watermarkElementButtons = WatermarkElement.allCases.map { element in
            ToggleButtonView.ViewModel(
                id: String(element.id),
                title: element.localizedDesc,
                isActive: selectedWatermarkElements.contains(element),
                tapHandler: { [weak self] id in
                    if let id = Int(id), let element = WatermarkElement(rawValue: id) {
                        self?.handleWatermarkElementTap(element: element)
                    }
                }
            )
        }
    }

    func handleWatermarkElementTap(element: WatermarkElement) {
        if selectedWatermarkElements.contains(element) {
            selectedWatermarkElements.remove(element)
        } else {
            selectedWatermarkElements.insert(element)
        }
        if let index = watermarkElementButtons.firstIndex(where: { $0.id == String(element.id) }) {
            watermarkElementButtons[index].isActive = selectedWatermarkElements.contains(element)
        }
    }

    // MARK: Create room

    func createRoom() {
        let roomName = roomName
        isSaving = true
        creatingRoomService.createRoom(
            model: CreatingRoomModel(
                roomType: selectedRoomType.type.ascRoomType,
                name: roomName,
                image: selectedImage,
                tags: tags.map { $0 },
                createAsNewFolder: isCreateNewFolderEnabled,
                thirdPartyFolderId: selectedSubfolder?.id ?? thirdPartyFolder?.id,
                isAutomaticIndexing: isAutomaticIndexing,
                isRestrictContentCopy: isRestrictContentCopy,
                fileLifetime: makeFileLifetimeModel(),
                watermark: makeWatermarkRequestModel(),
                watermarkImage: selectedWatermarkType == .image ? watermarkImage : nil,
                quota: quotaSizeInBytes
            )
        ) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isSaving = false

                switch result {
                case let .success(room):
                    self.resultModalModel = .init(
                        result: .success,
                        message: NSLocalizedString("Done", comment: "")
                    )
                    room.title = roomName
                    self.onCreate(room)

                case let .failure(error):
                    self.resultModalModel = .init(
                        result: .failure,
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    
    //MARK: - Create room template
    
    func createTemplate() {
        roomTemplatesNetworkService.createTemplate(room: CreateRoomTemplateModel(
            title: roomName,
            roomId: editingRoom?.id,
            tags: Array(tags),
            public: false,
            copylogo: true,
            color: editingRoom?.logo?.color)) { [weak self] status, progress, result, error, cancel in
                guard let self else { return }
                switch status {
                case .begin:
                    break
                    
                case .progress:
                    DispatchQueue.main.async {
                        MBProgressHUD.currentHUD?.progress = progress
                    }
                    
                case .error:
                    DispatchQueue.main.async {
                        self.resultModalModel = .init(
                            result: .failure,
                            message: error?.localizedDescription ?? NSLocalizedString("Could not create the template.", comment: "")
                        )
                    }
                    self.isSaving = false
                case .end:
                    DispatchQueue.main.async {
                        self.resultModalModel = .init(
                            result: .success,
                            message: NSLocalizedString("Template \(self.roomName) saved", comment: "")
                        )
                        self.isSaving = false
                    }
                }
                if let editingRoom {
                    onCreate(editingRoom)
                }
            }
    }

    func makeFileLifetimeModel() -> CreateRoomRequestModel.FileLifetime? {
        guard isFileLifetimeEnabled else { return nil }
        return CreateRoomRequestModel.FileLifetime(
            fileAge: fileAge,
            deletePermanently: actionOnFiles == .remove,
            periodType: CreateRoomRequestModel.FileLifetime.PeriodType(
                rawValue: selectedTemePeriod.rawValue
            ) ?? .days
        )
    }

    func makeWatermarkRequestModel() -> CreateRoomRequestModel.Watermark? {
        guard isWatermarkEnabled else { return nil }
        if selectedWatermarkType == .viewerInfo {
            return CreateRoomRequestModel.Watermark(
                rotate: selectedWatermarkPosition.rawValue,
                text: watermarkStaticText,
                additions: selectedWatermarkElements.map(\.rawValue).reduce(0, +)
            )
        } else if selectedWatermarkType == .image {
            return CreateRoomRequestModel.Watermark(
                rotate: Int(selectedWatermarkImageRotationAngle.rawValue),
                imageScale: Int(selectedWatermarkImageScale.rawValue),
                imageUrl: editingRoom?.watermark?.imageUrl,
                imageWidth: editingRoom?.watermark?.imageWidth,
                imageHeight: editingRoom?.watermark?.imageHeight
            )
        }
        return nil
    }

    // MARK: Update room

    func updateRoom() {
        guard let room = editingRoom else {
            isSaving = false
            return
        }

        creatingRoomService.editRoom(
            model: EditRoomModel(
                roomType: selectedRoomType.type.ascRoomType,
                room: room,
                name: roomName,
                image: selectedImage,
                ownerToChange: newRoomOwner,
                tagsToAdd: Array(tags.subtracting(room.tags ?? [])),
                tagsToDelete: Array(Set(room.tags ?? []).subtracting(tags)),
                isAutomaticIndexing: isAutomaticIndexing,
                isRestrictContentCopy: isRestrictContentCopy,
                fileLifetime: makeFileLifetimeModel(),
                watermark: makeWatermarkRequestModel(),
                watermarkImage: watermarkImage,
                watermarkImageWasChanged: watermarkImageWasChanged,
                quota: quotaSizeInBytes
            )
        ) { [weak self] result in
            switch result {
            case let .success(room):
                self?.onCreate(room)
            case let .failure(error):
                self?.errorMessage = error.localizedDescription
            }
            self?.isSaving = false
        }
    }

    // MARK: Room image

    func makeImageMenuItems() -> [MenuViewItem] {
        var menu: [MenuViewItem] = [
            .init(
                text: NSLocalizedString("Photo Library", comment: ""),
                systemImageName: "photo",
                action: { [weak self] in
                    self?.imageFromLibraryAction { [weak self] in
                        self?.selectedImage = $0
                    }
                }
            ),
            .init(text: NSLocalizedString("Take Photo", comment: ""), systemImageName: "camera", action: imageFromCameraAction),
            .init(text: NSLocalizedString("Choose Files", comment: ""), systemImageName: "folder", action: imageFromFilesAction),
        ]
        if selectedImage != nil || editingRoom?.logo?.small != nil {
            menu.append(.init(
                text: NSLocalizedString("Remove", comment: ""),
                systemImageName: "trash",
                color: .red,
                action: { [unowned self] in
                    selectedImage = nil
                    editingRoom?.logo?.small = nil
                }
            ))
        }
        return menu
    }

    func imageFromLibraryAction(completion: @escaping (UIImage?) -> Void) {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromLibrary(in: topController, to: temporaryFolderName) { [weak self] result in
            self?.handleImageSelection(result, imageCompletion: completion)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }

    func imageFromCameraAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromCamera(in: topController, to: temporaryFolderName) { [weak self] result in
            self?.handleImageSelection(result) {
                self?.selectedImage = $0
            }
            attachManager.cleanup(for: temporaryFolderName)
        }
    }

    func imageFromFilesAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromFiles(in: topController, to: temporaryFolderName) { [weak self] result in
            self?.handleImageSelection(result) {
                self?.selectedImage = $0
            }
            attachManager.cleanup(for: temporaryFolderName)
        }
    }

    func handleImageSelection(_ result: Result<URL, Error>, imageCompletion: (UIImage?) -> Void) {
        switch result {
        case let .success(url):
            imageCompletion(UIImage(contentsOfFile: url.path))
        case let .failure(error):
            if let error = error as? ASCAttachmentManagerError, error == .canceled {
                return
            }
            errorMessage = error.localizedDescription
            imageCompletion(nil)
        }
    }

    func topController() -> UIViewController? {
        if var topController = UIWindow.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
}

// MARK: - Extension ASCFolderProviderType

private extension ASCFolderProviderType {
    var fileProviderType: ASCFileProviderType {
        switch self {
        case .boxNet:
            .webdav
        case .dropBox:
            .dropbox
        case .google, .googleDrive:
            .googledrive
        case .sharePoint:
            .webdav
        case .skyDrive:
            .webdav
        case .oneDrive:
            .onedrive
        case .webDav:
            .webdav
        case .yandex:
            .yandex
        case .nextCloud:
            .nextcloud
        case .ownCloud:
            .owncloud
        case .iCloud:
            .icloud
        case .kDrive:
            .kdrive
        }
    }
}

// MARK: - Extension types

extension ManageRoomViewModel {
    enum FilesTimePeriod: Int, CaseIterable {
        case days
        case months
        case years

        var localizedDesc: String {
            switch self {
            case .days:
                NSLocalizedString("Days", comment: "")
            case .months:
                NSLocalizedString("Months", comment: "")
            case .years:
                NSLocalizedString("Years", comment: "")
            }
        }
    }

    enum ActionOnFile: CaseIterable {
        case trash
        case remove

        var localizedDesc: String {
            switch self {
            case .trash:
                NSLocalizedString("Move to trash", comment: "")
            case .remove:
                NSLocalizedString("Delete permanently", comment: "")
            }
        }
    }

    enum WatermarkType: CaseIterable {
        case viewerInfo
        case image

        var localizedDesc: String {
            switch self {
            case .viewerInfo:
                return NSLocalizedString("Viewer info", comment: "Watermark Type")
            case .image:
                return NSLocalizedString("Image", comment: "Watermark Type")
            }
        }
    }

    enum WatermarkPosition: Int, CaseIterable {
        case diagonal = -45
        case horizontal = 0

        var localizedDesc: String {
            switch self {
            case .diagonal:
                return NSLocalizedString("Diagonal", comment: "Watermark Position")
            case .horizontal:
                return NSLocalizedString("Horizontal", comment: "Watermark Position")
            }
        }
    }

    enum WatermarkElement: Int, CaseIterable {
        case userName = 1
        case userEmail = 2
        case ipAddress = 4
        case currentDate = 8
        case roomName = 16

        var localizedDesc: String {
            switch self {
            case .userName:
                return NSLocalizedString("User Name", comment: "Watermark Element")
            case .userEmail:
                return NSLocalizedString("User Email", comment: "Watermark Element")
            case .ipAddress:
                return NSLocalizedString("Use IP Address", comment: "Watermark Element")
            case .currentDate:
                return NSLocalizedString("Current Date", comment: "Watermark Element")
            case .roomName:
                return NSLocalizedString("Room Name", comment: "Watermark Element")
            }
        }

        var id: Int {
            rawValue
        }
    }

    enum WatermarkImageScale: Double, CaseIterable {
        case x1 = 100
        case x2 = 200
        case x3 = 300
        case x4 = 400
        case x5 = 500

        var localizedDesc: String {
            "\(Int(rawValue))%"
        }
    }

    enum WatermarkImageRotationAngle: Double, CaseIterable {
        case a0 = 0
        case a30 = -30
        case a45 = -45
        case a60 = -60
        case a90 = -90

        var localizedDesc: String {
            "\(Int(rawValue))°"
        }
    }

    enum SizeUnit: CaseIterable {
        case bytes
        case kb
        case mb
        case gb
        case tb

        var localizedDesc: String {
            switch self {
            case .bytes:
                return NSLocalizedString("bytes", comment: "Measurement unit")
            case .kb:
                return NSLocalizedString("KB", comment: "Measurement unit")
            case .mb:
                return NSLocalizedString("MB", comment: "Measurement unit")
            case .gb:
                return NSLocalizedString("GB", comment: "Measurement unit")
            case .tb:
                return NSLocalizedString("TB", comment: "Measurement unit")
            }
        }
    }
}

private extension ManageRoomViewModel.SizeUnit {
    typealias SizeUnit = ManageRoomViewModel.SizeUnit

    static func formatBytes(_ bytes: Double) -> (value: Double, unit: SizeUnit) {
        let units: [SizeUnit] = [.bytes, .kb, .mb, .gb, .tb]
        var value = bytes
        var unit = SizeUnit.bytes

        for nextUnit in units {
            if value < 1024 || nextUnit == .tb {
                unit = nextUnit
                break
            }
            value /= 1024
        }

        return (value: value, unit: unit)
    }

    static func bytes(from value: Double, unit: SizeUnit) -> Double {
        switch unit {
        case .bytes:
            return value
        case .kb:
            return value * 1024
        case .mb:
            return value * pow(1024, 2)
        case .gb:
            return value * pow(1024, 3)
        case .tb:
            return value * pow(1024, 4)
        }
    }
}

extension ManageRoomViewModel.WatermarkElement {
    static func selectedElements(from value: Int) -> [ManageRoomViewModel.WatermarkElement] {
        ManageRoomViewModel.WatermarkElement.allCases.filter { element in
            (value & element.rawValue) != 0
        }
    }
}
