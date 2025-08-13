//
//  ASCTransferViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 4/13/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import FileKit
import Kingfisher
import UIKit

typealias ASCTransferViewType = (provider: ASCFileProviderProtocol?, entity: ASCEntity)

protocol ASCTransferView: UIViewController {
    func updateViewData(data: ASCTransferViewModel)
    func showLoadingPage(_ show: Bool)
}

class ASCTransferViewController: UITableViewController {
    typealias TableData = ASCTransferViewModel.TableData

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
                switch viewModel.image {
                case let .image(image):
                    cell.leftImageView.image = image
                case let .kfImage(
                    url,
                    provider,
                    placeholder,
                    defaultImage,
                    cornerRadius,
                    targetSize
                ):
                    let processor = RoundCornerImageProcessor(
                        cornerRadius: cornerRadius,
                        targetSize: targetSize
                    )
                    cell.leftImageView.kf.setProviderImage(
                        with: url,
                        for: provider,
                        placeholder: placeholder,
                        options: [
                            .processor(processor),
                        ],
                        completionHandler: { [weak cell] result in
                            switch result {
                            case .success:
                                break
                            case .failure:
                                cell?.leftImageView.image = defaultImage
                            }
                        }
                    )
                    cell.leftImageView.layerCornerRadius = cornerRadius
                }
                cell.titleLabel.text = viewModel.title
                cell.badgeImageView.image = viewModel.badgeImage
                cell.rightBadgeImageView.image = viewModel.rightBadgeImage
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
                cell.rightBadgeImageView.image = nil
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

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        presenter.willDisplay(at: indexPath)
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
    func updateViewData(data: ASCTransferViewModel) {
        title = title ?? data.title
        navigationItem.prompt = data.navPrompt
        configureToolBar(items: data.toolBarItems)
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

    private func configureToolBar(items: [ASCTransferViewModel.BarButtonItem]) {
        let barButtonItems: [UIBarButtonItem] = items.map { item in
            switch item.type {
            case .capsule:
                return UIBarButtonItem.makeCapsuleBarButtonItem(
                    title: item.title,
                    isEnabled: item.isEnabled,
                    item.onTapHandler
                )
            case .plain:
                let barItem = UIBarButtonItem(
                    title: item.title,
                    style: .plain,
                    closure: item.onTapHandler
                )
                barItem.isEnabled = item.isEnabled
                return barItem
            }
        }
        /// add space between bar buttons
        var resultButtonItems: [UIBarButtonItem] = []

        for (index, button) in barButtonItems.enumerated() {
            resultButtonItems.append(button)
            /// do not add in the end
            if index != barButtonItems.count - 1 {
                resultButtonItems.append(.flexibleSpace())
            }
        }

        setToolbarItems(resultButtonItems, animated: false)
    }
}
