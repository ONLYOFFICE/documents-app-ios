//
//  ASCAppThemeViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.05.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCAppThemeViewController: ASCBaseTableViewController {
    // MARK: - Properties

    private var tableData: [CellType] = []

    // MARK: - Lifecycle Methods

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Theme", comment: "")
        view.backgroundColor = .systemGroupedBackground
        tableView.cellLayoutMarginsFollowReadableWidth = true

        build()
    }

    private func build() {
        tableData = AppTheme.allCases.map { theme in
            .standart(
                viewModel: ASCStandartCellViewModel(
                    title: theme.description,
                    action: {
                        self.setTheme(theme: theme)
                    },
                    accessoryType: AppThemeService.theme == theme
                        ? UITableViewCell.AccessoryType.checkmark
                        : UITableViewCell.AccessoryType.none
                )
            )
        }
        tableView?.reloadData()
    }

    private func setTheme(theme: AppTheme) {
        AppThemeService.theme = theme
        build()
    }
}

// MARK: - Table view data source

extension ASCAppThemeViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellType(by: indexPath).toCell(tableView: tableView)
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch cellType(by: indexPath) {
        case let .standart(model):
            model.action?()
        }
    }

    override public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        52
    }

    private func cellType(by indexPath: IndexPath) -> CellType {
        tableData[indexPath.row]
    }
}

// MARK: - Cell types

extension ASCAppThemeViewController {
    enum CellType {
        case standart(viewModel: ASCStandartCellViewModel)

        public func toCell(tableView: UITableView) -> UITableViewCell {
            switch self {
            case let .standart(viewModel):
                return makeStandartCell(viewModel, for: tableView) ?? makeDefaultCell()
            }
        }

        private func makeStandartCell(_ viewModel: ASCStandartCellViewModel, for tableView: UITableView) -> UITableViewCell? {
            guard let cell = ASCStandartCell.createForTableView(tableView) as? ASCStandartCell else { return nil }
            cell.viewModel = viewModel
            return cell
        }

        private func makeDefaultCell() -> UITableViewCell {
            UITableViewCell()
        }
    }
}
