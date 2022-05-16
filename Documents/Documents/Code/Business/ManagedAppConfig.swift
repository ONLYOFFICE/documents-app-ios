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

    private let configurationKey = "com.apple.configuration.managed"
    private let feedbackKey = "com.apple.feedback.managed"

    private var appConfigHooks: [() -> ManagedAppConfigHook?] = []
    private var provider = UserDefaults.standard

    lazy var appConfigAll: [String: Any] = {
        provider.dictionary(forKey: configurationKey) ?? [:]
    }()

    // MARK: - Lifecycle Methods

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didChangeUserDefaults),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    @objc
    private func didChangeUserDefaults() {
        triggerHooks()
    }

    /// Force call hooks
    func triggerHooks() {
        if let configuration = UserDefaults.standard.dictionary(forKey: configurationKey) {
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
        return appConfigAll[key] as? T
    }

    /// Rewrite configuration value from the MDM server to an app.
    /// - Returns: Key of configuration value from the MDM server
    func setAppConfig(_ dictionary: [String: Any]?) {
        guard let dictionary = dictionary else {
            provider.removeObject(forKey: configurationKey)
            return
        }
        provider.set(dictionary, forKey: configurationKey)
    }

    /// Set feedback information that can be queried over MDM.
    /// - Parameter dictionary: New values for this feedback dictionary
    func setFeedback(_ dictionary: [String: Any]?) {
        guard let dictionary = dictionary else {
            provider.removeObject(forKey: feedbackKey)
            return
        }
        provider.set(dictionary, forKey: feedbackKey)
    }
}
