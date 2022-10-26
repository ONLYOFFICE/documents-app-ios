//
//  ASCLinkTableViewHeaderFooterView.swift
//  Documents
//
//  Created by Alexander Yuzhin on 26.10.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCLinkTableViewHeaderFooterView: UITableViewHeaderFooterView {
    static let identifier = String(describing: ASCLinkTableViewHeaderFooterView.self)

    // MARK: - Properties

    lazy var textView: UITextView = {
        let textView = ASCFooterTextView(frame: .zero)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 0, left: -5, bottom: -10, right: -5)
        textView.backgroundColor = .clear
        textView.delegate = self
        return textView
    }()

    // MARK: - Lifecycle Methods

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(textView)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentView.addSubview(textView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let labelFrame = textLabel?.frame ?? CGRect.zero

        textView.frame = CGRect(
            origin: CGPoint(x: labelFrame.origin.x, y: 10),
            size: labelFrame.size
        )
    }
}

extension ASCLinkTableViewHeaderFooterView: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        textView.selectedTextRange = nil
    }
}

private class ASCFooterTextView: UITextView {
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // Prevent long press to show the magnifying glass
        if gestureRecognizer is UILongPressGestureRecognizer {
            gestureRecognizer.isEnabled = false
        }
        super.addGestureRecognizer(gestureRecognizer)
    }
}
