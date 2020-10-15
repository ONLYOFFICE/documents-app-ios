//
//  ASCSettingsViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/19/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import FileKit
import MBProgressHUD
import SDWebImage
import MessageUI
import DocumentConverter
import Kingfisher

class ASCSettingsViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var clearCacheCell: UITableViewCell!
    @IBOutlet weak var supportCell: UITableViewCell!
    @IBOutlet weak var introCell: UITableViewCell!
    @IBOutlet weak var compressImagesSwitch: UISwitch!
    @IBOutlet weak var previewFilesSwitch: UISwitch!
    
    
    private var cacheSize: UInt64 = 0
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        compressImagesSwitch?.isOn = UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.compressImage)
        previewFilesSwitch?.isOn = UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.previewFiles)
        
        navigationController?.view.backgroundColor = UIColor(named: "table-background")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.pad {
            navigationController?.navigationBar.prefersLargeTitles = false
            
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if UIDevice.pad {
            guard let navigationBar = navigationController?.navigationBar else { return }
            
            let transparent = (navigationBar.y + navigationBar.height + scrollView.contentOffset.y) > 0
            
            navigationBar.setBackgroundImage(transparent ? nil : UIImage(), for: .default)
            navigationBar.shadowImage = transparent ? nil : UIImage()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        calcCacheSize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if cell == clearCacheCell {
            clearCache()
        } else if cell == supportCell {
            sendFeedback()
        } else if cell == introCell {
            let introVC = ASCIntroViewController.instantiate(from: Storyboard.intro)
            present(introVC, animated: true, completion: nil)
        }
    }

    // MARK: - Private
    
    private func calcCacheSize() {
        clearCacheCell?.isUserInteractionEnabled = false
        //clearCacheCell?.detailTextLabel?.text = ""
        
        let activityView = UIActivityIndicatorView(style: .gray)
        activityView.color = view.tintColor
        activityView.startAnimating()
        
        if cacheSize < 1 {
            clearCacheCell?.detailTextLabel?.text = ""
            clearCacheCell?.accessoryView = activityView
        }
                    
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }

            var commonSize: UInt64 = 0
            
            _ = Path.userTemporary.find(searchDepth: 5) { path in
                if path.isRegular {
                    commonSize += path.fileSize ?? 0
                }

                return path.isRegular
            }

            strongSelf.cacheSize = commonSize

            ImageCache.default.calculateDiskStorageSize { [weak self] result in
                switch result {
                case .success(let size):
                    log.info("Disk cache size: \(Double(size) / 1024 / 1024) MB")
                    guard let strongSelf = self else { return }

                    strongSelf.cacheSize += UInt64(size)

                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }

                        delay(seconds: 0.3) {
                            strongSelf.cacheSize += UInt64(SDImageCache.shared.totalDiskSize())
                            strongSelf.clearCacheCell?.accessoryView = nil
                            strongSelf.clearCacheCell?.isUserInteractionEnabled = strongSelf.cacheSize > 0
                            strongSelf.clearCacheCell?.detailTextLabel?.text = strongSelf.cacheSize < 1
                                ? NSLocalizedString("None", comment: "If the cache is empty")
                                : String.fileSizeToString(with: strongSelf.cacheSize)
                        }
                    }
                case .failure(let error):
                    print(error)
                    guard let strongSelf = self else { return }

                    strongSelf.clearCacheCell?.isUserInteractionEnabled = false
                    strongSelf.clearCacheCell?.detailTextLabel?.text = NSLocalizedString("None", comment: "If the cache is empty")
                }
            }
        }
    }
    
    private func clearCache() {
        let alertController = UIAlertController(
            title: NSLocalizedString("Clear Cache?", comment: "Button title"),
            message: NSLocalizedString("This operation will free up space on your device by deleting temporary files. Your offline files and personal data won't be removed.", comment: ""),
            preferredStyle: UIDevice.pad ? .alert : .actionSheet,
            tintColor: nil
        )
        let deleteAction = UIAlertAction(title: NSLocalizedString("Clear Cache", comment: "Button title"), style: .destructive) { (action) in
            guard let hud = MBProgressHUD.showTopMost() else {
                return
            }
            
            hud.mode = .indeterminate
            hud.label.text = NSLocalizedString("Clearing", comment: "Caption of the processing")
            
            DispatchQueue.global().async { [weak self] in
                _ = Path.userTemporary.find(searchDepth: 1) { path in
                    ASCLocalFileHelper.shared.removeFile(path)
                    return true
                }
                
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }

                    // Clear avatar images
                    ImageCache.default.clearMemoryCache()
                    ImageCache.default.clearDiskCache()
                    ImageCache.default.cleanExpiredDiskCache()

                    // Clear images
                    SDImageCache.shared.clearMemory()
                    SDImageCache.shared.clearDisk()
                    
                    hud.setSuccessState()
                    hud.hide(animated: true, afterDelay: 2)
                    
                    strongSelf.calcCacheSize()
                }
            }
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func sendFeedback() {
        let composer = MFMailComposeViewController()        
        let localSdkVersion = ASCEditorManager.shared.localSDKVersion().joined(separator: ".")
        
        if MFMailComposeViewController.canSendMail() {
            composer.mailComposeDelegate = self
            composer.setToRecipients([ASCConstants.Urls.supportMailTo])
            composer.setSubject(String.localizedStringWithFormat("%@ iOS Feedback", ASCConstants.Name.appNameFull))
            composer.setMessageBody([
                String(repeating: "\n", count: 5),
                String(repeating: "_", count: 20),
                "App version: \(ASCCommon.appVersion ?? "Unknown") (\(ASCCommon.appBuild ?? "Unknown"))",
                "SDK: \(localSdkVersion)",
                "Converter: \(DocumentLocalConverter.sdkVersion() ?? "")",
                "Device model: \(UIDevice.platform)",
                "iOS Version: \(ASCCommon.systemVersion)"
            ].joined(separator: "\n"), isHTML: false)

            present(composer, animated: true, completion: nil)
        }
    }
    
    // MARK: - MFMailComposeViewController Delegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }

    
    // MARK: - Actions
    
    @IBAction func onCompressImages(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: ASCConstants.SettingsKeys.compressImage)
    }
    
    @IBAction func onFilePreview(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: ASCConstants.SettingsKeys.previewFiles)
        NotificationCenter.default.post(name: ASCConstants.Notifications.reloadData, object: nil)
    }
    
}
