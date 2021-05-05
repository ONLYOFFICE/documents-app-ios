//
//  ASCConverterOptionsAlert.swift
//  Documents
//
//  Created by Alexey Musinov on 06.06.2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import DocumentConverter

class ASCConverterOptionsAlert: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    fileprivate lazy var encodings = DocumentLocalConverter.encodingings()
    fileprivate lazy var delimiters = DocumentLocalConverter.delimiters()
    
    fileprivate var alert: UIAlertController? = nil
    
    let preferredContentSize = CGSize(width: 260, height: 240)
    
    public var isOnlyCodePages = false
    
    func show(_ handler: @escaping (_ encoding: Int, _ delimiter: Int) -> ()) {
        
        alert = UIAlertController(title: isOnlyCodePages ?
            NSLocalizedString("Choose Code Page", comment: "") :
            NSLocalizedString("Choose CSV Options", comment: ""),
                                  message: "",
                                  preferredStyle: .alert)
        
        let picker = UIPickerView(frame:
            isOnlyCodePages ?
                CGRect(x: 0, y: -50, width: preferredContentSize.width, height: preferredContentSize.height + 75):
                CGRect.init(origin: .zero, size: preferredContentSize))
        
        picker.dataSource = self
        picker.delegate = self
        picker.reloadAllComponents()
        
        let indexEncoding = encodings?.firstIndex(where: { $0.range(of: "UTF") != nil }) ?? 0
        picker.selectRow(indexEncoding, inComponent: 0, animated: false)
        
        let viewController = UIViewController()
        viewController.preferredContentSize = preferredContentSize
        viewController.view.addSubview(picker)
        
        if !isOnlyCodePages {
            let encodingLabel = UILabel.init(frame: CGRect.init(x: 15, y: -5,
                                                                width: preferredContentSize.width * 0.5,
                                                                height: 20))
            encodingLabel.text = NSLocalizedString("Encoding", comment: "")
            encodingLabel.font = UIFont.systemFont(ofSize: 15)
            encodingLabel.textAlignment = .left
            encodingLabel.textColor = .gray
            if #available(iOS 13.0, *) {
                encodingLabel.textColor = .secondaryLabel
            }
            viewController.view.addSubview(encodingLabel)
            
            let indexDelimiter = delimiters?.firstIndex(where: { $0.range(of: ",") != nil }) ?? 0
            picker.selectRow(indexDelimiter, inComponent: 1, animated: false)
            
            let delimiterLabel = UILabel.init(frame: CGRect.init(x: preferredContentSize.width * 0.5, y: -5,
                                                                 width: preferredContentSize.width * 0.5 - 15,
                                                                 height: 20))
            delimiterLabel.text = NSLocalizedString("Delimiter", comment: "")
            delimiterLabel.font = UIFont.systemFont(ofSize: 15)
            delimiterLabel.textAlignment = .right
            delimiterLabel.textColor = .gray
            if #available(iOS 13.0, *) {
                delimiterLabel.textColor = .secondaryLabel
            }
            
            viewController.view.addSubview(delimiterLabel)
        }
        
        alert?.isModalInPopover = true
        alert?.preferredContentSize = preferredContentSize
        alert?.setValue(viewController, forKey: "contentViewController")
        alert?.addAction(UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel, handler: nil))
        alert?.addAction(UIAlertAction(title: ASCLocalization.Common.ok, style: .default, handler: { action in
            handler(picker.selectedRow(inComponent: 0), self.isOnlyCodePages ? 0 : picker.selectedRow(inComponent: 1))
        }))

        if let topVC = ASCViewControllerManager.shared.topViewController, let alert = alert {
            topVC.present(alert, animated: true, completion: nil)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return isOnlyCodePages ? 1 : 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if 0 == component {
            return encodings?.count ?? 0
        } else {
            return delimiters?.count ?? 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if 0 == component {
            return encodings?[row] ?? ""
        } else {
            return delimiters?[row] ?? ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if 0 == component {
            return preferredContentSize.width * (isOnlyCodePages ? 1.0 : 0.8)
        } else {
            return preferredContentSize.width * 0.2
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 15)
        if #available(iOS 13.0, *) {
            label.textColor = .label
        }
        
        if 0 == component {
            label.textAlignment = .left
            label.text = encodings?[row] ?? ""
          
            if isOnlyCodePages {
                label.textAlignment = .center
            }
        } else {
            label.textAlignment = .center
            
            if let delimiter = delimiters?[row] {
                if delimiter == " " {
                    label.text = NSLocalizedString("Space", comment: "")
                } else if delimiter == "\t" {
                    label.text = NSLocalizedString("Tab", comment: "")
                } else {
                    label.text = delimiter
                }
            }
        }
        
        return label
    }
}
