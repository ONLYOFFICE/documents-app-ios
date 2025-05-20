//
//  ASCHelpAndFeedbackViewController.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 13/5/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import DocumentConverter
import MessageUI
import SafariServices
import UIKit

class ASCHelpAndFeedbackViewController: ASCBaseTableViewController {
    // MARK: - Section model

    struct SettingsSection {
        var items: [CellType]
        var header: String?
        var footer: String?

        init(items: [CellType], header: String? = nil, footer: String? = nil) {
            self.items = items
            self.header = header
            self.footer = footer
        }
    }

    private var tableData: [SectionType] = []

    // MARK: - Lifecycle Methods

    init() {
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Help & Feedback", comment: "")

        configureTableView()
        build()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if UIDevice.pad {
            navigationController?.navigationBar.prefersLargeTitles = false

            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
        }

        build()
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if UIDevice.pad {
            guard let navigationBar = navigationController?.navigationBar else { return }

            let transparent = (navigationBar.y + navigationBar.height + scrollView.contentOffset.y) > 0

            navigationBar.setBackgroundImage(transparent ? nil : UIImage(), for: .default)
            navigationBar.shadowImage = transparent ? nil : UIImage()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func configureTableView() {
        view.backgroundColor = .systemGroupedBackground
    }

    private func build() {
        var data: [SectionType] = []
        var informationSection: SettingsSection = SettingsSection(items: [])

        if ASCAppSettings.Feature.allowUserVoice {
            informationSection.items.append(
                .standart(viewModel: ASCStandartCellViewModel(
                    title: NSLocalizedString("Suggest a Feature", comment: ""),
                    action: {
                        self.openURL(ASCConstants.Urls.userVoiceUrl)
                    },
                    accessoryType: .disclosureIndicator
                )
                )
            )
        }

        informationSection.items.append(contentsOf: [
            .standart(viewModel: ASCStandartCellViewModel(
                title: NSLocalizedString("Contact Support", comment: ""),
                action: {
                    self.sendFeedback()
                },
                accessoryType: .disclosureIndicator
            )),
            .standart(viewModel: ASCStandartCellViewModel(
                title: NSLocalizedString("Help Center", comment: ""),
                action: {
                    self.openURL(ASCConstants.Urls.helpCenterUrl)
                },
                accessoryType: .disclosureIndicator
            )),
        ]
        )
        let whatsNewSection = SettingsSection(
            items: [
                .standart(viewModel: ASCStandartCellViewModel(
                    title: NSLocalizedString("What's New", comment: ""),
                    action: {
                        WhatsNewService.show(force: true)
                    },
                    accessoryType: .disclosureIndicator
                )),
            ]
        )
        data.append(.standart(viewModel: informationSection))
        data.append(.standart(viewModel: whatsNewSection))

        tableData = data
        tableView?.reloadData()
    }

    // MARK: - Private

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            let svc = SFSafariViewController(url: url)
            present(svc, animated: true, completion: nil)
        }
    }

    private func sendFeedback() {
        let composer = MFMailComposeViewController()
        let localSdkVersion = ASCEditorManager.shared.localSDKVersion().joined(separator: ".")
        var converterVersion = "none"

        converterVersion = DocumentLocalConverter.sdkVersion() ?? ""

        if MFMailComposeViewController.canSendMail() {
            composer.mailComposeDelegate = self
            composer.setToRecipients([ASCConstants.Urls.supportMailTo])
            composer.setSubject(String.localizedStringWithFormat("%@ iOS Feedback", ASCConstants.Name.appNameFull))
            composer.setMessageBody([
                String(repeating: "\n", count: 5),
                String(repeating: "_", count: 20),
                "App version: \(ASCCommon.appVersion ?? "Unknown") (\(ASCCommon.appBuild ?? "Unknown"))",
                "SDK: \(localSdkVersion)",
                "Converter: \(converterVersion)",
                "Device model: \(Device.current.safeDescription)",
                "iOS Version: \(ASCCommon.systemVersion)",
            ].joined(separator: "\n"), isHTML: false)

            present(composer, animated: true, completion: nil)
        } else {
            UIAlertController.showWarning(
                in: self,
                message: NSLocalizedString("Failed to send feedback by mail. Try to write your request on our forum.", comment: ""),
                actions: [
                    UIAlertAction(title: NSLocalizedString("Go to forum", comment: ""), handler: { action in
                        if let url = URL(string: ASCConstants.Urls.applicationFeedbackForum), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }),
                ]
            )
        }
    }
}

// MARK: - MFMailComposeViewController Delegate

extension ASCHelpAndFeedbackViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result:
        MFMailComposeResult, error: Error?
    ) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Table view data source

extension ASCHelpAndFeedbackViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        tableData.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData[section].toSection().items.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellType(by: indexPath).toCell(tableView: tableView)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        tableData[section].toSection().header
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        tableData[section].toSection().footer
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch cellType(by: indexPath) {
        case let .standart(model):
            model.action?()
        }
    }

    private func cellType(by indexPath: IndexPath) -> CellType {
        tableData[indexPath.section].toSection().items[indexPath.row]
    }
}

// MARK: - Cell types

extension ASCHelpAndFeedbackViewController {
    enum CellType {
        case standart(viewModel: ASCStandartCellViewModel)

        public func viewModel() -> Any {
            switch self {
            case let .standart(viewModel):
                return viewModel
            }
        }

        public func toCell(tableView: UITableView) -> UITableViewCell {
            switch self {
            case let .standart(viewModel):
                return makeStandartCell(viewModel, for: tableView) ?? makeDefaultCell()
            }
        }

        private func makeStandartCell(_ viewModel: ASCStandartCellViewModel, for tableView: UITableView) -> UITableViewCell? {
            guard let cell = ASCStandartCell.createForTableView(tableView) as? ASCStandartCell else { return nil }
            cell.viewModel = viewModel
            return cell
        }

        private func makeDefaultCell() -> UITableViewCell {
            UITableViewCell()
        }
    }
}

// MARK: - Section types

extension ASCHelpAndFeedbackViewController {
    enum SectionType {
        case standart(viewModel: SettingsSection)

        public func toSection() -> SettingsSection {
            switch self {
            case let .standart(viewModel):
                return viewModel
            }
        }

        var viewModel: SettingsSection {
            get {
                switch self {
                case let .standart(viewModel):
                    return viewModel
                }
            }

            set {
                switch self {
                case .standart:
                    self = .standart(viewModel: newValue)
                }
            }
        }
    }
}
