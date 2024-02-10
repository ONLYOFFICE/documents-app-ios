//
//  CreateRoomRouteView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 04.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct CreateRoomRouteView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var selectedRoomType: RoomTypeModel?
    @State var roomName: String
    let hideActivityOnSuccess: Bool
    var onCreate: (ASCFolder) -> Void

    var body: some View {
        NavigationView {
            RoomSelectionView(selectedRoomType: $selectedRoomType)
                .navigation(item: $selectedRoomType) { type in
                    ManageRoomView(
                        viewModel: ManageRoomViewModel(
                            selectedRoomType: type,
                            roomName: roomName,
                            hideActivityOnSuccess: hideActivityOnSuccess
                        ) { room in
                            presentationMode.wrappedValue.dismiss()
                            onCreate(room)
                        }
                    )
                }
        }
    }
}

#Preview {
    CreateRoomRouteView(roomName: "", hideActivityOnSuccess: true) { _ in }
}
