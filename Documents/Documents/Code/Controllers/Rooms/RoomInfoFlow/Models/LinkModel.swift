//
//  LinkModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 19.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

extension Rooms {
    struct LinkModel: Identifiable, Hashable {
        let title: String
        let imagesNames: [String]
        var id = UUID()
    }
}
