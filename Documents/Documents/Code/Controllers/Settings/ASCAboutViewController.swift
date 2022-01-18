//
//  ASCAboutViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/22/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import SwiftRater
import DocumentConverter

struct SocialNetworkUrl {
    let scheme: String
    let page: String
    
    func openPage() {
        if let schemeUrl = URL(string: scheme), let pageUrl = URL(string: page) {
            if UIApplication.shared.canOpenURL(schemeUrl) {
                UIApplication.shared.open(schemeUrl, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.open(pageUrl, options: [:], completionHandler: nil)
            }
        }
    }
}

enum SocialNetwork {
    case facebook, google, twitter, instagram, youtube, vk
    func url() -> SocialNetworkUrl {
        switch self {
        case .facebook: return SocialNetworkUrl(scheme: "fb://profile/833032526736775", page: "https://www.facebook.com/OnlyOffice-833032526736775")
        case .twitter: return SocialNetworkUrl(scheme: "twitter:///user?screen_name=ONLY_OFFICE", page: "https://twitter.com/ONLY_OFFICE")
        case .google: return SocialNetworkUrl(scheme: "gplus://plus.google.com/u/0/+Onlyoffice_Community", page: "https://plus.google.com/+Onlyoffice_Community")
        case .instagram: return SocialNetworkUrl(scheme: "instagram://user?username=ONLYOFFICEE", page:"https://www.instagram.com/ONLYOFFICE")
        case .youtube: return SocialNetworkUrl(scheme: "youtube://user/+Onlyoffice_Community", page: "https://www.youtube.com/user/onlyofficeTV")
        case .vk: return SocialNetworkUrl(scheme: "vk://vk.com/onlyoffice", page: "https://vk.com/onlyoffice")
        }
    }
    
    func openPage() {
        self.url().openPage()
    }
}

class ASCAboutViewController: UITableViewController, UIGestureRecognizerDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var rateCell: UITableViewCell!
    @IBOutlet weak var tellFriendCell: UITableViewCell!
    @IBOutlet weak var copyrightsLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var termsOfServiceCell: UITableViewCell!
    @IBOutlet weak var privacyPolicyCell: UITableViewCell!
    
    fileprivate var secretsTaps = 0
    fileprivate var secretsMaxTaps = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let versionInfo = [
            [NSLocalizedString("Version", comment: ""), " \(ASCCommon.appVersion ?? "") (\(ASCCommon.appBuild ?? ""))"],
            ["SDK", ASCEditorManager.shared.localSDKVersion().joined(separator: ".")],
            [NSLocalizedString("Converter", comment: ""), DocumentLocalConverter.sdkVersion() ?? ""]
            ]
            .map { $0.joined(separator: " ") }
            .joined(separator: "\n")

        versionLabel.text = versionInfo
        copyrightsLabel.text = ASCConstants.Name.copyright
        
        let logoGestureTap = UITapGestureRecognizer(target: self, action: #selector(logoTap))
        logoImageView.addGestureRecognizer(logoGestureTap)
        logoImageView.isUserInteractionEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if  let navigationController = navigationController,
            let interactivePopGestureRecognizer = navigationController.interactivePopGestureRecognizer
        {
            navigationController.setNavigationBarHidden(true, animated: true)
            interactivePopGestureRecognizer.delegate = self
        }
        delay(seconds: 0.03) { [weak self] in
            self?.recalcHeaderView()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        delay(seconds: 0.03) { [weak self] in
            self?.recalcHeaderView()
        }
    }

    private func recalcHeaderView() {
        if let headerView = tableView.tableHeaderView {
            let rowCount = tableView.numberOfRows(inSection: 0)
            let rowHeight = tableView.rowHeight
            let footerViewHeight = tableView.tableFooterView?.bounds.height ?? 0
            let screenBounds = view.bounds
            let bottomSafeArea = view.safeAreaInsets.bottom

            headerView.frame = CGRect(
                x: 0,
                y: 0,
                width: Int(tableView.bounds.width),
                height: Int(screenBounds.height) - rowCount * Int(rowHeight) - Int(footerViewHeight) - Int(bottomSafeArea)
            )

            tableView.reloadData()
            tableView.setContentOffset(.zero, animated: false)
        }
    }

    // MARK: - Table view Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if cell == rateCell {
            SwiftRater.appName = ASCConstants.Name.appNameFull
            
            if SwiftRater.isRateDone {
                if let url = URL(string: ASCConstants.Urls.appReview), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else {
                SwiftRater.rateApp()
            }
        } else if cell == termsOfServiceCell {
            let termsOfServiceLink = ASCConstants.remoteConfigValue(forKey: ASCConstants.RemoteSettingsKeys.termsOfServiceLink)?.stringValue ?? ASCConstants.Urls.legalTerms
            
            if let url = URL(string: termsOfServiceLink) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else if cell == privacyPolicyCell {
            let privacyPolicyLink = ASCConstants.remoteConfigValue(forKey: ASCConstants.RemoteSettingsKeys.privacyPolicyLink)?.stringValue ?? ASCConstants.Urls.legalTerms
            
            if let url = URL(string: privacyPolicyLink) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else if cell == tellFriendCell {
            let activityController = UIActivityViewController(
                activityItems: [
                    String.localizedStringWithFormat("%@ - Work on your documents even on the go. %@", ASCConstants.Name.appNameFull, ASCConstants.Urls.applicationPage)
                ],
                applicationActivities: nil
            )
            
            if UIDevice.pad {
                activityController.popoverPresentationController?.sourceView = cell
                activityController.popoverPresentationController?.sourceRect = cell.bounds
            }
            
            present(activityController, animated: true, completion: nil)
        }
    }

    // MARK: - Action
    @IBAction func onBack(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func onDone(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onFacebook(_ sender: UIButton) {
        SocialNetwork.facebook.openPage()
    }
    
    @IBAction func onTwitter(_ sender: UIButton) {
        SocialNetwork.twitter.openPage()
    }
    
    @IBAction func onGoogle(_ sender: UIButton) {
        SocialNetwork.google.openPage()
    }
    
    @IBAction func onVk(_ sender: UIButton) {
        SocialNetwork.vk.openPage()
    }
    
    @objc func logoTap(_ sender: UITapGestureRecognizer) {
        secretsTaps += 1
        
        if secretsTaps >= secretsMaxTaps {            
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
            
            ASCDebugManager.shared.enabled = !ASCDebugManager.shared.enabled
            
            secretsTaps = 0
        }
    }
}
