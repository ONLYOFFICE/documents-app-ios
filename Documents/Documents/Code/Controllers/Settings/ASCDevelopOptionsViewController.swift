//
//  ASCDevelopOptionsViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 14.06.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCDevelopOptionsViewController: ASCBaseTableViewController {
    // Section model

    struct SettingsSection {
        var items: [CellType]
        var header: String?
        var footer: String?

        init(items: [CellType], header: String? = nil, footer: String? = nil) {
            self.items = items
            self.header = header
            self.footer = footer
        }
    }

    // MARK: - Properties

    private var tableData: [SectionType] = []

    // MARK: - Lifecycle Methods

    init() {
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Developer options", comment: "")

        configureTableView()
        build()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if UIDevice.pad {
            navigationController?.navigationBar.prefersLargeTitles = false

            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if UIDevice.pad {
            guard let navigationBar = navigationController?.navigationBar else { return }

            let transparent = (navigationBar.y + navigationBar.height + scrollView.contentOffset.y) > 0

            navigationBar.setBackgroundImage(transparent ? nil : UIImage(), for: .default)
            navigationBar.shadowImage = transparent ? nil : UIImage()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func configureTableView() {
        view.backgroundColor = .groupTableViewBackground

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(
            ASCSettingsNotificationCell.self,
            forCellReuseIdentifier: ASCSettingsNotificationCell.identifier
        )
    }

    private func build() {
        var data: [SectionType] = []

        // Features section
        let featuresSection = SettingsSection(
            items: [
                .switchControl(viewModel: ASCSwitchCellViewModel(
                    title: "Skeleton of categories (false)",
                    isOn: ASCConstants.Feature.allowCategoriesSkeleton,
                    valueChanged: { isOn in
                        UserDefaults.standard.set(isOn, forKey: ASCConstants.SettingsKeys.debugAllowCategoriesSkeleton)
                    }
                )),
                .switchControl(viewModel: ASCSwitchCellViewModel(
                    title: "Allow iCloud (true)",
                    isOn: ASCConstants.Feature.allowiCloud,
                    valueChanged: { isOn in
                        UserDefaults.standard.set(isOn, forKey: ASCConstants.SettingsKeys.debugAllowiCloud)
                    }
                )),
                .switchControl(viewModel: ASCSwitchCellViewModel(
                    title: "Hide Searchbar if empty screen (false)",
                    isOn: ASCConstants.Feature.hideSearchbarIfEmpty,
                    valueChanged: { isOn in
                        UserDefaults.standard.set(isOn, forKey: ASCConstants.SettingsKeys.debugHideSearchbarIfEmpty)
                    }
                )),
            ],
            header: NSLocalizedString("Features", comment: "")
        )
        data.append(.standart(viewModel: featuresSection))

        tableData = data
        tableView?.reloadData()
    }
}

// MARK: - Table view data source

extension ASCDevelopOptionsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        tableData.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData[section].toSection().items.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellType(by: indexPath).toCell(tableView: tableView)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        tableData[section].toSection().header
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        tableData[section].toSection().footer
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch cellType(by: indexPath) {
        case let .standart(model):
            model.action?()
        default:
            break
        }
    }

    private func cellType(by indexPath: IndexPath) -> CellType {
        tableData[indexPath.section].toSection().items[indexPath.row]
    }
}

// MARK: - Cell types

extension ASCDevelopOptionsViewController {
    enum CellType {
        case standart(viewModel: ASCStandartCellViewModel)
        case switchControl(viewModel: ASCSwitchCellViewModel)

        public func viewModel() -> Any {
            switch self {
            case let .standart(viewModel):
                return viewModel
            case let .switchControl(viewModel):
                return viewModel
            }
        }

        public func toCell(tableView: UITableView) -> UITableViewCell {
            switch self {
            case let .standart(viewModel):
                return makeStandartCell(viewModel, for: tableView) ?? makeDefaultCell()
            case let .switchControl(viewModel):
                return makeSwitchCell(viewModel, for: tableView) ?? makeDefaultCell()
            }
        }

        private func makeStandartCell(_ viewModel: ASCStandartCellViewModel, for tableView: UITableView) -> UITableViewCell? {
            guard let cell = ASCStandartCell.createForTableView(tableView) as? ASCStandartCell else { return nil }
            cell.viewModel = viewModel
            return cell
        }

        private func makeSwitchCell(_ viewModel: ASCSwitchCellViewModel, for tableView: UITableView) -> UITableViewCell? {
            guard let switchCell = ASCSwitchCell.createForTableView(tableView) as? ASCSwitchCell else { return nil }
            switchCell.viewModel = viewModel
            switchCell.uiSwitch?.onTintColor = tableView.tintColor
            return switchCell
        }

        private func makeDefaultCell() -> UITableViewCell {
            UITableViewCell()
        }
    }
}

// MARK: - Section types

extension ASCDevelopOptionsViewController {
    enum SectionType {
        case standart(viewModel: SettingsSection)

        public func toSection() -> SettingsSection {
            switch self {
            case let .standart(viewModel):
                return viewModel
            }
        }

        var viewModel: SettingsSection {
            get {
                switch self {
                case let .standart(viewModel):
                    return viewModel
                }
            }

            set {
                switch self {
                case .standart:
                    self = .standart(viewModel: newValue)
                }
            }
        }
    }
}
