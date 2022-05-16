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

    let newProvidersKey = "newProviders"
    let provider1 = [
        "address": "https://webdav.example.com",
        "login": "user1",
        "password": "password1",
        "type": "ASCFileProviderTypeWebDAV",
    ]

    let provider2 = [
        "address": "https://webdav.example.com",
        "login": "user2",
        "password": "password2",
        "type": "ASCFileProviderTypeWebDAV",
    ]

    var sampleConfig1: [String: Any] = [:]
    var sampleConfig2: [String: Any] = [:]

    var handler1: AppConfigHandlerMock?
    var handler2: AppConfigHandlerMock?

    override func setUpWithError() throws {
        sampleConfig1 = [
            newProvidersKey: [provider1],
        ]

        sampleConfig2 = [
            newProvidersKey: [provider2],
        ]

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
        let providers: [Any]? = manager.appConfig(newProvidersKey)
        XCTAssertNotNil(providers)

        let provider: [String: Any]? = providers?.first as? [String: Any]
        XCTAssertNotNil(provider)

        XCTAssertTrue(NSDictionary(dictionary: provider!).isEqual(to: provider1))
    }

    func testObservers() throws {
        manager.add(observer: handler1)
        manager.add(observer: handler2)

        UserDefaults.standard.set(sampleConfig2, forKey: configurationKey)

        var value1 = handler1?.value
        var value2 = handler2?.value

        XCTAssertNotNil(value1)
        XCTAssertNotNil(value2)

        XCTAssertTrue(NSDictionary(dictionary: value1!).isEqual(to: sampleConfig2))
        XCTAssertTrue(NSDictionary(dictionary: value2!).isEqual(to: sampleConfig2))

        handler2 = nil

        UserDefaults.standard.set(sampleConfig1, forKey: configurationKey)

        value1 = handler1?.value
        value2 = handler2?.value

        XCTAssertNotNil(value1)
        XCTAssertNil(value2)

        XCTAssertTrue(NSDictionary(dictionary: value1!).isEqual(to: sampleConfig1))
    }
}
