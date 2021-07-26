//
//  ASCSharingAddRightHoldersTableViewDataSourceAndDelegate.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<T: UITableViewCell & ASCReusedIdentifierProtocol & ASCViewModelSetter>:
    NSObject, UITableViewDataSource, UITableViewDelegate where T.ViewModel: ASCNamedProtocol {
    
    let type = T.self
    var rowHeight: CGFloat = 60
    var onCellTapped: ((T.ViewModel, IsSelected) -> Void)?
    
    private var groupedModels: [Section] = []
    
    init(models: [(T.ViewModel, IsSelected)] = []) {
        super.init()
        set(models: models)
    }
    
    func set(models: [(T.ViewModel, IsSelected)]) {
        groupedModels = models
            .reduce([], { result, model in
                guard let firstLetter = model.0.name.uppercased().first else { return result }
                guard let section = result.last else {
                    let section =  Section(index: firstLetter, models: [model])
                    return [section]
                }
                guard section.index == firstLetter else {
                    var result = result
                    result.append(Section(index: firstLetter, models: [model]))
                    return result
                }
                
                section.models.append(model)
                return result
            })
    }
    
    func getModels() -> [(T.ViewModel, IsSelected)] {
        groupedModels.reduce([]) { result, section in
            var result = result
            result.append(contentsOf: section.models)
            return result
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        groupedModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedModels[section].models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard var cell = tableView.dequeueReusableCell(withIdentifier: T.reuseId) as? T else {
            fatalError("Couldn't cast cell to \(T.self)")
        }
        let viewModel = groupedModels[indexPath.section].models[indexPath.row]
        
        cell.viewModel = viewModel.model
        cell.isSelected = viewModel.selected
        cell.selectedBackgroundView = UIView()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let viewModel = groupedModels[indexPath.section].models[indexPath.row]
        cell.setSelected(viewModel.selected, animated: false)
        if viewModel.selected {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var viewModel = groupedModels[indexPath.section].models[indexPath.row]
        viewModel.selected = true
        groupedModels[indexPath.section].models[indexPath.row] = viewModel
        onCellTapped?(viewModel.model, viewModel.selected)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        var viewModel = groupedModels[indexPath.section].models[indexPath.row]
        viewModel.selected = false
        groupedModels[indexPath.section].models[indexPath.row] = viewModel
        onCellTapped?(viewModel.model, viewModel.selected)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        rowHeight
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        rowHeight
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        groupedModels.map({ "\($0.index)" })
    }
    
    func tableView(_ tableView: UITableView,
                   sectionForSectionIndexTitle title: String,
                   at index: Int) -> Int {
        return index
    }
    
    class Section {
        var index: Character
        var models: [(model: T.ViewModel, selected: IsSelected)]
        
        init(index: Character, models: [(T.ViewModel, IsSelected)]) {
            self.index = index
            self.models = models
        }
    }
}
