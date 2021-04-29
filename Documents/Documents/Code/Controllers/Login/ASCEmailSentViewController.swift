//
//  ASCEmailSentViewController.swift
//  Documents
//
//  Created by Иван Гришечко on 28.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCEmailSentViewController: UIViewController {

    @IBOutlet weak var textLable: UILabel!
    @IBOutlet weak var backToLogin: UIButton!
    
    var email: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setText()
        navigationController?.navigationBar.isHidden = true
    }
    
    private func attributedText(withString string: String, boldString: String, font: UIFont) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string,
                                                     attributes: [NSAttributedString.Key.font: font])
        let boldFontAttribute: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: font.pointSize)]
        let range = (string as NSString).range(of: boldString)
        attributedString.addAttributes(boldFontAttribute, range: range)
        return attributedString
    }
    
    private func setText() {
        guard let email = email else { return }
        let localizedText = NSLocalizedString("Если пользователь с почтой %@ существует, то на этот адрес была отправлена инструкция по смене пароля", comment: "Email sent instructions")
        textLable.attributedText = self.attributedText(withString: String(format: localizedText, email), boldString: email, font: textLable.font)
    }
    
    @IBAction func backToLogin(_ sender: Any) {
        guard let signInVC = navigationController?.viewControllers[2] else { return }
        navigationController?.popToViewController(signInVC, animated: true)
    }
}
