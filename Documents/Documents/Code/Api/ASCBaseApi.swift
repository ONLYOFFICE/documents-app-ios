//
//  ASCBaseApi.swift
//  Documents
//
//  Created by Alexander Yuzhin on 17/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire

typealias NetworkCompletionHandler = (_ result: Any?, _ error: Error?) -> Void

typealias ASCApiCompletionHandler = (_ result: Any?, _ error: Error?, _ response: Any?) -> Void
typealias ASCApiProgressHandler = (_ progress: Double, _ result: Any?, _ error: Error?, _ response: Any?) -> Void

class ASCBaseApi {
    static public func clearCookies(for url: URL?) {
        let cookieStorage = HTTPCookieStorage.shared

        if let url = url, let cookies = cookieStorage.cookies(for: url) {
            for cookie in cookies {
                cookieStorage.deleteCookie(cookie)
            }
        }
    }
}

class ASCServerTrustPolicyManager: ServerTrustManager {

    override func serverTrustEvaluator(forHost host: String) throws -> ServerTrustEvaluating? {
        return DisabledTrustEvaluator()
    }

}
