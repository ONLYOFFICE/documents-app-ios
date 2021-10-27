//
//  ASCAnalytics.swift
//  Documents
//
//  Created by Alexander Yuzhin on 20.11.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAnalytics

final class ASCAnalytics {
    
    class func logEvent(_ event: String, parameters: [String : Any]? = nil) {
        if ASCConstants.Analytics.allow {
            Analytics.logEvent(event, parameters: parameters)
        }
    }
    
    struct Event {
        
        struct Key {
            static let portal = "portal"
            static let email = "email"
            static let onDevice = "onDevice"
            static let type = "type"
            static let fileExt = "fileExt"
            static let locallyEditing = "locallyEditing"
            static let viewMode = "viewMode"
            static let provider = "provider"
        }
        
        struct Value {
            static let none = "none"
            static let file = "file"
            static let folder = "folder"
            static let document = "document"
            static let spreadsheet = "spreadsheet"
            static let presentation = "presentation"
            static let unknown = "unknown"
        }
        
    }
}
