//
//  ASCSaveAsTemplateRootViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 21.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

class ASCSaveAsTemplateRootViewController: UIHostingController<ASCSaveAsTemplateRootView> {
    init(room: ASCFolder, onSave: @escaping (ASCFolder) -> Void) {
        super.init(rootView: ASCSaveAsTemplateRootView(room: room, onCreate: onSave))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(
            coder: aDecoder
        )
    }
}

struct ASCSaveAsTemplateRootView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var room: ASCFolder
    @State var onCreate: (ASCFolder) -> Void
    
    var body: some View {
        NavigationView {
            ManageRoomView(viewModel: ManageRoomViewModel(
                screenMode: .saveAsTemplate(room),
                selectedRoomType: room.roomTypeModel,
                onCreate: onCreate)
            )
        }
    }
}

private extension ASCFolder {
    var roomTypeModel: RoomTypeModel {
        switch roomType {
        case .colobaration:
            return RoomTypeModel.make(fromRoomType: .collaboration)
        case .custom:
            return RoomTypeModel.make(fromRoomType: .custom)
        case .public:
            return RoomTypeModel.make(fromRoomType: .publicRoom)
        case .fillingForm:
            return RoomTypeModel.make(fromRoomType: .formFilling)
        case .virtualData:
            return RoomTypeModel.make(fromRoomType: .virtualData)
        default:
            return RoomTypeModel.make(fromRoomType: .collaboration)
        }
    }
}
