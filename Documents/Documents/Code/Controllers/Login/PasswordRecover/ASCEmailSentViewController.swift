//
//  ASCEmailSentViewController.swift
//  Documents
//
//  Created by Иван Гришечко on 28.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCEmailSentViewController: ASCBaseViewController {
    override class var storyboard: Storyboard { return Storyboard.login }

    // MARK: - Outlets

    @IBOutlet var textLable: UILabel!
    @IBOutlet var backToLogin: ASCButtonStyle!

    // MARK: - Properties

    var email: String?

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        backToLogin?.styleType = .default
        setText()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setText() {
        guard let email = email else { return }

        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: ASCTextStyle.subheadlineBold.font,
        ]

        let attributedString = NSAttributedString(string: String(format: NSLocalizedString("If a user with the mail %@ exists, then an instruction to change the password was sent to this address.", comment: "Email sent instructions"), email))
            .applying(attributes: boldAttributes, toRangesMatching: email)

        textLable?.attributedText = attributedString
    }

    // MARK: - Actions

    @IBAction func backToLogin(_ sender: Any) {
        popControllers(2)
    }
}
