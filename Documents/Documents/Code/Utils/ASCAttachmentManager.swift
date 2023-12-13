//
//  ASCAttachmentManager.swift
//  DocumentEditor
//
//  Created by Alexander Yuzhin on 09.02.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation

typealias ASCAttachmentHandler = (_ url: URL?, _ error: Error?) -> Void

enum ASCAttachmentManagerError: LocalizedError {
    
    case exist
    case unknown(error: Error?)
    
    public var errorDescription: String? {
        switch self {
        case .exist:
            return "A file with a similar name already exist."
        case .unknown(let error):
            return error?.localizedDescription ?? "Unknown error"
        }
    }
}
            
class ASCAttachmentManager: NSObject {
    
    // MARK: - Properties
    
    public struct Text {
        static var photoLibraryUnavailableTitle = "Photo Library Unavailable"
        static var photoLibraryUnavailableMessage = "Please go to Settings and enable the photo library for this app to use this feature."
        static var cameraUnavailableTitle = "Camera Unavailable"
        static var cameraUnavailableMessage = "Please go to Settings and enable the camera for this app to use this feature."
        static var settings = "Settings"
        static var cancel = "Cancel"
    }
    
    var photoQuality: CGFloat = 0.9
    
    private var handler: ASCAttachmentHandler?
    private var temporaryFolderName: String?
    private lazy var temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    
    // MARK: - Methods
        
    /// Store file from Photo Library in temporary
    /// - Parameters:
    ///   - viewController: parent view controller
    ///   - temporaryName: temporary folder name
    ///   - completion: completion handler
    func storeFromLibrary(
        in viewController: UIViewController,
        to temporaryName: String,
        completion: @escaping ASCAttachmentHandler)
    {
        temporaryFolderName = temporaryName
        presentPhotoLibrary(in: viewController, completion: completion)
    }
    
    /// Store file from Camera in temporary
    /// - Parameters:
    ///   - viewController: parent view controller
    ///   - temporaryName: temporary folder name
    ///   - completion: completion handler
    func storeFromCamera(
        in viewController: UIViewController,
        to temporaryName: String,
        completion: @escaping ASCAttachmentHandler)
    {
        temporaryFolderName = temporaryName
        presentCamera(in: viewController, completion: completion)
    }
    
    /// Store file from Files in temporary
    /// - Parameters:
    ///   - viewController: parent view controller
    ///   - temporaryName: temporary folder name
    ///   - completion: completion handler
    func storeFromFiles(
        in viewController: UIViewController,
        allowedUTIs: [String] = [String(kUTTypeImage)],
        to temporaryName: String,
        completion: @escaping ASCAttachmentHandler)
    {
        temporaryFolderName = temporaryName
        presentFiles(in: viewController, allowedUTIs: allowedUTIs, completion: completion)
    }
    
    /// Cleanup of temporary folder
    /// - Parameter temporaryName: temporary folder
    func cleanup(for temporaryName: String) {
        let folderURL = temporaryDirectoryURL.appendingPathComponent(temporaryName, isDirectory: true)
        do {
            try FileManager.default.removeItem(at: folderURL)
        } catch { }
    }
    
    /// Urls of content attachments directory
    /// - Parameter temporaryName: temporary folder
    /// - Returns: List of files urls
    func urls(for temporaryName: String) -> [URL] {
        let folderURL = temporaryDirectoryURL.appendingPathComponent(temporaryName, isDirectory: true)
        do {
            return try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
        } catch {
            print(error)
        }
        return []
    }
    
    
    // MARK: - Private
    
    /// Display Photo Library
    /// - Parameters:
    ///   - viewController: parent view controller
    ///   - completion: completion handler
    func presentPhotoLibrary(in viewController: UIViewController, completion: @escaping ASCAttachmentHandler) {
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            showAccessAlert(
                in: viewController,
                title: ASCAttachmentManager.Text.photoLibraryUnavailableTitle,
                message: ASCAttachmentManager.Text.photoLibraryUnavailableMessage
            )
            return
        }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        
        handler = completion
        
        viewController.present(imagePickerController, animated: true, completion: nil)
    }
    
    /// Display Camera
    /// - Parameters:
    ///   - viewController: parent view controller
    ///   - completion: completion handler
    func presentCamera(in viewController: UIViewController, completion: @escaping ASCAttachmentHandler) {
        let showCamera = {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                
                DispatchQueue.main.async {
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.sourceType = .camera
                    imagePickerController.allowsEditing = false
                    imagePickerController.mediaTypes = [kUTTypeImage as String]
                    imagePickerController.delegate = self
                    
                    self.handler = completion
                    
                    viewController.present(imagePickerController, animated: true, completion: nil)
                }
            }
        }
        
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera()
                    } else {
                        self.showAccessAlert(
                            in: viewController,
                            title: ASCAttachmentManager.Text.cameraUnavailableTitle,
                            message: ASCAttachmentManager.Text.cameraUnavailableMessage
                        )
                    }
                }
            })
        } else {
            showCamera()
        }
    }
    
    /// Display Files
    /// - Parameters:
    ///   - viewController: parent view controller
    ///   - completion: completion handler
    func presentFiles(in viewController: UIViewController, allowedUTIs: [String], completion: @escaping ASCAttachmentHandler) {
        let documentPicker = UIDocumentPickerViewController(
            documentTypes: allowedUTIs,
            in: .import)
        documentPicker.delegate = self
        
        handler = completion
        
        viewController.present(documentPicker, animated: true)
    }
    
    /// Show access warning dialog
    /// - Parameters:
    ///   - viewController: parent view controller
    ///   - title: warning title
    ///   - message: warning message
    private func showAccessAlert(in viewController: UIViewController, title: String?, message: String?) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let settingsAction = UIAlertAction(title: ASCAttachmentManager.Text.settings, style: .cancel, handler: { (alert) in
            let settingsUrl = NSURL(string: UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
                }

            }
        })
        let cancelAction = UIAlertAction(title: ASCAttachmentManager.Text.cancel, style: .default, handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        viewController.present(alertController , animated: true, completion: nil)
    }
    
    
    /// Upload file data
    /// - Parameters:
    ///   - data: file data
    ///   - name: file name
    ///   - folder: stored in the folder
    private func store(fileData: Data, for name: String, in folderURL: URL, completion: @escaping ((_ url: URL?, _ error: Error?) -> Void)) {
        var isDirectory: ObjCBool = false
        var folderExists = FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory)
        folderExists = folderExists && isDirectory.boolValue
        
        if !folderExists {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                completion(nil, error)
                return
            }
        }
        
        let fileURL = folderURL.appendingPathComponent(name)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            completion(nil, ASCAttachmentManagerError.exist)
            return
        }
        
        do {
            try fileData.write(to: fileURL)
        } catch let error {
            completion(nil, error)
            return
        }
        
        completion(fileURL, nil)
    }
    
}


// MARK: - UIImagePickerController Delegate

extension ASCAttachmentManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)

        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! NSString
        
        if !mediaType.isEqual(to: kUTTypeImage as NSString as String) {
            return
        }
        
        guard
            let imageToSave = info[UIImagePickerController.InfoKey.editedImage] as? UIImage ?? info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        else {
            return
        }
        
        let imageName = (info[UIImagePickerController.InfoKey.imageURL] as? URL)?.lastPathComponent ?? (UUID().uuidString + ".jpeg")
        let compressionQuality: CGFloat = photoQuality
        
        if let imageData = imageToSave.jpegData(compressionQuality: compressionQuality) {
            if let temporaryFolderName = self.temporaryFolderName {
                let folderURL = temporaryDirectoryURL.appendingPathComponent(temporaryFolderName)
                debugPrint(folderURL)
                self.store(fileData: imageData, for: imageName, in: folderURL) { file, error in
                    self.handler?(file, error)
                }
            }
        } else {
            self.handler?(nil, nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        handler?(nil, nil)
    }
}


// MARK: - UIImagePickerController Delegate

extension ASCAttachmentManager: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        
        let coordinator = NSFileCoordinator()
        var error: NSError? = nil
        
        coordinator.coordinate(readingItemAt: url, options: [], error: &error) { (url) -> Void in
            
            do {
                let fileData = try Data(contentsOf: url)
                if let temporaryFolderName = self.temporaryFolderName {
                    let folderURL = temporaryDirectoryURL.appendingPathComponent(temporaryFolderName)
                    debugPrint(folderURL)
                    self.store(fileData: fileData, for: url.lastPathComponent, in: folderURL) { file, error in
                        self.handler?(file, error)
                    }
                }
            } catch {
                self.handler?(nil, error)
            }
        }
        
        url.stopAccessingSecurityScopedResource()
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        handler?(nil, nil)
    }
}
