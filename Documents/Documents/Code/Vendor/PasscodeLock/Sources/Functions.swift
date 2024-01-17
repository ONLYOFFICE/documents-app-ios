//
//  Functions.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

#if os(iOS)

import Foundation

func localizedStringFor(_ key: String, comment: String) -> String {
    let name = "PasscodeLock"
    let bundle = bundleForResource(name, ofType: "strings")

    return NSLocalizedString(key, tableName: name, bundle: bundle, comment: comment)
}

func bundleForResource(_ name: String, ofType type: String) -> Bundle {
    #if SWIFT_PACKAGE
        return Bundle.module
    #else
        if Bundle.main.path(forResource: name, ofType: type) != nil {
            return Bundle.main
        }

        return Bundle(for: PasscodeLock.self)
    #endif
}

#endif
