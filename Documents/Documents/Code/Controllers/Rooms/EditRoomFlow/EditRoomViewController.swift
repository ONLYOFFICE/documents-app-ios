//
//  EditRoomViewController.swift
//  Documents
//
//  Created by Victor Tihovodov on 10.01.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

class EditRoomViewController: UIHostingController<EditRoomWrapperView> {
    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(
            coder: aDecoder
        )
    }

    init(folder: ASCFolder, onAction: @escaping (ASCFolder) -> Void) {
        super.init(
            rootView: EditRoomWrapperView(folder: folder) { value in
                UIApplication.topViewController()?.dismiss(animated: true)
                onAction(value)
            }
        )
    }
}

struct EditRoomWrapperView: View {
    @State var folder: ASCFolder
    @State var onAction: (ASCFolder) -> Void

    var body: some View {
        NavigationView {
            ManageRoomView(
                viewModel: ManageRoomViewModel(
                    editingRoom: folder,
                    selectedRoomType: folder.roomTypeModel,
                    onCreate: onAction
                )
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
