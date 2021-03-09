//
//  UILabel+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11.01.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UILabel {
    
    func addTrailing(image: UIImage) {
        let attachment = NSTextAttachment()
        attachment.image = image

        let attachmentString = NSAttributedString(attachment: attachment)
        let string: NSMutableAttributedString
        
        if let attributedText = self.attributedText {
            string = attributedText.mutableCopy() as! NSMutableAttributedString
        } else {
            string = NSMutableAttributedString(string: self.text ?? "", attributes: [:])
        }

        string.append(NSAttributedString(string: " "))
        string.append(attachmentString)
        self.attributedText = string
    }
    
    func addLeading(image: UIImage) {
        let attachment = NSTextAttachment()
        attachment.image = image

        let attachmentString = NSAttributedString(attachment: attachment)
        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(attachmentString)
        
        let string: NSMutableAttributedString
        
        if let attributedText = self.attributedText {
            string = attributedText.mutableCopy() as! NSMutableAttributedString
        } else {
            string = NSMutableAttributedString(string: self.text ?? "", attributes: [:])
        }
        
        mutableAttributedString.append(NSAttributedString(string: " "))
        mutableAttributedString.append(string)
        self.attributedText = mutableAttributedString
    }

}
