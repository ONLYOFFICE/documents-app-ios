//
//  ASCMultiAccountPresenter.swift
//  Documents-opensource
//
//  Created by Лолита Чернышева on 03.04.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import Kingfisher

protocol ASCMultiAccountPresenterProtocol: AnyObject {
    var view: ASCMultiAccountViewProtocol? { get }
    func setup()
    func showProfile(viewController: ASCMultiAccountViewProtocol, account: ASCAccount?)
    func deleteFromDevice(account: ASCAccount?)
    func renewal(account: ASCAccount)
}

class ASCMultiAccountPresenter: ASCMultiAccountPresenterProtocol {
    typealias TableData = ASCMultiAccountScreenModel.TableData

    // MARK: - Properties

    var view: ASCMultiAccountViewProtocol?

    // MARK: - Initialization

    init(view: ASCMultiAccountViewProtocol) {
        self.view = view
    }

    // MARK: - Public methods

    func setup() {
        render()
    }

    func showProfile(viewController: ASCMultiAccountViewProtocol, account: ASCAccount?) {
        let userProfileVC = ASCUserProfileViewController.instantiate(from: Storyboard.userProfile)
        guard let account else { return }

        let userProfileNavigationVC = ASCBaseNavigationController(rootASCViewController: userProfileVC)
        userProfileNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
        userProfileNavigationVC.modalPresentationStyle = .formSheet
        viewController.present(userProfileNavigationVC, animated: true, completion: { [weak self] in
            guard let self = self else { return }
            let avatarUrl = self.absoluteUrl(from: URL(string: account.avatar ?? ""), for: account.portal ?? "")
            userProfileVC.avatarView.kf.apiSetImage(with: avatarUrl, placeholder: Asset.Images.avatarDefault.image)
            userProfileVC.userNameLabel.text = account.displayName
            userProfileVC.portalLabel.text = account.portal
            userProfileVC.emailLabel.text = account.email
        })
    }

    func deleteFromDevice(account: ASCAccount?) {
        
        guard let account = account else { return }

        let currentAccount = ASCAccountsManager.shared.get(by: ASCFileManager.onlyofficeProvider?.apiClient.baseURL?.absoluteString ?? "", email: ASCFileManager.onlyofficeProvider?.user?.email ?? "")
        
        if account.email == currentAccount?.email {
            logout()
        }
        ASCAccountsManager.shared.remove(account)
        render()
    }

    func renewal(account: ASCAccount) {
        let accountsVC = ASCAccountsViewController.instantiate(from: Storyboard.login)
        accountsVC.login(by: account) {
            // MARK: - todo
        }
    }

    // MARK: - Private methods

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

    private func logout() {
        ASCUserProfileViewController.logout()
    }

    private func buildMultiAccountScreenModel() -> ASCMultiAccountScreenModel {
        let tableData: TableData = .init(sections: [.simple(getAddAccountCellModels() + getAccountCellModels())])
        let title = NSLocalizedString("Accounts", comment: "")
        return ASCMultiAccountScreenModel(title: title, tableData: tableData)
    }

    private func getAddAccountCellModels() -> [TableData.Cell] {
        let text = NSLocalizedString("Add account", comment: "")
        return [AddAccountCellModel(image: "",
                                    text: text)].map { model in
            .addAccount(model)
        }
    }

    private func getAccountCellModels() -> [TableData.Cell] {
        ASCAccountsManager.shared.accounts.map { account in
            AccountCellModel(avatarUrlString: account.avatar ?? "",
                             name: account.displayName ?? "",
                             email: account.email ?? "")
        }.map { model in
            .account(model)
        }
    }

    private func render() {
        view?.desplayData(data: buildMultiAccountScreenModel())
    }
}
