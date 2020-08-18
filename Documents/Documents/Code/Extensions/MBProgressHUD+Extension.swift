//
//  MBProgressHUD+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/31/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD

extension MBProgressHUD {

    static weak var currentHUD: MBProgressHUD? = nil

    static func showTopMost() -> MBProgressHUD? {
        if let topView = UIApplication.shared.keyWindow?.rootViewController?.view {
            let hud = MBProgressHUD.showAdded(to: topView, animated: true)
            hud.minSize = CGSize(width: 100, height: 100)
            UIApplication.shared.keyWindow?.addSubview(hud)
            MBProgressHUD.currentHUD = hud
            return hud
        }
        return nil
    }
    
    func setSuccessState(title: String? = nil) {
        if let hudImage = UIImage(named: "hud-checkmark") {
            mode = .customView
            customView = UIImageView(image: hudImage)
            label.text = title ?? NSLocalizedString("Done", comment: "Operation completed")
        }
    }
}
