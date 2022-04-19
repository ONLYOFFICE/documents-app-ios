//
//  ASCSelectUserViewController.swift
//  Documents
//
//  Created by Лолита Чернышева on 15.04.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSelectUserViewController: UIViewController {
    // MARK: - properties

    private var dataArray = [ASCSelectUserTableViewDataModelItem]()
    private var cellHeight: CGFloat = 60
    private var tableView = UITableView()
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Asset.Colors.tableCategoryBackground.color
        searchController.searchBar.delegate = self
        setupNavigationBar()
        usersListRequest()
        setupTableView()
        configureSearchController()
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
            title: NSLocalizedString("Cancel", comment: ""),
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

    private func usersListRequest() {
        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.People.all) { [weak self] response, error in
            if let error = error {
                log.error(error)
            } else if let users = response?.result {
                for user in users {
                    let firstName = user.firstName ?? ""
                    let lastName = user.lastName ?? ""
                    let fullName = "\(lastName) \(firstName)".trimmed

                    let userName = fullName
                    let department = user.department
                    let avatarUrl = user.avatar
                    let id = user.userId

                    self?.dataArray.append(ASCSelectUserTableViewDataModelItem(id: id, avatarImageUrl: avatarUrl, userName: userName, userPosition: department))
                }

                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }
            }
        }
    }
}

extension ASCSelectUserViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ASCSharingRightHolderTableViewCell.reuseId, for: indexPath) as? ASCSharingRightHolderTableViewCell else { return UITableViewCell() }

        let dataModel = dataArray[indexPath.row]
        cell.viewModel = .init(id: dataModel.id ?? "",
                               avatarUrl: dataModel.avatarImageUrl,
                               name: dataModel.userName ?? "",
                               department: dataModel.userPosition)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
}

// MARK: - UISearchBarDelegate

extension ASCSelectUserViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        print("Search")
    }
}
