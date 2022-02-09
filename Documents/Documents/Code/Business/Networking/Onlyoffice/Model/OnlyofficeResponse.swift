//
//  OnlyofficeResponse.swift
//  Documents
//
//  Created by Alexander Yuzhin on 04.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class OnlyofficeResponseBase: Mappable {
    var count: Int?
    var status: Int?
    var statusCode: Int?
    var error: OnlyofficeResponseError?

    required convenience init?(map: Map) {
        self.init()
    }

    func mapping(map: Map) {
        count       <- map["count"]
        status      <- map["status"]
        statusCode  <- map["statusCode"]
        error       <- map["error"]
    }
}

class OnlyofficeResponseError: Mappable {
    var message: String?
    var type: String?
    var stack: String?
    var hresult: Int?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        message  <- map["message"]
        type     <- map["type"]
        stack    <- map["stack"]
        hresult  <- map["hresult"]
    }
}


    
class OnlyofficeResponse<T: Mappable>: OnlyofficeResponseBase {

    var result: T?

    required convenience init?(map: Map) {
        self.init()
    }

    override func mapping(map: Map) {
        super.mapping(map: map)
        
        result <- map["response"]
    }
}

class OnlyofficeResponseType<T>: OnlyofficeResponseBase {

    var result: T?

    required convenience init?(map: Map) {
        self.init()
    }

    override func mapping(map: Map) {
        super.mapping(map: map)
        
        result <- map["response"]
    }
}


class OnlyofficeResponseArray<T: Mappable>: OnlyofficeResponseBase {
    
    var result: [T]?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        result <- map["response"]
    }
}

class OnlyofficeResponseArrayType<T>: OnlyofficeResponseBase {
    
    var result: [T]?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        result <- map["response"]
    }
}
