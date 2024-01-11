//
//  EditRoomRouteView.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 10.01.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

struct EditRoomRouteView: View {
    @Environment(\.presentationMode) var presentationMode

    var folder: ASCFolder
    var onEdited: (ASCFolder) -> Void

    var body: some View {
        NavigationView {
            EditRoomView(
                viewModel: EditRoomViewModel(folder: folder, onEdited: onEdited)
            )
        }
    }
}

#Preview {
    CreateRoomRouteView { _ in }
}
