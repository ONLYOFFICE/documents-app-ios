//
//  ManagedAppConfigTest.swift
//  DocumentsTests
//
//  Created by Alexander Yuzhin on 28.09.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

@testable import Documents
import XCTest

class ManagedAppConfigTest: XCTestCase {
    class AppConfigHandlerMock: ManagedAppConfigHook {
        var value: [String: Any]?

        func onApp(config: [String: Any?]) {
            value = config as [String: Any]
        }
    }

    let manager = ManagedAppConfig.shared

    let configurationKey = "com.apple.configuration.managed"
    let feedbackKey = "com.apple.feedback.managed"

    let sampleConfig1 = [
        "address": "https://webdav.example.com",
        "login": "user1",
        "password": "password1",
        "type": "ASCFileProviderTypeWebDAV",
    ]

    let sampleConfig2 = [
        "address": "https://webdav.example.com",
        "login": "user2",
        "password": "password2",
        "type": "ASCFileProviderTypeWebDAV",
    ]

    var handler1: AppConfigHandlerMock?
    var handler2: AppConfigHandlerMock?

    override func setUpWithError() throws {
        handler1 = AppConfigHandlerMock()
        handler2 = AppConfigHandlerMock()

        UserDefaults.standard.set(sampleConfig1, forKey: configurationKey)
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: configurationKey)
        UserDefaults.standard.removeObject(forKey: feedbackKey)
    }

    func testReadConfig() throws {
        XCTAssertNotNil(manager.appConfigAll)
    }

    func testReadProvider() throws {
        let type: String? = manager.appConfig("type")
        let address: String? = manager.appConfig("address")
        let login: String? = manager.appConfig("login")
        let password: String? = manager.appConfig("password")

        XCTAssertNotNil(type)
        XCTAssertNotNil(address)
        XCTAssertNotNil(login)
        XCTAssertNotNil(password)
    }

    func testObservers() throws {
        manager.add(observer: handler1)
        manager.add(observer: handler2)

        UserDefaults.standard.set(sampleConfig2, forKey: configurationKey)
        ManagedAppConfig.shared.triggerHooks()

        var value1 = handler1?.value
        var value2 = handler2?.value

        XCTAssertNotNil(value1)
        XCTAssertNotNil(value2)

        XCTAssertTrue(NSDictionary(dictionary: value1!).isEqual(to: sampleConfig2))
        XCTAssertTrue(NSDictionary(dictionary: value2!).isEqual(to: sampleConfig2))

        handler2 = nil

        UserDefaults.standard.set(sampleConfig1, forKey: configurationKey)
        ManagedAppConfig.shared.triggerHooks()

        value1 = handler1?.value
        value2 = handler2?.value

        XCTAssertNotNil(value1)
        XCTAssertNil(value2)

        XCTAssertTrue(NSDictionary(dictionary: value1!).isEqual(to: sampleConfig1))
    }
}
