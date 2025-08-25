//
//  ASCMultiAccountsViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 31.03.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import UIKit

protocol ASCMultiAccountViewProtocol: UIViewController {
    func desplayData(data: ASCMultiAccountScreenModel)
    func showDeleteAccountFromDeviceAlert(account: ASCAccount)
}

class ASCMultiAccountsViewController: UITableViewController {
    enum Constants {
        static var rowHeight: CGFloat = 60
        static var separatorInset: CGFloat = 85
    }

    typealias Cell = ASCMultiAccountScreenModel.TableData.Cell
    typealias Section = ASCMultiAccountScreenModel.TableData.Section

    private var account: ASCAccount?
    private var rowHeight: CGFloat = Constants.rowHeight

    var screenModel: ASCMultiAccountScreenModel = .empty {
        didSet {
            setup()
            tableView.reloadData()
        }
    }

    var presenter: ASCMultiAccountPresenterProtocol?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.phone ? .portrait : [.portrait, .landscape]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIDevice.phone ? .portrait : super.preferredInterfaceOrientationForPresentation
    }

    // MARK: - life cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if UIDevice.pad {
            navigationController?.navigationBar.prefersLargeTitles = false

            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true

            scrollViewDidScroll(tableView)
        }

        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if ASCAccountsManager.shared.accounts.count < 1 {
            switchVCSingle()
            return
        }

        setupNavigationBar()
        presenter?.setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if UIDevice.pad {
            guard let navigationBar = navigationController?.navigationBar else { return }

            let transparent = (navigationBar.y + navigationBar.height + scrollView.contentOffset.y) > 0

            navigationBar.setBackgroundImage(transparent ? nil : UIImage(), for: .default)
            navigationBar.shadowImage = transparent ? nil : UIImage()
        }
    }

    // MARK: - private methods

    private func setupNavigationBar() {
        let title = ASCLocalization.Common.cancel
        let backButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(backAction))
        navigationItem.leftBarButtonItem = backButton
    }

    private func setup() {
        title = screenModel.title
        tableView.separatorInset.left = Constants.separatorInset
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(
            DetailImageStyleTabelViewCell.self,
            forCellReuseIdentifier: DetailImageStyleTabelViewCell.reuseIdentifier
        )
    }

    func showDeleteAccountFromDeviceAlert(account: ASCAccount) {
        guard let email = account.email else { return }

        let message = String(format: NSLocalizedString("Are you sure you want to delete the account %@ from this devce?", comment: ""), email)

        let deleteAlertAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""),
                                              style: .destructive)
        { [weak self] _ in
            guard let self = self else { return }

            self.presenter?.deleteFromDevice(account: account) {
                if ASCAccountsManager.shared.accounts.count < 1 {
                    self.switchVCSingle()
                }
            }
        }

        let alertController = UIAlertController.alert("", message: message, actions: [deleteAlertAction]).cancelable()
        present(alertController, animated: true, completion: nil)
    }

    func switchVCSingle() {
        if ASCAccountsManager.shared.accounts.count < 1 {
            let connectPortalVC = ASCConnectPortalViewController.instance()
            connectPortalVC.modalPresentationStyle = .fullScreen
            connectPortalVC.navigationItem.leftBarButtonItem =
                UIBarButtonItem(
                    title: NSLocalizedString("Close", comment: ""),
                    style: .plain,
                    closure: { [weak self] in
                        guard let self else { return }
                        self.dismiss(animated: true)
                    }
                )
            navigationController?.pushViewController(connectPortalVC, animated: false)
        }
    }

    @objc private func backAction() {
        dismiss(animated: true)
    }
}

extension ASCMultiAccountsViewController {
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
        tableView.deselectRow(at: indexPath, animated: true)

        switch tableDataCell(indexPath: indexPath) {
        case .addAccount:
            let connectPortalVC = ASCConnectPortalViewController.instance()
            navigationController?.pushViewController(connectPortalVC, animated: true, completion: {})
        case let .account(model):
            model.selectCallback()
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
        switch tableDataCell(indexPath: indexPath) {
        case .addAccount:
            return nil
        case let .account(model):
            let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                let profileActionTitle = NSLocalizedString("Profile", comment: "")
                let profileAction = UIAction(title: profileActionTitle, image: UIImage(systemName: "person")) { _ in
                    model.showProfileCallback()
                }

                let deleteFromDeviceTitle = NSLocalizedString("Delete from device", comment: "")
                let deleteFromDeviceAction = UIAction(title: deleteFromDeviceTitle, image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    model.deleteCallback()
                }

                return UIMenu(title: "", children: [profileAction, deleteFromDeviceAction])
            }

            return configuration
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch tableDataCell(indexPath: indexPath) {
        case .addAccount:
            return false
        case .account:
            return true
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch tableDataCell(indexPath: indexPath) {
        case .addAccount:
            return
        case let .account(model):
            if editingStyle == .delete {
                model.deleteCallback()
            }
        }
    }

    private func tableDataCell(indexPath: IndexPath) -> Cell {
        let section = screenModel.tableData.sections[indexPath.section]
        switch section {
        case let .simple(cells):
            return cells[indexPath.row]
        }
    }
}

extension ASCMultiAccountsViewController: ASCMultiAccountViewProtocol {
    func desplayData(data: ASCMultiAccountScreenModel) {
        screenModel = data
    }
}

private extension UITableViewCell {
    func setup(model: AddAccountCellModel) {
        textLabel?.text = model.text
        textLabel?.textColor = model.style.textColor
        imageView?.image = UIImage(asset: Asset.Images.cloudAppend)
        layoutMargins = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 0)
    }
}
