//
//  ASCSelectUserViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 15.04.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSelectUserViewController: UIViewController {
    private enum Constants {
        static let cellHeight: CGFloat = 60
        static let leftRightInserts: CGFloat = 16
        static let cornerRadius: CGFloat = 10
    }

    // MARK: - Properties

    private var dataArray = [ASCUserTableViewDataModelItem]()
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
        filteredUsers.enumerated().forEach { index, item in
            if item.id == id {
                filteredUsers[index].isSelected = true
            }
        }
        dataArray.enumerated().forEach { index, item in
            if item.id == id {
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
    private var filteredUsers = [ASCUserTableViewDataModelItem]()
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
        usersListRequest()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .never
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
        navigationItem.title = NSLocalizedString("Select user", comment: "")
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
        tableView.register(ASCSharingRightHolderTableViewCell.self, forCellReuseIdentifier: ASCSharingRightHolderTableViewCell.reuseId)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView(
            frame: CGRect(
                x: 0, y: 0, width: 1, height: CGFloat.leastNormalMagnitude
            )
        )
        tableView.tableFooterView = UIView(
            frame: CGRect(
                x: 0, y: 0, width: 1, height: Constants.leftRightInserts
            )
        )
        view.addSubview(tableView)
        tableView.fillToSuperview()
    }

    @objc private func cancelBarButtonItemTapped() {
        dismiss(animated: true)
    }

    private func usersListRequest() {
        showActivityIndicator()

        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.People.all) { [weak self] response, error in
            self?.hideActivityIndicator()

            if let error = error {
                log.error(error)
            } else if let users = response?.result {
                self?.dataArray = users.map {
                    ASCUserTableViewDataModelItem(
                        id: $0.userId,
                        avatarImageUrl: $0.avatar,
                        userName: $0.displayName,
                        userPosition: $0.displayName,
                        isSelected: false,
                        isOwner: $0.isOwner
                    )
                }
                .sorted { $0.userName ?? "" < $1.userName ?? "" }

                self?.tableView.reloadData()
                self?.displayPlaceholderIfNeeded()
            }
        }
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

extension ASCSelectUserViewController: UITableViewDelegate, UITableViewDataSource {
    private func tableData() -> [ASCUserTableViewDataModelItem] {
        isFiltering ? filteredUsers : dataArray
    }

    private func numberOfRecords() -> Int {
        tableData().count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRecords()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ASCSharingRightHolderTableViewCell.reuseId, for: indexPath) as? ASCSharingRightHolderTableViewCell else { return UITableViewCell() }

        // Data
        let dataModel = getDataModel(indexPath: indexPath)

        cell.viewModel = .init(id: dataModel.id ?? "",
                               avatarUrl: dataModel.avatarImageUrl,
                               name: dataModel.userName ?? "",
                               department: dataModel.userPosition)

        if dataModel.isSelected == true {
            cell.accessoryType = .checkmark
        }

        return cell
    }

    func getDataModel(indexPath: IndexPath) -> ASCUserTableViewDataModelItem {
        tableData()[indexPath.row]
    }

    func deselectAll() {
        filteredUsers.enumerated().forEach { index, _ in
            filteredUsers[index].isSelected = false
        }

        dataArray.enumerated().forEach { index, _ in
            dataArray[index].isSelected = false
        }
    }

    func selectCell(indexPath: IndexPath) {
        let index: Int? = tableData().firstIndex { item in
            item.isSelected == true
        }
        if let index = index {
            let previousCellIndexPath = IndexPath(row: index, section: 0)
            tableView.cellForRow(at: previousCellIndexPath)?.accessoryType = .none
        }

        deselectAll()

        let model = getDataModel(indexPath: indexPath)
        if let dataArrayIndex = dataArray.firstIndex(where: { item in
            guard let itemId = item.id, let modelId = model.id else { return false }
            return itemId == modelId
        }) {
            dataArray[dataArrayIndex].isSelected = true
        }

        if let filteredUsersArrayIndex = filteredUsers.firstIndex(where: { item in
            guard let itemId = item.id, let modelId = model.id else { return false }
            return itemId == modelId
        }) {
            filteredUsers[filteredUsersArrayIndex].isSelected = true
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataModel = getDataModel(indexPath: indexPath)
        if let filterText = dataModel.userName {
            delegate?.updateData(filterText: filterText, id: dataModel.id)
        }
        selectCell(indexPath: indexPath)
        dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        // No sections, so scroll manually
        if let firstIndex = tableData().firstIndex(where: { title == "\(($0.userName ?? " ").uppercased().first ?? " ")" }) {
            tableView.scrollToRow(at: IndexPath(row: firstIndex, section: 0), at: .top, animated: false)
        }
        return index
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        tableData()
            .map { "\(($0.userName ?? " ").uppercased().first ?? " ")" }
            .withoutDuplicates()
    }
}

// MARK: - UISearchBarDelegate

extension ASCSelectUserViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchedText = searchController.searchBar.text else { return }
        filterContentForSearchText(searchedText)
    }

    private func filterContentForSearchText(_ searchText: String) {
        filteredUsers = dataArray.filter { (user: ASCUserTableViewDataModelItem) -> Bool in
            (user.userName?.lowercased().contains(searchText.lowercased())) ?? false
        }

        tableView.reloadData()
        displayPlaceholderIfNeeded()
    }
}
