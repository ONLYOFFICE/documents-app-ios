//
//  ASCMultiAccountsController.swift
//  Documents-opensource
//
//  Created by Лолита Чернышева on 31.03.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import UIKit

protocol ASCMultiAccountViewProtocol: UIViewController {
    func desplayData(data: ASCMultiAccountScreenModel)
}

class ASCMultiAccountsController: UITableViewController {
    typealias Cell = ASCMultiAccountScreenModel.TableData.Cell
    typealias Section = ASCMultiAccountScreenModel.TableData.Section

    private var account: ASCAccount?
    private var rowHeight: CGFloat = 60

    var screenModel: ASCMultiAccountScreenModel = .empty {
        didSet {
            setup()
            tableView.reloadData()
        }
    }

    var presenter: ASCMultiAccountPresenterProtocol?

    // MARK: - life cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        presenter?.setup()
    }

    // MARK: - private methods

    private func setupNavigationBar() {
        let title = NSLocalizedString("Cancel", comment: "")
        let backButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(backAction))
        navigationItem.leftBarButtonItem = backButton
    }

    private func setup() {
        title = screenModel.title
        tableView.separatorInset.left = 65
        tableView.register(DetailImageStyleTabelViewCell.self, forCellReuseIdentifier: DetailImageStyleTabelViewCell.reuseIdentifier)
    }

    private func showDeleteAccountFromDeviceAlert(account: ASCAccount?) {
        guard let account = account,
              let email = account.email else { return }

        let message = String(format: NSLocalizedString("Are you sure you want to delete the account  %@ from this devce?", comment: ""), email)

        let deleteAlertAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""),
                                              style: .default) { [weak self] _ in
            guard let self = self else { return }

            self.presenter?.deleteFromDevice(account: account)
        }

        let alertController = UIAlertController.alert("", message: message, actions: [deleteAlertAction]).cancelable()
        present(alertController, animated: true, completion: nil)
    }

    @objc private func backAction() {
        dismiss(animated: true)
    }
}

extension ASCMultiAccountsController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        screenModel.tableData.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch screenModel.tableData.sections[section] {
        case let .simple(cells):
            return cells.count
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        switch tableDataCell(indexPath: indexPath) {
        case .addAccount:
            navigationController?.pushViewController(ASCConnectPortalViewController.instance(), animated: true, completion: {})
        case .account:

            // MARK: - todo

            presenter?.renewal(account: ASCAccountsManager.shared.accounts[index - 1])
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableDataCell(indexPath: indexPath) {
        case let .addAccount(model):
            let cell = UITableViewCell()
            cell.setup(model: model)
            return cell

        case let .account(model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: DetailImageStyleTabelViewCell.reuseIdentifier) as? DetailImageStyleTabelViewCell else { return UITableViewCell() }
            cell.setup(model: model)
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in

            let profileActionTitle = NSLocalizedString("Profile", comment: "")
            let profileAction = UIAction(title: profileActionTitle, image: UIImage(systemName: "person")) { [weak self] _ in
                guard let self = self else { return }

                // MARK: - todo show

                self.presenter?.showProfile(viewController: self, account: ASCAccountsManager.shared.accounts[indexPath.row - 1])
            }

            let deleteFromDeviceTitle = NSLocalizedString("Delete from device", comment: "")
            let deleteFromDeviceAction = UIAction(title: deleteFromDeviceTitle, image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }

                self.showDeleteAccountFromDeviceAlert(account: ASCAccountsManager.shared.accounts[indexPath.row - 1])
            }

            return UIMenu(title: "", children: [profileAction, deleteFromDeviceAction])
        }

        return configuration
    }

    private func tableDataCell(indexPath: IndexPath) -> Cell {
        let section = screenModel.tableData.sections[indexPath.section]
        switch section {
        case let .simple(cells):
            return cells[indexPath.row]
        }
    }
}

extension ASCMultiAccountsController: ASCMultiAccountViewProtocol {
    func desplayData(data: ASCMultiAccountScreenModel) {
        screenModel = data
    }
}

private extension UITableViewCell {
    func setup(model: AddAccountCellModel) {
        textLabel?.text = model.text
        textLabel?.textColor = model.style.textColor
        imageView?.image = UIImage(asset: Asset.Images.cloudAppend)
    }
}
