//
//  MBProgressHUD+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/31/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD

extension MBProgressHUD {
    weak static var currentHUD: MBProgressHUD?

    enum Result {
        case success(String?), failure(String?)
    }

    static func showTopMost() -> MBProgressHUD? {
        if let topView = UIWindow.keyWindow?.rootViewController?.view {
            let hud = MBProgressHUD.showAdded(to: topView, animated: true)
            hud.minSize = CGSize(width: 100, height: 100)
            UIWindow.keyWindow?.addSubview(hud)
            MBProgressHUD.currentHUD = hud
            return hud
        }
        return nil
    }
    
    static func showTopMost(mode: MBProgressHUDMode, hideCurrent: Bool = true) {
        if hideCurrent {
            currentHUD?.hide(animated: false)
        }
        let hud = showTopMost()
        hud?.mode = mode
    }

    func setSuccessState(title: String? = nil) {
        mode = .customView
        customView = UIImageView(image: Asset.Images.hudCheckmark.image)
        label.text = title ?? NSLocalizedString("Done", comment: "Operation completed")
    }

    func setState(result: Result) {
        mode = .customView

        label.numberOfLines = 0

        switch result {
        case let .success(title):
            customView = UIImageView(image: Asset.Images.hudCheckmark.image)
            label.text = title ?? NSLocalizedString("Done", comment: "Operation completed")
        case let .failure(title):
            customView = UIImageView(image: Asset.Images.hudCross.image)
            label.text = title ?? ASCLocalization.Common.error
        }
    }
}
