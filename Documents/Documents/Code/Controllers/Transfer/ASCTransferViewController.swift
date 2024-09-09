//
//  ASCTransferViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 4/13/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import FileKit
import UIKit

typealias ASCTransferViewType = (provider: ASCFileProviderProtocol?, entity: ASCEntity)

protocol ASCTransferView: UIViewController {
    func updateViewData(data: ASCTransferViewData)
    func showLoadingPage(_ show: Bool)
}

class ASCTransferViewController: UITableViewController {
    typealias TableData = ASCTransferViewData.TableData

    // MARK: - Public

    var presenter: ASCTransferPresenterProtocol!

    // MARK: - Private

    private var tableData: TableData = .empty {
        didSet {
            tableView.reloadData()
        }
    }

    // MARK: - Outlets

    @IBOutlet var actionButton: UIBarButtonItem!
    @IBOutlet var emptyView: UIView!
    @IBOutlet var loadingView: UIView!

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundView = UIView()
        tableView.tableFooterView = UIView()

        showLoadingPage(true)
        presenter.viewDidLoad()

        if let refreshControl = refreshControl {
            refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presenter.rebuild()

        // Layout loader
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            if loadingView?.superview != nil {
                loadingView?.centerYAnchor.constraint(
                    equalTo: view.centerYAnchor,
                    constant: -view.safeAreaInsets.top
                ).isActive = true
            }
        }
    }

    @objc func refresh(_ refreshControl: UIRefreshControl) {
        presenter?.fetchData()
    }

    func showLoadingPage(_ show: Bool) {
        if show {
            showEmptyView(false)
            view.addSubview(loadingView)

            loadingView.translatesAutoresizingMaskIntoConstraints = false
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -view.safeAreaInsets.top).isActive = true

            tableView.isUserInteractionEnabled = false
        } else {
            loadingView.removeFromSuperview()
            tableView.isUserInteractionEnabled = true
        }
    }

    // MARK: - Private

    private func showEmptyView(_ show: Bool) {
        if !show {
            emptyView.removeFromSuperview()
        } else {
            view.addSubview(emptyView)

            emptyView.translatesAutoresizingMaskIntoConstraints = false
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -view.safeAreaInsets.top).isActive = true
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellFolderCellId = "TransferFolderCell"

        if tableData.cells.isEmpty {
            showEmptyView(true)
        } else {
            showEmptyView(false)

            let cell = tableData.cells[indexPath.row]

            switch cell {
            case let .folder(viewModel):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: cellFolderCellId, for: indexPath) as? ASCTransferViewCell else {
                    return UITableViewCell()
                }
                cell.leftImageView.image = viewModel.image
                cell.titleLabel.text = viewModel.title
                cell.isUserInteractionEnabled = viewModel.isInteractable
                cell.contentView.alpha = viewModel.isInteractable ? 1 : 0.5
                cell.accessoryType = .disclosureIndicator
                return cell
            case let .file(viewModel):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: cellFolderCellId, for: indexPath) as? ASCTransferViewCell else {
                    return UITableViewCell()
                }
                cell.leftImageView.image = viewModel.image
                cell.titleLabel.text = viewModel.title
                cell.accessoryType = .none
                return cell
            }
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableData.cells[indexPath.row]

        switch cell {
        case let .folder(viewModel):
            guard viewModel.isInteractable else { return }
            viewModel.onTapAction()
        case let .file(viewModel):
            viewModel.onTapAction()
        }
    }

    // MARK: - Actions

    @IBAction func onClose(_ sender: UIBarButtonItem) {
        presenter.onClose()
    }

    @IBAction func onDone(_ sender: UIBarButtonItem) {
        presenter.onDone()
    }
}

extension ASCTransferViewController: ASCTransferView {
    func updateViewData(data: ASCTransferViewData) {
        title = title ?? data.title
        navigationItem.prompt = data.navPrompt
        if !data.actionButtonTitle.isEmpty {
            actionButton?.title = data.actionButtonTitle
            actionButton?.isEnabled = data.isActionButtonEnabled
        } else {
            setToolbarItems([], animated: false)
        }
        updateTableData(data.tableData)
    }

    private func updateTableData(_ tableData: TableData) {
        self.tableData = tableData
        refreshControl?.endRefreshing()
        if !presenter.isLoading {
            showLoadingPage(false)
            showEmptyView(self.tableData.cells.isEmpty)
        }
        tableView.reloadData()
    }
}
