//
//  ASCIndexTransform.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/22/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import ObjectMapper

class ASCIndexTransform: TransformType {
    public typealias Object = String
    public typealias JSON = String
    
    public init() {}
    
    open func transformFromJSON(_ value: Any?) -> String? {
        if let indexInt = value as? Int {
            return String(indexInt)
        }
    
        if let indexStr = value as? String {
            return indexStr
        }
    
        return nil
    }
    
    open func transformToJSON(_ value: String?) -> String? {
        return value
    }
}
