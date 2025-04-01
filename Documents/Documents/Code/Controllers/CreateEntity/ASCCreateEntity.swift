//
//  ASCCreateEntity.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/30/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import AVFoundation
import CoreServices
import MBProgressHUD
import SwiftMessages
import UIKit
import VisionKit

class ASCCreateEntity: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Properties

    private var provider: ASCFileProviderProtocol?
    private var parent: ASCDocumentsViewController?

    override init() {
        super.init()
    }

    init(provider: ASCFileProviderProtocol?) {
        self.provider = provider
        super.init()
    }

    // MARK: - Lifecycle Methods

    func showCreateController(for provider: ASCFileProviderProtocol, in viewController: ASCDocumentsViewController, sender: Any? = nil) {
        self.provider = provider
        parent = viewController

        if let provider = provider as? ASCOnlyofficeProvider,
           provider.apiClient.serverVersion?.docSpace != nil,
           provider.folder?.isRoomListFolder == true
        {
            showCreateRoomController(provider: provider, viewController: viewController)
            return
        }

        let allowClouds = {
            guard let provider = provider as? ASCOnlyofficeProvider,
                  provider.apiClient.serverVersion?.docSpace == nil
            else { return false }
            return provider.apiClient.active
        }()

        let allowForms = {
            guard let provider = provider as? ASCOnlyofficeProvider,
                  let folder = provider.folder,
                  provider.apiClient.serverVersion?.docSpace != nil
            else { return false }

            return folder.isRoomListSubfolder && folder.parentsFoldersOrCurrentContains(
                keyPath: \.roomType,
                value: .fillingForm
            )
        }()

        let allowScanDocument = VNDocumentCameraViewController.isSupported

        var createEntityVC: ASCCreateEntityUIViewController!

        if ASCViewControllerManager.shared.phoneLayout {
            createEntityVC = ASCCreateEntityUIViewController(
                allowClouds: allowClouds,
                allowForms: allowForms,
                allowScanDocument: allowScanDocument,
                onAction: { type in
                    SwiftMessages.hide()
                    self.createEntity(type, in: viewController)
                }
            )

            var config = SwiftMessages.defaultConfig
            config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            config.duration = .forever
            config.presentationStyle = .bottom
            config.dimMode = .gray(interactive: true)
            config.overrideUserInterfaceStyle = AppThemeService.theme.overrideUserInterfaceStyle

            let windowViewController = WindowViewController(config: config)

            config.windowViewController = { config in
                windowViewController
            }

            windowViewController.addChild(createEntityVC)
            guard let createEntityView = createEntityVC.view else { return }
            createEntityVC.didMove(toParent: windowViewController)

            createEntityView.layerCornerRadius = 10

            SwiftMessages.show(config: config, view: createEntityView)
        } else {
            var senderView = sender as? UIView

            if let barButton = sender as? UIBarButtonItem {
                senderView = barButton.customView
            }

            createEntityVC = ASCCreateEntityUIViewController(
                allowClouds: allowClouds,
                allowForms: allowForms,
                allowScanDocument: VNDocumentCameraViewController.isSupported,
                onAction: { type in
                    createEntityVC.dismiss(animated: true) {
                        self.createEntity(type, in: viewController)
                    }
                }
            )

            if let senderView {
                createEntityVC.modalPresentationStyle = .popover
                if allowForms {
                    createEntityVC.preferredContentSize = CGSize(width: 375, height: 200)
                } else {
                    createEntityVC.preferredContentSize = CGSize(width: 375, height: 420 - (allowClouds ? 0 : 50) + (allowScanDocument ? 50 : 0))
                }
                createEntityVC.popoverPresentationController?.backgroundColor = .systemGroupedBackground
                createEntityVC.popoverPresentationController?.sourceView = senderView
                createEntityVC.popoverPresentationController?.sourceRect = senderView.bounds
            }

            viewController.present(createEntityVC, animated: true, completion: nil)
        }
    }

    private func showCreateRoomController(provider: ASCOnlyofficeProvider, viewController: ASCDocumentsViewController) {
        let vc = CreateRoomRouteViewViewController(onAction: { [weak viewController] room in
            viewController?.add(entity: room, open: true)
        })

        if UIDevice.pad {
            vc.isModalInPresentation = true
            vc.modalPresentationStyle = .formSheet
        }

        viewController.present(vc, animated: true, completion: nil)
    }

    private func createEntity(_ type: CreateEntityUIType, in viewController: ASCDocumentsViewController) {
        switch type {
        case .document:
            createFile(ASCConstants.FileExtensions.docx, viewController: viewController)

        case .spreadsheet:
            createFile(ASCConstants.FileExtensions.xlsx, viewController: viewController)

        case .presentation:
            createFile(ASCConstants.FileExtensions.pptx, viewController: viewController)

        case .folder:
            createFolder(viewController: viewController)

        case .importFile:
            loadFile(viewController: viewController)

        case .importImage:
            loadImage(viewController: viewController)

        case .makePicture:
            takePhoto(viewController: viewController)

        case .connectCloud:
            let connectStorageVC = ASCConnectPortalThirdPartyViewController.instantiate(from: Storyboard.connectStorage)
            let connectStorageNavigationVC = ASCBaseNavigationController(rootASCViewController: connectStorageVC)

            connectStorageNavigationVC.modalPresentationStyle = .formSheet
            connectStorageNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize

            viewController.present(connectStorageNavigationVC, animated: true, completion: nil)

        case .pdfDocspace:
            uploadPDFFromDocspace(viewController: viewController)

        case .pdfDevice:
            uploadPDFFromDevice(viewController: viewController)

        case .scanDocument:
            scanDocument(viewController: viewController)
        }
    }

    func createFile(_ fileExtension: String, for provider: ASCFileProviderProtocol?, in viewController: ASCDocumentsViewController) {
        guard let provider else { return }
        self.provider = provider

        createFile(fileExtension, viewController: viewController)
    }

    func createFile(_ fileExtension: String, viewController: ASCDocumentsViewController) {
        guard let provider else { return }
        var hud: MBProgressHUD?

        ASCEntityManager.shared.createFile(for: provider, fileExtension, in: viewController.folder, handler: { status, entity, error in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.label.text = NSLocalizedString("Creating", comment: "Caption of the process")
            } else if status == .error {
                hud?.hide(animated: true)

                if let error {
                    self.showError(message: error.localizedDescription)
                }
            } else if status == .end {
                hud?.hide(animated: false)

                if let entity {
                    viewController.add(entity: entity)
                }
            }
        })
    }

    func createFolder(viewController: ASCDocumentsViewController) {
        guard let provider else { return }
        var hud: MBProgressHUD?

        ASCEntityManager.shared.createFolder(for: provider, in: viewController.folder, handler: { status, entity, error in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.label.text = NSLocalizedString("Creating", comment: "Caption of the process")
            } else if status == .error {
                hud?.hide(animated: true)

                if let error {
                    self.showError(message: error.localizedDescription)
                }
            } else if status == .end {
                if let entity {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: .standardDelay)
                    viewController.add(entity: entity)
                } else {
                    hud?.hide(animated: false)
                }
            }
        })
    }

    func loadFile(viewController: ASCDocumentsViewController) {
        ASCCreateEntityDocumentDelegate.shared.documentsViewController = viewController
        ASCCreateEntityDocumentDelegate.shared.provider = provider

        let documentPicker = UIDocumentPickerViewController(
            documentTypes: [
                String(kUTTypeImage),
                String(kUTTypeText),
                String(kUTTypeContent),
                String(kUTTypeItem),
                String(kUTTypeData),
            ],
            in: .import
        )
//        documentPicker.addOptionWithTitle("Photos", image: nil, order: .First, handler: nil)
        documentPicker.delegate = ASCCreateEntityDocumentDelegate.shared
        viewController.present(documentPicker, animated: true)
    }

    func loadImage(viewController: ASCDocumentsViewController) {
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            return
        }

        ASCCreateEntityImageDelegate.shared.documentsViewController = viewController
        ASCCreateEntityImageDelegate.shared.provider = provider

        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = ASCCreateEntityImageDelegate.shared

        viewController.present(imagePickerController, animated: true, completion: nil)
    }

    func takePhoto(viewController: ASCDocumentsViewController) {
        func showCamera() {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                ASCCreateEntityImageDelegate.shared.documentsViewController = viewController
                ASCCreateEntityImageDelegate.shared.provider = provider

                DispatchQueue.main.async {
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.sourceType = .camera
                    imagePickerController.allowsEditing = false
                    imagePickerController.mediaTypes = [kUTTypeImage as String]
                    imagePickerController.delegate = ASCCreateEntityImageDelegate.shared

                    viewController.present(imagePickerController, animated: true, completion: nil)
                }
            }
        }

        func showAuthorizationAlert() {
            // Camera not available
            let cameraUnavailableAlertController = UIAlertController(
                title: NSLocalizedString("Camera Unavailable", comment: ""),
                message: NSLocalizedString("Please go to Settings and enable the camera for this app to use this feature.", comment: ""),
                preferredStyle: .alert
            )

            let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: ""), style: .cancel, handler: { alert in
                if let settingsUrl = NSURL(string: UIApplication.openSettingsURLString) {
                    DispatchQueue.main.async {
                        UIApplication.shared.open(settingsUrl as URL, options: [:], completionHandler: nil)
                    }
                }
            })
            let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .default, handler: nil)
            cameraUnavailableAlertController.addAction(settingsAction)
            cameraUnavailableAlertController.addAction(cancelAction)
            viewController.present(cameraUnavailableAlertController, animated: true, completion: nil)
        }

        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera()
                    } else {
                        showAuthorizationAlert()
                    }
                }
            })
        } else {
            showCamera()
        }
    }

    func uploadPDFFromDocspace(viewController: ASCDocumentsViewController) {
        let vc = ASCTransferViewController.instantiate(from: Storyboard.transfer)

        let presenter = ASCTransferPresenter(
            view: vc,
            provider: provider?.copy(),
            transferType: .selectFillForms,
            enableFillRootFolders: false,
            folder: .onlyofficeRootFolder
        )
        vc.presenter = presenter
        vc.actionButton.isEnabled = false

        let nc = ASCTransferNavigationController(rootASCViewController: vc)
        nc.onFileSelection = { [provider, weak viewController] file in
            ServicesProvider.shared.copyFileInsideProviderService.copyFileInsideProvider(
                provider: provider,
                file: file,
                viewController: viewController
            )
        }
        nc.displayActionButtonOnRootVC = true
        nc.modalPresentationStyle = .formSheet
        nc.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
        viewController.present(nc, animated: true)
    }

    func uploadPDFFromDevice(viewController: ASCDocumentsViewController) {
        ASCCreateEntityDocumentDelegate.shared.documentsViewController = viewController
        ASCCreateEntityDocumentDelegate.shared.provider = provider
        let documentPicker = UIDocumentPickerViewController(
            documentTypes: [
                String(kUTTypePDF),
            ],
            in: .import
        )
        documentPicker.delegate = ASCCreateEntityDocumentDelegate.shared
        viewController.present(documentPicker, animated: true)
    }

    func scanDocument(viewController: ASCDocumentsViewController) {
        if VNDocumentCameraViewController.isSupported {
            let scanner = VNDocumentCameraViewController()
            scanner.delegate = self
            viewController.present(scanner, animated: true)
        } else {
            UIAlertController.showError(
                in: viewController,
                message: NSLocalizedString("Scanning is not supported on this device", comment: "")
            )
        }
    }

    // MARK: - Private

    private func showError(message: String) {
        if let topVC = ASCViewControllerManager.shared.topViewController {
            UIAlertController.showError(in: topVC, message: message)
        }
    }
}

// MARK: - ASCCreateEntityDocumentDelegate

class ASCCreateEntityDocumentDelegate: NSObject, UIDocumentPickerDelegate {
    public static let shared = ASCCreateEntityDocumentDelegate()
    var documentsViewController: ASCDocumentsViewController?
    var provider: ASCFileProviderProtocol?

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        _ = url.startAccessingSecurityScopedResource()

        let coordinator = NSFileCoordinator()
        var error: NSError?

        let hud = MBProgressHUD.showTopMost()
        hud?.mode = .indeterminate

        coordinator.coordinate(readingItemAt: url, options: [], error: &error) { url in
            hud?.hide(animated: false)

            do {
                let fileData = try Data(contentsOf: url)

                if let provider = provider {
                    var forceCancel = false
                    let openingAlert = ASCProgressAlert(
                        title: NSLocalizedString("Uploading", comment: "Caption of the process") + "...",
                        message: nil,
                        handler: { cancel in
                            forceCancel = cancel
                        }
                    )

                    ASCEntityManager.shared.createFile(
                        for: provider,
                        in: documentsViewController?.folder,
                        data: fileData,
                        name: url.lastPathComponent,
                        params: nil,
                        handler: { status, progress, entity, error, cancel in
                            if status == .begin {
                                openingAlert.show()
                            } else if status == .progress {
                                openingAlert.progress = progress

                                if forceCancel {
                                    cancel = forceCancel
                                    OnlyofficeApiClient.shared.cancelAll()
                                    return
                                }
                            } else if status == .error {
                                openingAlert.hide()

                                if let error {
                                    self.showError(message: error.localizedDescription)
                                }
                            } else if status == .end {
                                openingAlert.hide()

                                if let entity {
                                    self.documentsViewController?.add(entity: entity, open: false)
                                }
                            }
                        }
                    )
                }

            } catch {
                showError(message: error.localizedDescription)
            }
        }

        url.stopAccessingSecurityScopedResource()
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // 🤷🏻‍♀️
    }

    private func showError(message: String) {
        if let topVC = ASCViewControllerManager.shared.topViewController {
            UIAlertController.showError(in: topVC, message: message)
        }
    }
}

// MARK: - ASCCreateEntityImageDelegate

class ASCCreateEntityImageDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public static let shared = ASCCreateEntityImageDelegate()
    var documentsViewController: ASCDocumentsViewController?
    var provider: ASCFileProviderProtocol?

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)

        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! NSString

        if !mediaType.isEqual(to: kUTTypeImage as NSString as String) {
            return
        }

        guard let imageToSave = info[UIImagePickerController.InfoKey.editedImage] as? UIImage ?? info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }

        let compressionQuality: CGFloat = UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.compressImage) ? 0.1 : 1.0

        if let provider = provider, let imageData = imageToSave.jpegData(compressionQuality: compressionQuality) {
            var forceCancel = false
            let openingAlert = ASCProgressAlert(
                title: NSLocalizedString("Uploading", comment: "Caption of the process") + "...",
                message: nil,
                handler: { cancel in
                    forceCancel = cancel
                }
            )

            ASCEntityManager.shared.createImage(
                for: provider,
                in: documentsViewController?.folder,
                imageData: imageData,
                fileExtension: "jpg",
                handler: { status, progress, entity, error, cancel in
                    if status == .begin {
                        openingAlert.show()
                    } else if status == .progress {
                        openingAlert.progress = progress

                        if forceCancel {
                            cancel = forceCancel
                            OnlyofficeApiClient.shared.cancelAll()
                            return
                        }
                    } else if status == .error {
                        openingAlert.hide()

                        if let error {
                            self.showError(message: error.localizedDescription)
                        }
                    } else if status == .end {
                        openingAlert.hide()

                        if let entity = entity {
                            self.documentsViewController?.add(entity: entity)
                        }
                    }
                }
            )
        }
    }

    // MARK: - Private

    private func showError(message: String) {
        if let topVC = ASCViewControllerManager.shared.topViewController {
            UIAlertController.showError(in: topVC, message: message)
        }
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate

extension ASCCreateEntity: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true) { [weak self] in
            Task { [weak self] in
                guard let self, let viewController = self.parent else { return }

                var images: [UIImage] = []
                for index in 0 ..< scan.pageCount {
                    images.append(scan.imageOfPage(at: index))
                }

                ASCEditorManager.shared.storyForOCR(images: images)
                self.createFile(ASCConstants.FileExtensions.docx, viewController: viewController)
            }
        }
    }
}
