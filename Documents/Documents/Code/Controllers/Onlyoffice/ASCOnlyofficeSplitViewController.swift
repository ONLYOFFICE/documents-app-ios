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

    fileprivate var personalMigrationDidPresent = false

    private var isPersonal: Bool {
        ASCPortalTypeDefinderByCurrentConnection().definePortalType() == .personal
    }

    fileprivate lazy var personalMigrationDeadline = Date(integerLiteral: 2024_09_01) ?? Date()

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
            let accountsVC = ASCMultiAccountsViewController(style: .insetGrouped)
            let presenter = ASCMultiAccountPresenter(view: accountsVC)
            accountsVC.presenter = presenter

            let accountsNavigationVC = ASCBaseNavigationController(rootASCViewController: accountsVC)

            if let account = renewAccount {
                accountsVC.presenter?.renewal(by: account, animated: true)
                renewAccount = nil
            }

            accountsNavigationVC.modalTransitionStyle = .crossDissolve
            accountsNavigationVC.modalPresentationStyle = .fullScreen

            present(accountsNavigationVC, animated: false) {
                ASCViewControllerManager.shared.rootController?.display(provider: ASCFileManager.localProvider, folder: nil)
            }
        }

        delay(seconds: 0.01) {
            self.displayPersonalMigrationIfNeeded()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Notifications

    @objc func onOnlyofficeLogInCompleted(_ notification: Notification) {
        personalMigrationDidPresent = false

        ASCViewControllerManager.shared.rootController?.display(provider: ASCFileManager.onlyofficeProvider, folder: nil)

        delay(seconds: 0.1) {
            ASCViewControllerManager.shared.routeOpenFile()
        }
    }

    @objc func onOnlyofficeLogoutCompleted(_ notification: Notification) {
//        showDetailViewController(UINavigationController(rootASCViewController: ASCBaseViewController()), sender: self)

        personalMigrationDidPresent = false

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

    // MARK: - Private

    private func displayPersonalMigrationIfNeeded() {
        if personalMigrationDidPresent || !isPersonal {
            return
        }

        personalMigrationDidPresent = true

        let personalMigrationVC = PersonalMigrationViewController()
        let personalMigrationNC = ASCBaseNavigationController(rootASCViewController: personalMigrationVC)

        personalMigrationNC.setNavigationBarHidden(true, animated: false)
        personalMigrationNC.modalTransitionStyle = .crossDissolve
        personalMigrationNC.modalPresentationStyle = .fullScreen

        personalMigrationVC.allowClose = Date() < personalMigrationDeadline
        personalMigrationVC.onClose = {
            personalMigrationNC.dismiss(animated: true)
        }
        personalMigrationVC.onCreate = { [weak self] in
            guard let self else { return }

            personalMigrationNC.dismiss(animated: false) { [weak self] in
                guard let self else { return }

                let accountsVC = ASCMultiAccountsViewController(style: .insetGrouped)
                let presenter = ASCMultiAccountPresenter(view: accountsVC)
                accountsVC.presenter = presenter

                let accountsNavigationVC = ASCBaseNavigationController(rootASCViewController: accountsVC)

                accountsVC.presenter?.createPortal(animated: false)

                accountsNavigationVC.modalTransitionStyle = .crossDissolve
                accountsNavigationVC.modalPresentationStyle = .fullScreen

                present(accountsNavigationVC, animated: false) {
                    ASCViewControllerManager.shared.rootController?.display(provider: ASCFileManager.localProvider, folder: nil)
                }
            }
        }

        present(personalMigrationNC, animated: false)
    }
}
