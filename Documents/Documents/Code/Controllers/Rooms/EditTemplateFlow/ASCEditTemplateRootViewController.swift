//
//  ASCEditTemplateRootViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 27.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

class ASCEditTemplateRootViewController: UIHostingController<ASCEditTemplateRootView> {
    init(template: ASCFolder, onSave: @escaping (ASCFolder) -> Void) {
        super.init(rootView: ASCEditTemplateRootView(template: template) { template in
            UIApplication.topViewController()?.dismiss(animated: true)
            onSave(template)
        })
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ASCEditTemplateRootView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var template: ASCRoom
    @State var onSave: (ASCRoom) -> Void
    
    var body: some View {
        NavigationView {
            ManageRoomView(viewModel: ManageRoomViewModel(screenMode: .edit(template), selectedRoomType: template.roomTypeModel, onCreate: onSave))
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
