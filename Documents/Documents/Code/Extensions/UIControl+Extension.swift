//
//  UIControl+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/30/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

typealias UIControlClosureType = () -> Void

class UIControlClosure {
    let closure: UIControlClosureType

    init(_ closure: @escaping UIControlClosureType) {
        self.closure = closure
    }

    @objc func invoke() {
        closure()
    }
}

extension UIControl {
    func add(for controlEvents: UIControl.Event, _ closure: @escaping UIControlClosureType) {
        let sleeve = UIControlClosure(closure)
        addTarget(sleeve, action: #selector(UIControlClosure.invoke), for: controlEvents)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}
