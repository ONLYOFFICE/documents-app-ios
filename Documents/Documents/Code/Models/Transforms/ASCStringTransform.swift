//
//  ASCStringTransform.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/16/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import ObjectMapper

class ASCStringTransform: TransformType {
    public typealias Object = String
    public typealias JSON = String
    
    public init() {}
    
    open func transformFromJSON(_ value: Any?) -> String? {
        if let string = value as? String {
            return string.removingHTMLEntities
        }        
        return nil
    }
    
    open func transformToJSON(_ value: String?) -> String? {
        return value
    }
}
