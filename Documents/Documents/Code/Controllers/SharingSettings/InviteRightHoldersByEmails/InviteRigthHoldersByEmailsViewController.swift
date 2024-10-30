//
//  InviteRigthHoldersByEmailsViewController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 25/10/22.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import IQKeyboardManagerSwift
import UIKit
import WSTagsField

class InviteRigthHoldersByEmailsViewController: UIViewController {
    // MARK: - Properties

    private var cancellables: Set<AnyCancellable> = []

    let viewModel: InviteRigthHoldersByEmailsViewModel
    var isNextBarBtnEnabled: Bool {
        !tagsView.tags.isEmpty
    }

    private var accessBarBtnMenu: UIMenu {
        let accessList = viewModel.accessProvides()
        let menuItems = accessList
            .map { access in
                UIAction(title: access.title(),
                         image: access.image(),
                         state: access == viewModel.currentAccess ? .on : .off,
                         handler: { [unowned self, access] action in viewModel.accessChangeHandler(access) })
            }
        return UIMenu(title: "", children: menuItems)
    }

    lazy var tagsView: WSTagsField = {
        let tagsField = WSTagsField()
        tagsField.layer.cornerRadius = 10
        tagsField.backgroundColor = .secondarySystemGroupedBackground
        tagsField.textField.keyboardType = .emailAddress
        tagsField.textField.returnKeyType = .go
        tagsField.placeholder = NSLocalizedString("Enter email", comment: "placeholder")
        tagsField.cornerRadius = 6.0
        tagsField.spaceBetweenLines = 16
        tagsField.spaceBetweenTags = 6
        tagsField.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        tagsField.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        tagsField.placeholderAlwaysVisible = true
        tagsField.tintColor = Asset.Colors.brend.color
        tagsField.textColor = .link
        tagsField.selectedColor = Asset.Colors.brend.color
        tagsField.selectedTextColor = .white
        tagsField.enableScrolling = true
        tagsField.isScrollEnabled = true
        tagsField.showsVerticalScrollIndicator = true
        tagsField.inputFieldAccessoryView = UIView()

        tagsField.onDidAddTag = { [weak self] field, tag in
            field.tagViews.forEach { $0.tintColor = Asset.Colors.systemFillQuarternary.color }
            field.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
            self?.checkQouta()
            self?.updateToolbars()
        }

        tagsField.onDidRemoveTag = { [weak self] field, tag in
            if field.tags.isEmpty {
                field.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            }
            self?.updateToolbars()
        }

        tagsField.onShouldAcceptTag = { field in
            field.text?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isValidOnlyofficeEmail ?? false
        }

        return tagsField
    }()

    lazy var scrollView: UIScrollView = {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 10
        $0.backgroundColor = .clear
        return $0
    }(UIScrollView(frame: .zero))

    // MARK: - Lifecycle Methods

    init(viewModel: InviteRigthHoldersByEmailsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        viewModel.currentAccessPubliser
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkQouta()
                self?.updateToolbars()
            }.store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.loadPaymentQouta { [weak self] in
            self?.checkQouta()
        }

        let backTitle = NSLocalizedString("Back", comment: "")
        let backButton = UIBarButtonItem(title: backTitle, style: .plain, target: self, action: #selector(showSureDismissAlert))
        backButton.image = UIImage(systemName: "chevron.left")
        navigationItem.leftBarButtonItem = backButton

        title = NSLocalizedString("Invite people", comment: "")
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(scrollView)
        scrollView.anchor(
            top: view.safeAreaLayoutGuide.topAnchor,
            leading: view.leadingAnchor,
            bottom: view.safeAreaLayoutGuide.bottomAnchor,
            trailing: view.trailingAnchor,
            padding: UIEdgeInsets(
                top: 20,
                left: 20,
                bottom: 50,
                right: 20
            )
        )

        scrollView.addSubview(tagsView)
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        tagsView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        tagsView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        tagsView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        tagsView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

        let touchGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGuestureRecognize))
        tagsView.addGestureRecognizer(touchGestureRecognizer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        IQKeyboardManager.shared.enable = true

        configureToolBar()
        tagsView.textField.becomeFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        IQKeyboardManager.shared.enable = false
    }

    @objc func tapGuestureRecognize() {
        tagsView.textField.becomeFirstResponder()
    }

    func checkQouta() {
        guard let managerQouta = viewModel.managerQouta,
              let maxManagerQouta = managerQouta.value,
              let usedManagerQoura = managerQouta.used?.value,
              case .roomManager = viewModel.currentAccess
        else { return }

        let anableQouta = maxManagerQouta - usedManagerQoura - tagsView.tags.count
        if anableQouta == 1 {
            showQoutaAlmostExhausted()
        } else if anableQouta <= 0 {
            showQoutaReached()
        }
    }

    func showQoutaAlmostExhausted() {
        let message = NSLocalizedString("The quota of users is almost exhausted. Сontact the portal administrator", comment: "")
        let controller = UIAlertController(title: "", message: message, preferredStyle: .alert).okable()
        present(controller, animated: true)
    }

    func showQoutaReached() {
        let message = NSLocalizedString("The user limit has been reached. Сontact the portal administrator", comment: "")
        let controller = UIAlertController(title: "", message: message, preferredStyle: .alert).okable()
        present(controller, animated: true)
    }

    @objc func showSureDismissAlert() {
        guard !tagsView.tags.isEmpty else {
            navigationController?.dismiss(animated: true)
            return
        }
        let title = NSLocalizedString("Cancel invitation?", comment: "")
        let message = NSLocalizedString("Selected users will not be invited to the room", comment: "")
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addOk { [unowned self] _ in
            navigationController?.popViewController(animated: true)
        }
        controller.addCancel()
        present(controller, animated: true)
    }

    // MARK: - Toolbar

    func configureToolBar() {
        navigationController?.isToolbarHidden = false
        updateToolbars()
    }

    func updateToolbars() {
        toolbarItems = makeToolbarItems()
    }

    private func makeToolbarItems() -> [UIBarButtonItem] {
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let currentAccess = viewModel.currentAccess
        let accessBarBtnItem = makeAccessBarBtn(title: currentAccess.title(), image: currentAccess.image())
        return [accessBarBtnItem, spaceItem, makeNextBarBtn()]
    }

    private func makeAccessBarBtn(title: String, image: UIImage?) -> UIBarButtonItem {
        let barBtn = UIButton(type: .system)
        barBtn.setTitle(title, for: .normal)
        barBtn.setImage(image, for: .normal)
        barBtn.contentEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 8)
        barBtn.titleEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: -barBtn.contentEdgeInsets.right)
        barBtn.titleLabel?.font = .systemFont(ofSize: 17)
        barBtn.tintColor = Asset.Colors.brend.color
        let barBtnItem = UIBarButtonItem(customView: barBtn)
        barBtnItem.target = self
        if #available(iOS 14, *) {
            barBtn.showsMenuAsPrimaryAction = true
            barBtn.menu = accessBarBtnMenu
        } else {
            barBtn.addTarget(self, action: #selector(showAccessSheet), for: .touchUpInside)
        }

        return barBtnItem
    }

    private func makeNextBarBtn() -> UIBarButtonItem {
        let nextBtn = ASCButtonStyle()
        nextBtn.styleType = .capsule
        nextBtn.setTitleForAllStates(NSLocalizedString("Next", comment: "").uppercased())
        nextBtn.addTarget(self, action: #selector(onNextButtonTapped), for: .touchUpInside)
        nextBtn.isEnabled = isNextBarBtnEnabled

        Task { @MainActor [weak nextBtn] in
            nextBtn?.iq.enableMode = isNextBarBtnEnabled ? .enabled : .disabled
        }

        let barItem = UIBarButtonItem(customView: nextBtn)
        barItem.isEnabled = isNextBarBtnEnabled
        return barItem
    }

    @objc func onNextButtonTapped() {
        viewModel.nextTapClosure(tagsView.tags.map { $0.text }, viewModel.currentAccess)
    }

    @objc func showAccessSheet() {
        let accessController = UIAlertController(
            title: NSLocalizedString("Selecting access rights", comment: ""),
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )
        let accessList = viewModel.accessProvides()
        for access in accessList {
            accessController.addAction(UIAlertAction(
                title: access.title(),
                style: access == .deny ? .destructive : .default,
                handler: { [unowned self] _ in self.viewModel.accessChangeHandler(access) }
            ))
        }

        accessController.addAction(
            UIAlertAction(
                title: ASCLocalization.Common.cancel,
                style: .cancel,
                handler: nil
            )
        )

        present(accessController, animated: true, completion: nil)
    }
}
