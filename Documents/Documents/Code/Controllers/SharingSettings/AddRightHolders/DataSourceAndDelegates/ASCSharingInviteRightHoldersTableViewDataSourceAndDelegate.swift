//
//  ASCSharingAddRightHoldersTableViewDataSourceAndDelegate.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingInviteRightHoldersTableViewDataSourceAndDelegate<T: UITableViewCell & ASCReusedIdentifierProtocol & ASCViewModelSetter>:
    NSObject, UITableViewDataSource, UITableViewDelegate where T.ViewModel: ASCNamedProtocol
{
    typealias Item = (model: T.ViewModel, selected: IsSelected)
    typealias Group = [Item]

    let type = T.self
    var rowHeight: CGFloat = 60
    var onCellTapped: ((T.ViewModel, IsSelected) -> Void)?
    var inviteSectionEnabled = true
    var inviteCellClousure: () -> Void = {}

    private var models: Group = []

    init(models: [(T.ViewModel, IsSelected)]) {
        super.init()
        set(models: models)
    }

    func set(models: [(T.ViewModel, IsSelected)]) {
        self.models = models
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        inviteSectionEnabled ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard inviteSectionEnabled else { return models.count }
        return section == 0 ? 1 : models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !inviteSectionEnabled || indexPath.section == 1 {
            guard var cell = tableView.dequeueReusableCell(withIdentifier: T.reuseId) as? T else {
                fatalError("Couldn't cast cell to \(T.self)")
            }
            let viewModel = models[indexPath.row]
            cell.viewModel = viewModel.model
            cell.isSelected = viewModel.selected
            cell.selectedBackgroundView = UIView()
            return cell
        } else {
            let cell = UITableViewCell()
            cell.textLabel?.text = NSLocalizedString("Invite people by email", comment: "")
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !inviteSectionEnabled || indexPath.section == 1 {
            let viewModel = models[indexPath.row]
            cell.setSelected(viewModel.selected, animated: false)
            if viewModel.selected {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !inviteSectionEnabled || indexPath.section == 1 {
            var viewModel = models[indexPath.row]
            viewModel.selected = true
            models[indexPath.row] = viewModel
            onCellTapped?(viewModel.model, viewModel.selected)
        } else {
            inviteCellClousure()
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if !inviteSectionEnabled || indexPath.section == 1 {
            var viewModel = models[indexPath.row]
            viewModel.selected = false
            models[indexPath.row] = viewModel
            onCellTapped?(viewModel.model, viewModel.selected)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        (inviteSectionEnabled && indexPath.section == 0) ? 44 : rowHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        (inviteSectionEnabled && section == 0) ? 16 : .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        rowHeight
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        !inviteSectionEnabled || indexPath.section == 1
    }
}
