//
//  ASCAccountsViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10/23/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import MBProgressHUD
import Firebase

class ASCAccountsViewController: ASCBaseViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var accountsCollectionView: UICollectionView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var portalLabel: UILabel!
    @IBOutlet weak var labelsView: UIStackView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var accountInfoTopConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ASCAccountsManager.shared.accounts.count < 1 {
            switchVCSingle()
            return
        }
        
        setupLayout()
        currentPage = 0
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.prefersLargeTitles = false
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        continueButton?.isUserInteractionEnabled = true
        continueButton?.isEnabled = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIDevice.phone ? .portrait : [.portrait, .landscape]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIDevice.phone ? .portrait : super.preferredInterfaceOrientationForPresentation
    }

    fileprivate func setupLayout() {
        if let layout = accountsCollectionView.collectionViewLayout as? UPCarouselFlowLayout {
            layout.spacingMode = UPCarouselFlowLayoutSpacingMode.fixed(spacing: 40)
        }

        if UIDevice.phone, !UIDevice.greatOfInches(.inches47) {
            accountInfoTopConstraint?.constant = 5
        }
    }
    
    private var currentPage: Int = -1 {
        didSet {
            if currentPage == oldValue || currentPage < 0 {
                return
            }
            
            updateInfo(pageIndex: currentPage)
        }
    }
    
    private var pageSize: CGSize {
        if let layout = accountsCollectionView.collectionViewLayout as? UPCarouselFlowLayout {
            var pageSize = layout.itemSize
            if layout.scrollDirection == .horizontal {
                pageSize.width += layout.minimumLineSpacing
            } else {
                pageSize.height += layout.minimumLineSpacing
            }
            return pageSize
        }
        
        return .zero
    }
    
    private func updateInfo(pageIndex: Int) {
        let animationDuration = 0.3
        
        view.subviews.forEach({$0.layer.removeAllAnimations()})
        view.layer.removeAllAnimations()
        view.layoutIfNeeded()
        
        if pageIndex < 0 || pageIndex >= ASCAccountsManager.shared.accounts.count {
            UIView.animate(withDuration: animationDuration / 2, animations: { [weak self] in
                self?.labelsView?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self?.labelsView?.alpha = 0
            }) { [weak self] (completed) in
                self?.displayNameLabel?.text = ""
                self?.portalLabel?.text = ""
                
                UIView.animate(withDuration: animationDuration / 2) { [weak self] in
                    self?.labelsView?.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self?.labelsView?.alpha = 1
                }
            }
            return
        }

        UIView.animate(withDuration: animationDuration / 2, animations: { [weak self] in
            self?.labelsView?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self?.labelsView?.alpha = 0
        }) { [weak self] (completed) in
            let index = self?.currentPage ?? max(pageIndex, 0)
            let account = ASCAccountsManager.shared.accounts[index]
            self?.displayNameLabel?.text = account.email ?? NSLocalizedString("Unknown", comment: "")
            self?.portalLabel?.text = URL(string: account.portal ?? "")?.host ?? account.portal
            
            UIView.animate(withDuration: animationDuration / 2) { [weak self] in
                self?.labelsView?.transform = CGAffineTransform(scaleX: 1, y: 1)
                self?.labelsView?.alpha = 1
            }
        }
    }
    
    private func calcCurrentPage(by scrollView: UIScrollView) {
        if let layout = accountsCollectionView.collectionViewLayout as? UPCarouselFlowLayout {
            let pageSide = (layout.scrollDirection == .horizontal) ? pageSize.width : pageSize.height
            let offset = (layout.scrollDirection == .horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
            let page = Int(floor((offset - pageSide / 2) / pageSide) + 1)
            
            if page > -1 && page < ASCAccountsManager.shared.accounts.count {
                currentPage = page
            }
        }
    }
    
    private func switchVCSingle() {
        if ASCAccountsManager.shared.accounts.count < 1 {
            navigator.navigate(to: .onlyofficeConnectPortal)
        }
    }

    private func absoluteUrl(from url: URL?, for portal: String) -> URL? {
        if let url = url {
            if let _ = url.host {
                return url
            } else {
                return URL(string: portal + url.absoluteString)
            }
        }
        return nil
    }

    private func checkPortalExist(_ portal: String, completion: @escaping (Bool, String?) -> Void) {
        ASCOnlyOfficeApi.shared.baseUrl = portal
        ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiCapabilities) { results, error, response in
            if let error = error {
                ASCOnlyOfficeApi.shared.baseUrl = nil
                completion(false, error.localizedDescription)
            } else if let results = results as? [String: Any] {
                ASCOnlyOfficeApi.shared.capabilities = OnlyofficeCapabilities(JSON: results)
                completion(true, nil)
            } else {
                ASCOnlyOfficeApi.shared.baseUrl = nil
                completion(false, NSLocalizedString("Failed to check portal availability.", comment: ""))
            }
        }
    }

    private func checkServersVersion(_ portal: String, completion: @escaping (Bool, String?) -> Void) {
        ASCOnlyOfficeApi.shared.baseUrl = portal
        ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiServersVersion) { results, error, response in
            if let versions = results as? [String: Any] {
                if let communityServer = versions["communityServer"] as? String {
                    ASCOnlyOfficeApi.shared.serverVersion = communityServer
                }
            }
            completion(true, nil)
        }
    }

    func renewal(by account: ASCAccount, animated: Bool = true) {
        let signinViewController = ASCSignInViewController.instantiate(from: Storyboard.login)
        signinViewController.renewal = true
        signinViewController.portal = account.portal
        signinViewController.email = account.email
        navigationController?.pushViewController(signinViewController, animated: animated)
    }

    func login(by account: ASCAccount, completion: @escaping () -> Void) {
        ASCOnlyOfficeApi.cancelAllTasks()

        if let baseUrl = account.portal, let token = account.token {
            let dummyOnlyofficeProvider = ASCOnlyofficeProvider(baseUrl: baseUrl, token: token)
//
//            ASCOnlyOfficeApi.shared.baseUrl = baseUrl
//            ASCOnlyOfficeApi.shared.token = token
            

            let hud = MBProgressHUD.showTopMost()

            // Synchronize api calls
            let requestQueue = OperationQueue()
            requestQueue.maxConcurrentOperationCount = 1

            var lastErrorMsg: String?
            var allowPortal = false

            // Check portal if exist
            requestQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                self.checkPortalExist(baseUrl, completion: { success, errorMessage in
                    defer { semaphore.signal() }

                    allowPortal = success

                    if !success {
                        lastErrorMsg = errorMessage ?? NSLocalizedString("Failed to check portal availability.", comment: "")
                    }
                })
                semaphore.wait()
            }
            
            // Check portal version
            requestQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                self.checkServersVersion(baseUrl, completion: { success, errorMessage in
                    semaphore.signal()
                })
                semaphore.wait()
            }

            // Check read user info
            requestQueue.addOperation {
                if nil == lastErrorMsg {
                    let semaphore = DispatchSemaphore(value: 0)

                    dummyOnlyofficeProvider.userInfo { success, error in
                        if !success {
                            lastErrorMsg = error?.localizedDescription ?? NSLocalizedString("Failed to check portal availability.", comment: "")
                        }
                        semaphore.signal()
                    }
                    semaphore.wait()
                }
            }

            DispatchQueue.global(qos: .background).async { [weak self] in
                requestQueue.waitUntilAllOperationsAreFinished()

                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else {
                        ASCOnlyOfficeApi.reset()
                        OnlyofficeApiClient.reset()
                        completion()
                        return
                    }

                    if !allowPortal {
                        hud?.hide(animated: false)

                        if let strongSelf = self, let errorMessage = lastErrorMsg {
                            UIAlertController.showError(
                                in: strongSelf,
                                message: NSLocalizedString("Portal is unavailable.", comment: "") + " " + errorMessage
                            )
                        }
                    } else if let _ = lastErrorMsg {
                        hud?.hide(animated: false)
                        self?.renewal(by: account)
                    } else {
                        hud?.setSuccessState()

                        // Init ONLYOFFICE provider
                        ASCFileManager.onlyofficeProvider = ASCOnlyofficeProvider(baseUrl: baseUrl, token: token)
                        ASCFileManager.onlyofficeProvider?.user = dummyOnlyofficeProvider.user
                        ASCFileManager.provider = ASCFileManager.onlyofficeProvider
                        ASCFileManager.storeProviders()

                        // Notify
                        NotificationCenter.default.post(name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)

                        // Registration device into the portal
                        ASCOnlyOfficeApi.post(ASCOnlyOfficeApi.apiDeviceRegistration, parameters: ["type": 2], completion: { (_, _, _) in
                            // 2 - IOSDocuments
                        })

                        ASCAnalytics.logEvent(ASCConstants.Analytics.Event.switchAccount, parameters: [
                            "portal": baseUrl
                            ]
                        )

                        ASCEditorManager.shared.fetchDocumentService { _,_,_  in }
                        strongSelf.dismiss(animated: true, completion: nil)

                        hud?.hide(animated: true, afterDelay: 0.3)
                    }
                    
                    completion()
                }
            }
        }
    }
    
    // MARK: - Actions

    @IBAction func onDeleteAccount(_ sender: UIBarButtonItem) {
        let account = ASCAccountsManager.shared.accounts[currentPage]
        
        let deleteController = UIAlertController(
            title: String(format: NSLocalizedString("Are you sure you want to delete the account %@ from this device?", comment: ""), account.email ?? ""),
            message: nil,
            preferredStyle: UIDevice.phone ? .actionSheet : .alert,
            tintColor: nil
        )
        
        deleteController.addAction(title: NSLocalizedString("Delete account", comment: ""), style: .destructive, handler: { [weak self] action in
            ASCAccountsManager.shared.remove(account)
            
            if ASCAccountsManager.shared.accounts.count < 1 {
                self?.switchVCSingle()
                return
            }
            
            guard let pageIndex = self?.currentPage else { return }
            
            self?.accountsCollectionView.deleteItems(at: [IndexPath(row: pageIndex, section: 0)])
            
            if pageIndex >= ASCAccountsManager.shared.accounts.count && ASCAccountsManager.shared.accounts.count > 0 {
                self?.currentPage -= 1
            } else {
                self?.updateInfo(pageIndex: pageIndex)
            }
        })
        
        deleteController.addCancel()
        
        present(deleteController, animated: true, completion: nil)
    }
    
    @IBAction func onContinue(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        sender.isEnabled = false

        login(by: ASCAccountsManager.shared.accounts[currentPage]) {
            sender.isUserInteractionEnabled = true
            sender.isEnabled = true
        }
    }
    
    @IBAction func onClose(_ sender: UIBarButtonItem) {
        ASCOnlyOfficeApi.cancelAllTasks()

        // Cleanup auth info
        ASCOnlyOfficeApi.reset()
        OnlyofficeApiClient.reset()

        // Cleanup ONLYOFFICE provider
        ASCFileManager.onlyofficeProvider?.reset()
        ASCFileManager.onlyofficeProvider = nil
        ASCFileManager.storeProviders()

        dismiss(animated: true) {
            if let parent = self.presentingViewController {
                parent.viewWillAppear(false)
            }
        }
    }
}


// MARK: - UICollectionView DataSource

extension ASCAccountsViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ASCAccountsManager.shared.accounts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ASCAvatarCollectionViewCell.identifier, for: indexPath) as? ASCAvatarCollectionViewCell {
            let account = ASCAccountsManager.shared.accounts[indexPath.row]
            let avatarUrl = absoluteUrl(from: URL(string: account.avatar ?? ""), for: account.portal ?? "")

            cell.imageView.kf.apiSetImage(with: avatarUrl,
                                          placeholder: Asset.Images.avatarDefault.image)

            return cell
        }

        return UICollectionViewCell()
    }
}


// MARK: - UICollectionView Delegate

extension ASCAccountsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == currentPage {
            onContinue(continueButton)
            return
        }

        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}


// MARK: - UIScrollView Delegate

extension ASCAccountsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        calcCurrentPage(by: scrollView)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(scrollViewDidEndScrollingAnimation), with: scrollView, afterDelay: 0.2)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        calcCurrentPage(by: scrollView)
    }
}
