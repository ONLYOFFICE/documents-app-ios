//
//  UIBarButtonItem+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 06/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

/// Typealias for UIBarButtonItem closure.
typealias UIBarButtonItemTargetClosure = () -> ()

class UIBarButtonItemClosure {
    let closure: UIBarButtonItemTargetClosure

    init (_ closure: @escaping UIBarButtonItemTargetClosure) {
        self.closure = closure
    }

    @objc func invoke () {
        closure()
    }
}

extension UIBarButtonItem {

    convenience init(title: String?, style: UIBarButtonItem.Style, closure: @escaping UIBarButtonItemTargetClosure) {
        self.init(title: title, style: style, target: nil, action: nil)
        let sleeve = UIBarButtonItemClosure(closure)
        target = sleeve
        action = #selector(UIBarButtonItemClosure.invoke)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }

    convenience init(barButtonSystemItem: UIBarButtonItem.SystemItem, closure: @escaping UIBarButtonItemTargetClosure) {
        self.init(barButtonSystemItem: barButtonSystemItem, target: nil, action: nil)
        let sleeve = UIBarButtonItemClosure(closure)
        target = sleeve
        action = #selector(UIBarButtonItemClosure.invoke)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}
