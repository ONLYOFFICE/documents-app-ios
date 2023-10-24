//
//  ASCDIContainer.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.10.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

final class ASCDIContainer: ASCDIProtocol {
    static let shared = ASCDIContainer()

    // MARK: - Properties

    private var factories: [String: (Any...) -> Any?] = [:]

    // MARK: - Lifecycle Methods

    private init() {}

    func reset() {
        factories = [:]
    }

    // MARK: - Register

    func register<Service>(type: Service.Type, service: Any) {
        let key = String(describing: Service.self)
        factories[key] = { _ in service }
    }

    func register<Service>(_ type: Service.Type, _ factory: @escaping () -> Service) {
        let key = String(describing: Service.self)
        factories[key] = { _ in factory() }
    }

    func register<Service, A>(_ type: Service.Type, _ factory: @escaping (A) -> Service) {
        let key = String(describing: Service.self)
        factories[key] = { args in
            guard let arg1 = args[0] as? A else { return nil }
            return factory(arg1)
        }
    }

    func register<Service, A, B>(_ type: Service.Type, _ factory: @escaping (A, B) -> Service) {
        let key = String(describing: Service.self)
        factories[key] = { args in
            guard let arg1 = args[0] as? A, let arg2 = args[1] as? B else { return nil }
            return factory(arg1, arg2)
        }
    }

    func register<Service, A, B, C>(_ type: Service.Type, _ factory: @escaping (A, B, C) -> Service) {
        let key = String(describing: Service.self)
        factories[key] = { args in
            guard let arg1 = args[0] as? A, let arg2 = args[1] as? B, let arg3 = args[2] as? C else { return nil }
            return factory(arg1, arg2, arg3)
        }
    }

    // MARK: - Resolve

    func resolve<Service>(type: Service.Type) -> Service? {
        let key = String(describing: Service.self)
        return factories[key]?() as? Service
    }

    func resolve<Service>(_ type: Service.Type) -> Service? {
        return resolve(type: Service.self)
    }

    func resolve<Service>() -> Service? {
        return resolve(type: Service.self)
    }

    func resolve<Service, A>(_ type: Service.Type, _ arg1: A) -> Service? {
        let key = String(describing: Service.self)
        return factories[key]?(arg1) as? Service
    }

    func resolve<Service, A, B>(_ type: Service.Type, _ arg1: A, _ arg2: B) -> Service? {
        let key = String(describing: Service.self)
        return factories[key]?(arg1, arg2) as? Service
    }

    func resolve<Service, A, B, C>(_ type: Service.Type, _ arg1: A, _ arg2: B, _ arg3: C) -> Service? {
        let key = String(describing: Service.self)
        return factories[key]?(arg1, arg2, arg3) as? Service
    }
}
