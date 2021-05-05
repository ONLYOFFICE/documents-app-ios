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
    
    // MARK: - Private
    private var alertWindow: UIWindow? = nil
    private var actionController: UIAlertController? = nil
    private var progressView: UIProgressView? = nil
    
    // MARK: - Public Methods
    init(title: String?, message: String?, handler: @escaping (Bool) -> Void) {
        // Init alert view
        actionController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .default) { (action) in
            self.cleanupAlertWindow()
            handler(true)
        }
        actionController?.addAction(cancelAction)
        
        // Init progress view
        progress = 0.01
        
        actionController?.view.tintColor = Asset.Colors.brend.color

        progressView = UIProgressView(progressViewStyle: .bar)
        progressView?.translatesAutoresizingMaskIntoConstraints = false
        
        actionController?.view.addSubview(progressView!)
        
        actionController?.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-0-[progressView]-0-|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                metrics: nil,
                views: ["progressView": progressView!]
            )
        )
        actionController?.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:[progressView(1)]-45-|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                metrics: nil,
                views: ["progressView": progressView!]
            )
        )
        
    }
    
    func show(at viewController: UIViewController? = nil) {
        if let controller = viewController {
            controller.present(actionController!, animated: true, completion: nil)
        } else {
            alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow?.rootViewController = ASCBaseViewController()
            
            if let delegate = UIApplication.shared.delegate {
                alertWindow?.tintColor = delegate.window??.tintColor
            }
            
            if let topWindow = UIApplication.shared.keyWindow {
                alertWindow?.windowLevel = min(topWindow.windowLevel + 1, UIWindow.Level.statusBar - 10)
            }
            
            alertWindow?.makeKeyAndVisible()
            alertWindow?.rootViewController?.present(actionController!, animated: true, completion: nil)
        }
        
        progressView?.setProgress(progress, animated: true)
    }
    
    func hide(completion: (() -> Void)? = nil) {
        actionController?.dismiss(animated: true, completion: {
            self.cleanupAlertWindow()
            completion?()
        })
    }
    
    // MARK: - Private Methods
    
    private func updateProgress() {
        progressView?.setProgress(progress, animated: true)
    }
    
    private func cleanupAlertWindow() {
        alertWindow?.isHidden = true
        alertWindow?.removeFromSuperview()
        
        alertWindow = nil
    }

}
