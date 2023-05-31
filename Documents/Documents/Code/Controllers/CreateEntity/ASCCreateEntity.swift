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

class ASCCreateEntity: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Properties

    private var provider: ASCFileProviderProtocol?

    // MARK: - Lifecycle Methods

    func showCreateController(for provider: ASCFileProviderProtocol, in viewController: ASCDocumentsViewController, sender: Any? = nil) {
        self.provider = provider

        let createEntityView: ASCCreateEntityView!

        do {
            createEntityView = try SwiftMessages.viewFromNib()
            createEntityView.allowConnectClouds = {
                guard let provider = provider as? ASCOnlyofficeProvider,
                      provider.apiClient.serverVersion?.docSpace == nil
                else { return false }
                return provider.apiClient.active
            }()
        } catch {
            log.error("File: \(#file), Function: \(#function), Line: \(#line) - Could not load xib of ASCCreateEntityView")
            return
        }

        if UIDevice.phone || ASCViewControllerManager.shared.currentSizeClass == .compact {
            createEntityView.configureDropShadow()
            createEntityView.onCreate = { restorationIdentifier in
                SwiftMessages.hide()
                self.createEntity(by: restorationIdentifier, in: viewController)
            }

            var config = SwiftMessages.defaultConfig
            config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            config.duration = .forever
            config.presentationStyle = .bottom
            config.dimMode = .gray(interactive: true)
            config.overrideUserInterfaceStyle = AppThemeService.theme.overrideUserInterfaceStyle

            SwiftMessages.show(config: config, view: createEntityView)
        } else {
            var senderView = sender as? UIView

            if let barButton = sender as? UIBarButtonItem {
                senderView = barButton.customView
            }

            if let contentView = createEntityView.subviews.first {
//                (contentView as? CornerRoundingView)?.cornerRadius = 0

                for constraint in contentView.superview?.constraints ?? [] {
                    if let _ = constraint.firstItem as? ASCCreateEntityView ?? constraint.firstItem as? CornerRoundingView,
                       let _ = constraint.secondItem as? ASCCreateEntityView ?? constraint.secondItem as? CornerRoundingView
                    {
                        constraint.constant = 0
                    }
                }

                createEntityView.topConstraints.constant = 20
            }

            let createController = UIViewController()
            createController.view = createEntityView

            createEntityView.onCreate = { restorationIdentifier in
                createController.dismiss(animated: true, completion: {
                    self.createEntity(by: restorationIdentifier, in: viewController)
                })
            }

            if let senderView {
                createController.modalPresentationStyle = .popover
                createController.preferredContentSize = createController.view.frame.size

                if #available(iOS 13.0, *) {
                    if viewController.traitCollection.userInterfaceStyle == .light {
                        createController.popoverPresentationController?.backgroundColor = .white
                    }
                } else {
                    createController.popoverPresentationController?.backgroundColor = .white
                }
                createController.popoverPresentationController?.sourceView = senderView
                createController.popoverPresentationController?.sourceRect = senderView.bounds
            }

            viewController.present(createController, animated: true, completion: nil)
        }
    }

    private func createEntity(by restorationIdentifier: String, in viewController: ASCDocumentsViewController) {
        switch restorationIdentifier {
        case "create-document":
            createFile("docx", viewController: viewController)
        case "create-spreadsheet":
            createFile("xlsx", viewController: viewController)
        case "create-presentation":
            createFile("pptx", viewController: viewController)
        case "create-new-folder":
            createFolder(viewController: viewController)
        case "create-load-file":
            loadFile(viewController: viewController)
        case "create-load-image":
            loadImage(viewController: viewController)
        case "create-take-image":
            takePhoto(viewController: viewController)
        case "create-cloud":
            let connectStorageVC = ASCConnectPortalThirdPartyViewController.instantiate(from: Storyboard.connectStorage)
            let connectStorageNavigationVC = ASCBaseNavigationController(rootASCViewController: connectStorageVC)

            if UIDevice.pad {
                connectStorageNavigationVC.modalPresentationStyle = .formSheet
                connectStorageNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
            }

            viewController.present(connectStorageNavigationVC, animated: true, completion: nil)
        default:
            break
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
                    self.showError(message: error)
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
                    self.showError(message: error)
                }
            } else if status == .end {
                if let entity {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: 1.3)
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
                                    self.showError(message: error)
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

                        if let error = error {
                            self.showError(message: error)
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
