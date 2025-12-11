//
//  ASCProgressAlert.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/23/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCProgressAlert {
    // MARK: - Public

    var progress: Float = 0 {
        didSet {
            updateProgress()
        }
    }

    var isProgressAnimated: Bool = false

    // MARK: - Private

    private var alertWindow: UIWindow?
    private var actionController: UIAlertController?
    private var progressView: UIProgressView?
    private var isiOS26: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }

    // MARK: - Public Methods

    init(title: String?, message: String?, handler: @escaping (Bool) -> Void) {
        // Init alert view
        actionController = UIAlertController(
            title: title,
            message: "\(message ?? "")\n",
            preferredStyle: .alert
        )

        progressView = UIProgressView()
        progress = isProgressAnimated ? 0.01 : 0.0

        guard let actionController, let progressView else { return }

        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .default) { action in
            self.cleanupAlertWindow()
            handler(true)
        }
        actionController.addAction(cancelAction)

        actionController.view.tintColor = Asset.Colors.brend.color
        actionController.view.addSubview(progressView)

        let padding: CGFloat = isiOS26 ? 30 : 15
        var groupHeaderScrollViewBottomAnchor: NSLayoutYAxisAnchor?

        if let contentView = actionController.view.allSubviews().first(where: {
            String(describing: type(of: $0)).contains("GroupHeaderScrollView")
        }) {
            groupHeaderScrollViewBottomAnchor = contentView.bottomConstraint?.firstAnchor as? NSLayoutYAxisAnchor
        }

        if let groupHeaderScrollViewBottomAnchor {
            progressView.anchor(
                leading: actionController.view.leadingAnchor,
                bottom: groupHeaderScrollViewBottomAnchor,
                trailing: actionController.view.trailingAnchor,
                padding: .init(top: 0, left: padding, bottom: isiOS26 ? 8 : 20, right: padding)
            )
        }
    }

    func show(at viewController: UIViewController? = nil) {
        if let controller = viewController {
            controller.present(actionController!, animated: true, completion: nil)
        } else {
            guard let windowScene = UIApplication.shared.firstForegroundScene else {
                return
            }
            alertWindow = UIWindow(windowScene: windowScene)
            alertWindow?.overrideUserInterfaceStyle = AppThemeService.theme.overrideUserInterfaceStyle
            alertWindow?.rootViewController = ASCBaseViewController()

            if let keyWindow = UIApplication.shared.keyWindow {
                alertWindow?.tintColor = keyWindow.tintColor
                alertWindow?.windowLevel = min(keyWindow.windowLevel + 1, UIWindow.Level.statusBar - 10)
            }

            alertWindow?.makeKeyAndVisible()
            alertWindow?.rootViewController?.present(actionController!, animated: true, completion: nil)
        }

        progressView?.setProgress(progress, animated: isProgressAnimated)
    }

    func hide(completion: (() -> Void)? = nil) {
        actionController?.dismiss(animated: true, completion: {
            self.cleanupAlertWindow()
            completion?()
        })
    }

    // MARK: - Private Methods

    private func updateProgress() {
        progressView?.setProgress(progress, animated: isProgressAnimated)
    }

    private func cleanupAlertWindow() {
        alertWindow?.isHidden = true
        alertWindow?.removeFromSuperview()
        alertWindow = nil
    }
}

private extension UIView {
    func allSubviews() -> [UIView] {
        var result = subviews.compactMap { $0 }
        for sub in subviews {
            result.append(contentsOf: sub.allSubviews())
        }
        return result
    }
}

// @available(iOS 17, *)
// #Preview {
//    NavigationStack {
//        List {
//            Button("Show Alert") {
//                //
//            }
//        }
//    }
//    .navigationTitle("Progress Alert")
// }
