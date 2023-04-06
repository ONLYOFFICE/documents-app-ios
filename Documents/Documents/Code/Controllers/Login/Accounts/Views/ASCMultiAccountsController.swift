//
//  ASCMultiAccountsController.swift
//  Documents-opensource
//
//  Created by Лолита Чернышева on 31.03.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCMultiAccountViewProtocol: AnyObject {
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

    private func setupNavigationBar() {
        let title = NSLocalizedString("Cancel", comment: "")
        let backButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(backAction))
        navigationItem.leftBarButtonItem = backButton
    }

    private func setup() {
        title = screenModel.title
        tableView.separatorInset.left = 65
        tableView.register(DetailImageStyleTabelViewCell.self, forCellReuseIdentifier: "DetailImageStyleTabelViewCell")
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DetailImageStyleTabelViewCell") as? DetailImageStyleTabelViewCell else { return UITableViewCell() }
            cell.setup(model: model)
            return cell
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
