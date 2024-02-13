//
//  ASCSelectGroupViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 19.04.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSelectGroupViewController: UIViewController {
    // MARK: - Properties

    private var dataArray = [ASCGroupTableViewDataModelItem]()
    private let cellHeight: CGFloat = 60
    private let leftRightInserts: CGFloat = 16
    private let cornerRadius: CGFloat = 10
    private var tableView: UITableView = {
        if #available(iOS 13.0, *) {
            return UITableView(frame: .zero, style: .insetGrouped)
        } else {
            return UITableView(frame: .zero, style: .grouped)
        }
    }()

    weak var delegate: ASCFiltersViewControllerDelegate?

    func markAsSelected(id: String?) {
        deselectAll()
        if let id = id {
            selectItem(byId: id)
        }
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    private func selectItem(byId id: String) {
        for (index, item) in filteredGroup.enumerated() {
            if item.groupId == id {
                filteredGroup[index].isSelected = true
            }
        }
        for (index, item) in dataArray.enumerated() {
            if item.groupId == id {
                dataArray[index].isSelected = true
            }
        }
    }

    private let activityIndicator = UIActivityIndicatorView()
    private lazy var noSearchResultLabel: UILabel = {
        $0.text = NSLocalizedString("No Search Result", comment: "")
        $0.textAlignment = .center
        $0.font = UIFont.preferredFont(forTextStyle: .body)
        $0.textColor = .lightGray
        return $0
    }(UILabel())

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
        configureSearchController()
        setupTableView()
        groupsListRequest()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .never
    }

    private func groupsListRequest() {
        showActivityIndicator()

        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.People.groups) { [unowned self] response, error in
            self.hideActivityIndicator()

            if let error = error {
                log.error(error)
            } else if let groups = response?.result {
                self.dataArray = groups.map {
                    ASCGroupTableViewDataModelItem(
                        groupId: $0.id,
                        groupName: $0.name,
                        isSelected: false
                    )
                }
                .sorted { $0.groupName ?? "" < $1.groupName ?? "" }

                self.tableView.reloadData()
                self.displayPlaceholderIfNeeded()
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
        navigationItem.searchController = searchController
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = NSLocalizedString("Select group", comment: "")
        navigationItem.hidesSearchBarWhenScrolling = false

        let rightBarButton = UIBarButtonItem(
            title: ASCLocalization.Common.cancel,
            style: UIBarButtonItem.Style.plain,
            target: self,
            action: #selector(cancelBarButtonItemTapped)
        )
        navigationItem.rightBarButtonItem = rightBarButton
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView(
            frame: CGRect(
                x: 0, y: 0, width: 1, height: CGFloat.leastNormalMagnitude
            )
        )
        tableView.tableFooterView = UIView(
            frame: CGRect(
                x: 0, y: 0, width: 1, height: leftRightInserts
            )
        )
        view.addSubview(tableView)
        tableView.fillToSuperview()
    }

    @objc private func cancelBarButtonItemTapped() {
        dismiss(animated: true)
    }

    private func showActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator.removeFromSuperview()
        view.addSubview(activityIndicator)

        let tableHeaderHeigh = tableView.tableHeaderView?.height ?? 0

        activityIndicator.centerYAnchor.constraint(
            equalTo: view.centerYAnchor,
            constant: -tableHeaderHeigh - activityIndicator.height
        ).isActive = true
        activityIndicator.anchorCenterXToSuperview()
        activityIndicator.startAnimating()
    }

    private func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }

    private func displayPlaceholderIfNeeded() {
        noSearchResultLabel.removeFromSuperview()

        if numberOfRecords() < 1 {
            view.addSubview(noSearchResultLabel)
            noSearchResultLabel.anchorCenterXToSuperview()
            noSearchResultLabel.anchorCenterYToSuperview(constant: -100)
        }
    }
}

// MARK: - UITableViewDelegate and UITableViewDataSource

extension ASCSelectGroupViewController: UITableViewDelegate, UITableViewDataSource {
    private func numberOfRecords() -> Int {
        if isFiltering {
            return filteredGroup.count
        }
        return dataArray.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRecords()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let dataModel = getDataModel(indexPath: indexPath)

        if #available(iOS 14.0, *) {
            var config = cell.defaultContentConfiguration()
            config.textProperties.adjustsFontSizeToFitWidth = true
            config.textProperties.numberOfLines = 2
            config.textProperties.font = UIFont.preferredFont(forTextStyle: .callout)
            config.text = dataModel.groupName
            cell.automaticallyUpdatesContentConfiguration = true
            cell.contentConfiguration = config
        } else {
            cell.textLabel?.numberOfLines = 2
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
        for (index, _) in filteredGroup.enumerated() {
            filteredGroup[index].isSelected = false
        }

        for (index, _) in dataArray.enumerated() {
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
            delegate?.updateData(filterText: filterText, id: dataModel.groupId)
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
        displayPlaceholderIfNeeded()
    }
}
