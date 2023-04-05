//
//  ASCMultiAccountPresenter.swift
//  Documents-opensource
//
//  Created by Лолита Чернышева on 03.04.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCMultiAccountPresenterProtocol: AnyObject {
    var view: ASCMultiAccountViewProtocol? { get }
    func setup()
    func accountDidSelected(accountId: Int)
}

class ASCMultiAccountPresenter: ASCMultiAccountPresenterProtocol {
    typealias TableData = ASCMultiAccountScreenModel.TableData

    // MARK: - Properties

    var view: ASCMultiAccountViewProtocol?

    private var accounts: [ASCAccount] = [] {
        didSet {
            render()
        }
    }

    // MARK: - Initialization

    init(view: ASCMultiAccountViewProtocol) {
        self.view = view
        accounts = ASCAccountsManager.shared.accounts
    }

    // MARK: - Public methods

    func setup() {
        render()
    }

    func accountDidSelected(accountId: Int) {
        // MARK: - todo
    }

    // MARK: - Private methods

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
        accounts.map { account in
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
