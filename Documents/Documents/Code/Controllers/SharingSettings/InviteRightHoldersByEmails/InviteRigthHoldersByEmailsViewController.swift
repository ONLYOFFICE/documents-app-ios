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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var tagsView: WSTagsField = {
        let tagsView = WSTagsField()
        tagsView.textField.delegate = self
        tagsView.backgroundColor = .white
        tagsView.textField.placeholder = NSLocalizedString("Enter email", comment: "placeholder")
        tagsView.layer.cornerRadius = 4
        return tagsView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tagsView)

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
