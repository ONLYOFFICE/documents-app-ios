//
//  RoomSharingViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 19.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// needed info for presentation:
// 1. public or custom
// 2. does general link exist
// 3. additional links count

final class RoomSharingViewModel: ObservableObject {
    // MARK: - Published vars

    @Published var room: ASCFolder
    @Published var admins: [ASCUser] = []
    @Published var users: [ASCUser] = []

    // MARK: - Init
    
    init(room: ASCFolder) {
        self.room = room
    }
    
    func onTap() {
        
    }
    
    func shareButtonAction() {
        
    }
    
    func createAddLinkAction() {
        
    }

}
