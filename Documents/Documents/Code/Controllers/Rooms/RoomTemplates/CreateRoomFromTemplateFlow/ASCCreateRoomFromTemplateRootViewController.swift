//
//  ASCCreateRoomFromTemplateRootViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

class ASCCreateRoomFromTemplateRootViewController: UIHostingController<ASCCreateRoomFromTemplateRootView> {
    init(template: ASCFolder, onCreate: @escaping (ASCFolder) -> Void) {
        let rootView = ASCCreateRoomFromTemplateRootView(
            template: template,
            onCreate: onCreate
        )
        super.init(
            rootView: rootView
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ASCCreateRoomFromTemplateRootView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var template: ASCFolder
    @State var onCreate: (ASCFolder) -> Void

    var body: some View {
        NavigationView {
            ManageRoomView(viewModel: ManageRoomViewModel(
                screenMode: .createFromTemplate(template),
                selectedRoomType: template.roomTypeModel,
                onCreate: {
                    presentationMode.wrappedValue.dismiss()
                    onCreate($0)
                }
            )
            )
        }
    }
}

private extension ASCFolder {
    var roomTypeModel: RoomTypeModel {
        switch roomType {
        case .colobaration:
            return RoomTypeModel.make(fromRoomType: .collaboration, isRoomTemplate: true)
        case .custom:
            return RoomTypeModel.make(fromRoomType: .custom, isRoomTemplate: true)
        case .public:
            return RoomTypeModel.make(fromRoomType: .publicRoom, isRoomTemplate: true)
        case .fillingForm:
            return RoomTypeModel.make(fromRoomType: .formFilling, isRoomTemplate: true)
        case .virtualData:
            return RoomTypeModel.make(fromRoomType: .virtualData, isRoomTemplate: true)
        default:
            return RoomTypeModel.make(fromRoomType: .collaboration, isRoomTemplate: true)
        }
    }
}
