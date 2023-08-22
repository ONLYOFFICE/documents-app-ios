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

    required convenience init?(map: Map) {
        self.init()
    }

    func mapping(map: Map) {
        count <- map["count"]
        status <- map["status"]
        statusCode <- map["statusCode"]
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

class OnlyofficeResponseCodable<T: Codable>: OnlyofficeResponseBase {
    var result: T?

    required convenience init?(map: Map) {
        self.init()
    }

    override func mapping(map: Map) {
        super.mapping(map: map)

        if let response = map["response"].currentValue,
           let data = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
        {
            result = try? JSONDecoder().decode(T.self, from: data)
        }
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
