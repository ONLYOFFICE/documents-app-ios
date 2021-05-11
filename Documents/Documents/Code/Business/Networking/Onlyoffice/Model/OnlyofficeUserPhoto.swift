//
//  OnlyofficeUserPhoto.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class OnlyofficeUserPhoto: Mappable {
    var big: String?
    var max: String?
    var medium: String?
    var original: String?
    var retina: String?
    var small: String?
    
    
    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        big         <- map["big"]
        max         <- map["max"]
        medium      <- map["medium"]
        original    <- map["original"]
        retina      <- map["retina"]
        small       <- map["small"]
    }
}

//big: "/storage/userPhotos/root/28db9c8d-ec03-4d83-b16a-2b5171642f00_size_82-82.png"
//max: "/storage/userPhotos/root/28db9c8d-ec03-4d83-b16a-2b5171642f00_size_200-200.png"
//medium: "/storage/userPhotos/root/28db9c8d-ec03-4d83-b16a-2b5171642f00_size_48-48.png"
//original: "/storage/userPhotos/root/28db9c8d-ec03-4d83-b16a-2b5171642f00_orig_200-200.png"
//retina: "/storage/userPhotos/root/28db9c8d-ec03-4d83-b16a-2b5171642f00_size_360-360.png"
//small: "/stora
