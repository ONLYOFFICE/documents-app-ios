//
//  ASCOnlyofficeSplitViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 17/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCOnlyofficeSplitViewController: ASCBaseSplitViewController {
    // MARK: - Properties

    private var renewAccount: ASCAccount?

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(onOnlyofficeLogInCompleted(_:)), name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onOnlyofficeLogoutCompleted(_:)), name: ASCConstants.Notifications.logoutOnlyofficeCompleted, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tabBarItem.title = ASCConstants.Name.appNameShort

        if ASCFileManager.onlyofficeProvider == nil {
            let accountsVC = ASCMultiAccountsController(style: .insetGrouped)
            let presenter = ASCMultiAccountPresenter(view: accountsVC)
            accountsVC.presenter = presenter

            // let accountsVC = ASCMultiAccountsController() // ASCAccountsViewController.instantiate(from: Storyboard.login)
            let accountsNavigationVC = ASCBaseNavigationController(rootASCViewController: accountsVC)

            if let account = renewAccount {
                accountsVC.presenter?.renewal(by: account, animated: true)
                //      accountsVC.renewal(by: account, animated: false)
                renewAccount = nil
            }

            accountsNavigationVC.modalTransitionStyle = .crossDissolve
            accountsNavigationVC.modalPresentationStyle = .fullScreen

            present(accountsNavigationVC, animated: false) {
                ASCViewControllerManager.shared.rootController?.display(provider: ASCFileManager.localProvider, folder: nil)
            }
        }
    }

    // MARK: - Notifications

    @objc func onOnlyofficeLogInCompleted(_ notification: Notification) {
        ASCViewControllerManager.shared.rootController?.display(provider: ASCFileManager.onlyofficeProvider, folder: nil)

        delay(seconds: 0.1) {
            ASCViewControllerManager.shared.routeOpenFile()
        }
    }

    @objc func onOnlyofficeLogoutCompleted(_ notification: Notification) {
//        showDetailViewController(UINavigationController(rootASCViewController: ASCBaseViewController()), sender: self)

        if let userInfo = notification.userInfo,
           let account = userInfo["account"] as? ASCAccount
        {
            renewAccount = account
        }

        if let presentedVC = presentedViewController {
            presentedVC.dismiss(animated: true) { [weak self] in
                self?.viewWillAppear(false)
            }
        } else {
            viewWillAppear(false)
        }
    }
}
