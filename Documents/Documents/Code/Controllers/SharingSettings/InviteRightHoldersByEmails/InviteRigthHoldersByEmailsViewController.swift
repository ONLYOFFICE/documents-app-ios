//
//  InviteRigthHoldersByEmailsViewController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 25/10/22.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit
import WSTagsField

class InviteRigthHoldersByEmailsViewController: UIViewController {
    let viewModel: InviteRigthHoldersByEmailsViewModel

    init(viewModel: InviteRigthHoldersByEmailsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var tagsView: WSTagsField = {
        let tagsView = WSTagsField()
        tagsView.textField.delegate = self
        tagsView.backgroundColor = .systemBackground
        tagsView.textField.placeholder = NSLocalizedString("Enter email", comment: "placeholder")
        tagsView.layer.cornerRadius = 6
        tagsView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        tagsView.spaceBetweenLines = 10.0
        tagsView.tintColor = UIColor(hex: "#747480").withAlphaComponent(0.08)
        tagsView.textColor = .systemBlue
        return tagsView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tagsView)
        view.backgroundColor = .groupTableViewBackground
        title = NSLocalizedString("Invite people", comment: "")

        tagsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tagsView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            tagsView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            tagsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            tagsView.heightAnchor.constraint(lessThanOrEqualToConstant: 200),
        ])
    }
}

extension InviteRigthHoldersByEmailsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string.rangeOfCharacter(from: .whitespacesAndNewlines) != nil else { return true }
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let textFieldText = textField.text, textFieldText.isEmail else { return false }
        tagsView.addTag(textFieldText)
        textField.text = ""
        return true
    }
}

let __firstpartEmailPattern = "[A-Z0-9a-z]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
let __serverpartEmailPattern = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
let __emailRegex = __firstpartEmailPattern + "@" + __serverpartEmailPattern + "[A-Za-z]{2,8}"
let __emailPredicate = NSPredicate(format: "SELF MATCHES %@", __emailRegex)

extension String {
    var isEmail: Bool {
        return __emailPredicate.evaluate(with: self)
    }
}
