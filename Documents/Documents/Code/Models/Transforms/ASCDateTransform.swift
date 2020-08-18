//
//  ASCDateTransform.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/22/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import ObjectMapper

class ASCDateTransform: TransformType {
    public typealias Object = Date
    public typealias JSON = String
    
    public init() {}
    
    open func transformFromJSON(_ value: Any?) -> Date? {
        if let timeInt = value as? Double {
            return Date(timeIntervalSince1970: TimeInterval(timeInt))
        }
    
        if let timeStr = value as? String {
            return timeStr.dateFromISO8601
        }
    
        return nil
    }
    
    open func transformToJSON(_ value: Date?) -> String? {
        if let date = value {
            return date.iso8601
        }
        
        return nil
    }
}
