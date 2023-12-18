//
//  ASCSharingChooseNewOwnerRightHoldersTableViewDataSourceAndDelegate.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 03.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingChooseNewOwnerRightHoldersTableViewDataSourceAndDelegate<T: UITableViewCell & ASCReusedIdentifierProtocol & ASCViewModelSetter>:
    NSObject, UITableViewDataSource, UITableViewDelegate where T.ViewModel: ASCNamedProtocol
{
    typealias Item = (model: T.ViewModel, selected: IsSelected)
    typealias Group = [Item]

    let type = T.self
    var rowHeight: CGFloat = 60
    var onCellTapped: ((T.ViewModel, IsSelected) -> Void)?

    private var models: Group = []

    init(models: [(T.ViewModel, IsSelected)]) {
        super.init()
        set(models: models)
    }

    func set(models: [(T.ViewModel, IsSelected)]) {
        self.models = models
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard var cell = tableView.dequeueReusableCell(withIdentifier: T.reuseId) as? T else {
            fatalError("Couldn't cast cell to \(T.self)")
        }
        let viewModel = models[indexPath.row]
        cell.viewModel = viewModel.model
        cell.isSelected = viewModel.selected
        cell.selectedBackgroundView = UIView()
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var viewModel = models[indexPath.row]
        viewModel.selected = true
        models[indexPath.row] = viewModel
        onCellTapped?(viewModel.model, viewModel.selected)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        rowHeight
    }
}
