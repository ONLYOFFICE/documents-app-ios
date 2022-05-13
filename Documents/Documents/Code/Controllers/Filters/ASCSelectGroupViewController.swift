//
//  ASCSelectGroupViewController.swift
//  Documents
//
//  Created by Лолита Чернышева on 19.04.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSelectGroupViewController: UIViewController {
    // MARK: - properties

    private var dataArray = [ASCGroupTableViewDataModelItem]()
    private let cellHeight: CGFloat = 60
    private let leftRightInserts: CGFloat = 16
    private let cornerRadius: CGFloat = 10
    private var tableView = UITableView()
    weak var delegate: ASCFiltersViewControllerDelegate?

    // MARK: - Search

    let searchController = UISearchController(searchResultsController: nil)
    private var filteredGroup = [ASCGroupTableViewDataModelItem]()
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }

    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Asset.Colors.tableCategoryBackground.color
        searchController.searchBar.delegate = self
        setupNavigationBar()
        groupsListRequest()
        setupTableView()
        configureSearchController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .never
    }

    private func groupsListRequest() {
        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.People.groups) { [unowned self] response, error in
            if let error = error {
                log.error(error)
            } else if let groups = response?.result {
                for group in groups {
                    let groupName = group.name
                    let id = group.id

                    self.dataArray.append(ASCGroupTableViewDataModelItem(groupId: id, groupName: groupName, isSelected: false))
                }

                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }
            }
        }
    }

    private func configureSearchController() {
        searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "")
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.searchController = searchController
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = NSLocalizedString("Select group", comment: "")
        navigationItem.hidesSearchBarWhenScrolling = false

        let rightBarButton = UIBarButtonItem(
            title: NSLocalizedString("Cancel", comment: ""),
            style: UIBarButtonItem.Style.plain,
            target: self,
            action: #selector(cancelBarButtonItemTapped)
        )
        navigationItem.rightBarButtonItem = rightBarButton
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = Asset.Colors.viewBackground.color
        tableView.layer.cornerRadius = cornerRadius

        view.addSubview(tableView)
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                         left: view.leftAnchor,
                         bottom: view.bottomAnchor,
                         right: view.rightAnchor,
                         leftConstant: leftRightInserts,
                         rightConstant: leftRightInserts)
    }

    @objc private func cancelBarButtonItemTapped() {
        dismiss(animated: true)
    }
}

extension ASCSelectGroupViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredGroup.count
        }
        return dataArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let dataModel = getDataModel(indexPath: indexPath)

        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = dataModel.groupName
            cell.contentConfiguration = content
        } else {
            cell.textLabel?.text = dataModel.groupName
        }

        if dataModel.isSelected == true {
            cell.accessoryType = .checkmark
        }
        return cell
    }

    func getDataModel(indexPath: IndexPath) -> ASCGroupTableViewDataModelItem {
        if isFiltering {
            return filteredGroup[indexPath.row]
        } else {
            return dataArray[indexPath.row]
        }
    }

    func deselectAll() {
        filteredGroup.enumerated().forEach { index, _ in
            filteredGroup[index].isSelected = false
        }

        dataArray.enumerated().forEach { index, _ in
            dataArray[index].isSelected = false
        }
    }

    func selectCell(indexPath: IndexPath) {
        let index: Int? = {
            if isFiltering {
                return filteredGroup.firstIndex { item in
                    item.isSelected == true
                }
            } else {
                return dataArray.firstIndex { item in
                    item.isSelected == true
                }
            }
        }()
        if let index = index {
            let previousCellIndexPath = IndexPath(row: index, section: 0)
            tableView.cellForRow(at: previousCellIndexPath)?.accessoryType = .none
        }
        deselectAll()

        let model = getDataModel(indexPath: indexPath)
        if let dataArrayIndex = dataArray.firstIndex(where: { item in
            guard let itemId = item.groupId, let modelId = model.groupId else { return false }
            return itemId == modelId
        }) {
            dataArray[dataArrayIndex].isSelected = true
        }

        if let filteredGroupArrayIndex = filteredGroup.firstIndex(where: { item in
            guard let itemId = item.groupId, let modelId = model.groupId else { return false }
            return itemId == modelId
        }) {
            filteredGroup[filteredGroupArrayIndex].isSelected = true
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataModel = getDataModel(indexPath: indexPath)
        if let filterText = dataModel.groupName {
            delegate?.updateData(filterText: filterText)
        }
        selectCell(indexPath: indexPath)
        dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
}

// MARK: - UISearchBarDelegate

extension ASCSelectGroupViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchedText = searchController.searchBar.text else { return }
        filterContentForSearchText(searchedText)
    }

    private func filterContentForSearchText(_ searchText: String) {
        filteredGroup = dataArray.filter { (group: ASCGroupTableViewDataModelItem) -> Bool in
            (group.groupName?.lowercased().contains(searchText.lowercased())) ?? false
        }
        tableView.reloadData()
    }
}
