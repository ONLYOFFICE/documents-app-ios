//
//  ASCTextFiieldTableViewCell.swift
//  Documents
//
//  Created by Pavel Chernyshev on 25.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCTextViewTableViewCell: UITableViewCell, ASCReusedIdentifierProtocol, ASCViewModelSetter {
    static var reuseId: String = "TextFiieldTableViewCell"

    var viewModel: ASCTextFieldCellViewModel? {
        didSet {
            configureContentView()
        }
    }

    let textView = UITextView()
    var hSpacing: CGFloat = 16
    var vSpacing: CGFloat = 10

    var placeHolderText = ""

    func configureContentView() {
        selectionStyle = .none
        guard let viewModel = viewModel else { return }

        textView.delegate = self
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = contentView.backgroundColor
        placeHolderText = viewModel.placeholder ?? ""
        if let viewModelText = viewModel.text, !viewModelText.isEmpty {
            textView.text = viewModelText
        } else {
            textView.text = placeHolderText
            textView.textColor = .lightGray
        }

        textView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: vSpacing),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hSpacing),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hSpacing),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -vSpacing),
        ])
    }

    func getText() -> String {
        guard textView.text != placeHolderText else {
            return ""
        }
        return textView.text
    }
}

// MARK: - UITextViewDelegate for Placeholder

extension ASCTextViewTableViewCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeHolderText, textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .label
        }
        textView.becomeFirstResponder()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = placeHolderText
            textView.textColor = .lightGray
        }
        textView.resignFirstResponder()
    }
}
