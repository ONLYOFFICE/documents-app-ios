//
//  ManagedAppConfig.swift
//  Documents
//
//  Created by Alexander Yuzhin on 28.09.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ManagedAppConfigHook: AnyObject {
    func onApp(config: [String: Any?])
}

final class ManagedAppConfig {
    public static let shared = ManagedAppConfig()

    // MARK: - Properties

    private var appConfigHooks: [() -> ManagedAppConfigHook?] = []
    private let provider = UserDefaults.standard
    private var observer: NSKeyValueObservation?

    var appConfigAll: [String: Any]? {
        provider.managedAppConfig
    }

    // MARK: - Lifecycle Methods

    init() {
        subscribeNotification()
    }

    private func subscribeNotification() {
        unsubscribeNotification()

        observer = provider.observe(\.managedAppConfig, options: [.initial, .old, .new], changeHandler: { [weak self] defaults, change in
            guard !Device.current.isSimulator else { return }
            self?.triggerHooks()
        })
    }

    private func unsubscribeNotification() {
        observer?.invalidate()
    }

    deinit {
        unsubscribeNotification()
    }

    @objc
    private func didChangeUserDefaults() {
        triggerHooks()
    }

    /// Force call hooks
    func triggerHooks() {
        if let configuration = provider.dictionary(forKey: configurationKey) {
            appConfigHooks.forEach { $0()?.onApp(config: configuration) }
        }
    }

    /// Add observer of notification from MDM Server
    /// - Parameter observer: Observer of notification from MDM Server
    func add(observer: ManagedAppConfigHook?) {
        appConfigHooks.append { [weak observer] in observer }
    }

    /// The configuration value from the MDM server to an app.
    /// - Returns: Key of configuration value from the MDM server
    func appConfig<T>(_ key: String) -> T? {
        appConfigAll?[key] as? T
    }

    /// Rewrite configuration value from the MDM server to an app.
    /// - Returns: Key of configuration value from the MDM server
    func setAppConfig(_ dictionary: [String: Any]?) {
        provider.managedAppConfig = dictionary
    }

    /// Set feedback information that can be queried over MDM.
    /// - Parameter dictionary: New values for this feedback dictionary
    func setFeedback(_ dictionary: [String: Any]?) {
        provider.managedFeedbackConfig = dictionary
    }
}

private let configurationKey = "com.apple.configuration.managed"
private let feedbackKey = "com.apple.feedback.managed"

private extension UserDefaults {
    @objc dynamic var managedAppConfig: [String: Any]? {
        get { dictionary(forKey: configurationKey) }
        set { set(newValue, forKey: configurationKey) }
    }

    @objc dynamic var managedFeedbackConfig: [String: Any]? {
        get { dictionary(forKey: feedbackKey) }
        set { set(newValue, forKey: feedbackKey) }
    }
}
