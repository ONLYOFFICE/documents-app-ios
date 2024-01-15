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
    var onCreate: (ASCFolder) -> Void

    var body: some View {
        NavigationView {
            RoomSelectionView(selectedRoomType: $selectedRoomType)
                .navigation(item: $selectedRoomType) { type in
                    CreateRoomView(
                        viewModel: CreateRoomViewModel(selectedRoomType: type) { room in
                            presentationMode.wrappedValue.dismiss()
                            onCreate(room)
                        }
                    )
                }
        }
    }
}

#Preview {
    CreateRoomRouteView { _ in }
}
