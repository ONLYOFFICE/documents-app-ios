//
//  ASCDebugConsoleViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.06.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCDebugConsoleViewController: ASCBaseViewController {
    // MARK: - Properties

    fileprivate let isAutoScrollingPropertyName = "asc.debug.console.autoscrolling"
    fileprivate var isAutoScrolling: Bool {
        get {
            return UserDefaults.standard.bool(forKey: isAutoScrollingPropertyName)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: isAutoScrollingPropertyName)
        }
    }

    @IBOutlet var outputTextView: UITextView!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

    fileprivate func initView() {
        guard let textView = outputTextView, let logUrl = ASCLogIntercepter.shared.logUrl else {
            return
        }

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                title: isAutoScrolling ? "Scroll: OFF" : "Scroll: ON",
                style: .plain,
                target: self,
                action: #selector(onAutoScrolling(_:))
            ),
            UIBarButtonItem(
                title: "Copy",
                style: .plain,
                target: self,
                action: #selector(onCopyLog(_:))
            ),
        ]

        do {
            textView.text = try String(contentsOf: logUrl)
            delay(seconds: 0.01) {
                if self.isAutoScrolling, textView.text.count > 0 {
                    textView.scrollRangeToVisible(NSMakeRange(textView.text.count - 1, 1))
                }
            }
        } catch {}
    }

    // MARK: - Actions

    @IBAction func onDone(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func onAutoScrolling(_ sender: UIBarButtonItem) {
        isAutoScrolling = !isAutoScrolling
        sender.title = isAutoScrolling ? "Scroll: OFF" : "Scroll: ON"
    }

    @IBAction func onCopyLog(_ sender: UIBarButtonItem) {
        guard let textView = outputTextView else { return }

        UIPasteboard.general.string = textView.text

        sender.title = "Coped"
        sender.isEnabled = false

        delay(seconds: 3) {
            sender.title = "Copy"
            sender.isEnabled = true
        }
    }
}

// MARK: - ASCLogInterceptorDelegate

extension ASCDebugConsoleViewController: ASCLogInterceptorDelegate {
    func log(message: String) {
        guard let textView = outputTextView else { return }

        DispatchQueue.main.async {
            let selectedRange = textView.selectedRange

            let newText = textView.text + message + "\n"
            textView.text = newText

            textView.selectedRange = selectedRange

            if self.isAutoScrolling, textView.text.count > 0 {
                textView.scrollRangeToVisible(NSMakeRange(textView.text.count - 1, 1))
            }
        }
    }
}
