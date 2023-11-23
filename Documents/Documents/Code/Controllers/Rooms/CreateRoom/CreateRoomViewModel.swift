//
//  CreateRoomViewModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 23.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

class CreateRoomViewModel: ObservableObject {
    @Published var roomName: String = ""
    @Published var tags: String = ""

    func createRoom() {}
}
