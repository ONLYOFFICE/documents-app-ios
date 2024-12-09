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

    // Stroage quota
    @Published var allowChangeStorageQuota: Bool = false
    @Published var isStorateQuotaEnabled: Bool = false
    @Published var sizeQuota: Double = 40
    @Published var selectedSizeUnit: SizeUnit = .mb

    // MARK: Published Virtual data room only vars

    // File lifetime
    @Published var isAutomaticIndexing: Bool = false
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
    private var roomQuota: ASCPaymentQuotaSettings?

    private lazy var creatingRoomService = ServicesProvider.shared.roomCreateService
    private lazy var roomQuotaNetworkService = ServicesProvider.shared.roomQuotaNetworkService

    // MARK: - Init

    init(
        editingRoom: ASCRoom? = nil,
        selectedRoomType: RoomTypeModel,
        roomName: String = "",
        hideActivityOnSuccess: Bool = true,
        onCreate: @escaping (ASCFolder) -> Void
    ) {
        self.editingRoom = editingRoom
        self.selectedRoomType = selectedRoomType
        self.hideActivityOnSuccess = hideActivityOnSuccess
        self.onCreate = onCreate

        if let editingRoom {
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
        } else {
            self.roomName = roomName
        }

        selectedWatermarkElements.insert(.userName)
        setupWatermarkElementButtons()

        $isCreateNewFolderEnabled
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.configureSelectedLocation()
            })
            .store(in: &cancelable)

        $roomName
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.configureSelectedLocation()
            })
            .store(in: &cancelable)

        Task { @MainActor in
            if let roomQuota = await roomQuotaNetworkService.loadRoomsQouta(),
               let quota = roomQuota.defaultQuota
            {
                let (size, unit) = SizeUnit.formatBytes(quota)
                isStorateQuotaEnabled = roomQuota.enableQuota == true
                sizeQuota = size
                selectedSizeUnit = unit
                allowChangeStorageQuota = true
                self.roomQuota = roomQuota
            }
        }
    }

    // MARK: - Public func

    func save() {
        isSaving = true
        if isEditMode {
            updateRoom()
        } else {
            createRoom()
        }
        saveQuotaChanges()
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
        }
    }

    func didTapRemoveWatemarkImage() {
        watermarkImage = nil
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
                watermark: markWatermarkRequestModel(),
                watermarkImage: selectedWatermarkType == .image ? watermarkImage : nil
            )
        ) { [weak self] result in
            self?.isSaving = false
            switch result {
            case let .success(room):
                self?.isSavedSuccessfully = true
                room.title = roomName
                self?.onCreate(room)
            case let .failure(error):
                self?.errorMessage = error.localizedDescription
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

    func markWatermarkRequestModel() -> CreateRoomRequestModel.Watermark? {
        guard isWatermarkEnabled else { return nil }
        if selectedWatermarkType == .viewerInfo {
            return CreateRoomRequestModel.Watermark(
                rotate: selectedWatermarkPosition.rawValue,
                text: watermarkStaticText,
                additions: selectedWatermarkElements.map(\.rawValue).reduce(0, +)
            )
        } else if selectedWatermarkType == .image {
            return CreateRoomRequestModel.Watermark(
                rotate: selectedWatermarkPosition.rawValue,
                imageScale: Int(selectedWatermarkImageScale.rawValue)
            )
        }
        return nil
    }

    // MARK: Quota changes

    func saveQuotaChanges() {
        let quotaSizeInBytes = SizeUnit.bytes(from: sizeQuota, unit: selectedSizeUnit)
        let screenStateRoomQuota = ASCPaymentQuotaSettings(
            enableQuota: isStorateQuotaEnabled,
            defaultQuota: quotaSizeInBytes,
            lastRecalculateDate: roomQuota?.lastRecalculateDate
        )
        guard screenStateRoomQuota != roomQuota else { return }

        Task { [roomQuotaNetworkService] in
            await roomQuotaNetworkService.setupRoomsQuota(model: screenStateRoomQuota)
        }
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
                tagsToDelete: Array(Set(room.tags ?? []).subtracting(tags))
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
        [
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
