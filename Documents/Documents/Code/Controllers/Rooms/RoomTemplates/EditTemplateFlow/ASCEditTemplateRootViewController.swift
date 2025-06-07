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

    @available(*, unavailable)
    @MainActor @preconcurrency dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ASCEditTemplateRootView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var template: ASCRoom
    @State var onSave: (ASCRoom) -> Void

    var body: some View {
        NavigationView {
            ManageRoomView(viewModel: ManageRoomViewModel(screenMode: .editTemplate(template), selectedRoomType: template.roomTypeModel, onCreate: onSave))
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
