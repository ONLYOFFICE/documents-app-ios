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
    
    private(set) var selectedRows: [IndexPath] = []
    
    private var groupedModels: [Section] = []
    
    init(models: [T.ViewModel] = []) {
        super.init()
        set(models: models, selectedIndexes: [])
    }
    
    func set(models: [T.ViewModel], selectedIndexes: [Int]) {
        var currentIndex = -1
        groupedModels = models
            .reduce([], { result, model in
                guard let firstLetter = model.name.first else { return result }
                currentIndex += 1
                guard let section = result.last else {
                    let section =  Section(index: firstLetter, models: [model])
                    if selectedIndexes.contains(currentIndex) {
                        selectedRows.append(IndexPath(row: 0, section: 0))
                    }
                    return [section]
                }
                guard section.index == firstLetter else {
                    var result = result
                    result.append(Section(index: firstLetter, models: [model]))
                    if selectedIndexes.contains(currentIndex) {
                        selectedRows.append(IndexPath(row: 0, section: result.count - 1))
                    }
                    return result
                }
                
                section.models.append(model)
                if selectedIndexes.contains(currentIndex) {
                    selectedRows.append(IndexPath(row: section.models.count - 1, section: result.count - 1))
                }
                return result
            })
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
        if selectedRows.contains(indexPath) {
            cell.isSelected = true
        }
        let viewModel = groupedModels[indexPath.section].models[indexPath.row]
        cell.viewModel = viewModel
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRows.append(indexPath)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        selectedRows.removeAll(indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        rowHeight
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
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
        var models: [T.ViewModel]
        
        init(index: Character, models: [T.ViewModel]) {
            self.index = index
            self.models = models
        }
    }
}
