//
//  CreateEntityViewModel.swift
//  Documents
//
//  Created by Alexander Yuzhin on 09.08.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct CreateEntityViewModel: Identifiable {
    let id = UUID()
    var type: CreateEntityUIType
    var caption: String
    var icon: Image
    var action: (CreateEntityUIType) -> Void
}
