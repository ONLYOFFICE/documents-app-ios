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
    private var cellHeight: CGFloat = 60
    private var tableView = UITableView()

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

                    self.dataArray.append(ASCGroupTableViewDataModelItem(groupId: id, groupName: groupName))
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
        tableView.layer.cornerRadius = 10

        view.addSubview(tableView)
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                         left: view.leftAnchor,
                         bottom: view.bottomAnchor,
                         right: view.rightAnchor,
                         leftConstant: 16,
                         rightConstant: 16)
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

        let dataModel: ASCGroupTableViewDataModelItem

        if isFiltering {
            dataModel = filteredGroup[indexPath.row]
        } else {
            dataModel = dataArray[indexPath.row]
        }

        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = dataModel.groupName
            cell.contentConfiguration = content
        } else {
            cell.textLabel?.text = dataModel.groupName
        }
        return cell
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
