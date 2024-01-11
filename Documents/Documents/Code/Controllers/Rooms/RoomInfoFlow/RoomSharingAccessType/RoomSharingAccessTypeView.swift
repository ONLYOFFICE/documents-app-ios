//
//  RoomSharingAccessTypeView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28/12/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import SwiftUI

struct RoomSharingAccessTypeView: View {
    @ObservedObject var viewModel: RoomSharingAccessTypeViewModel

    var body: some View {
        handleHUD()

        return List {
            Section {
                ForEach(viewModel.accessModels) { model in
                    RoomSharingAccessRowView(model: model)
                }
            }
        }
        .disabled(viewModel.isAccessChanging)
        .navigationBarTitle(Text("Access type"))
        .alert(item: $viewModel.error) { errorMessage in
            Alert(
                title: Text(NSLocalizedString("Error", comment: "")),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"), action: {
                    viewModel.error = nil
                })
            )
        }
    }

    private func handleHUD() {
        if viewModel.isAccessChanging {
            MBProgressHUD.currentHUD?.hide(animated: false)
            let hud = MBProgressHUD.showTopMost()
            hud?.mode = .indeterminate
            hud?.label.text = NSLocalizedString("Changing access", comment: "")
        } else {
            if let hud = MBProgressHUD.currentHUD {
                if (viewModel.error ?? "").isEmpty {
                    hud.setState(result: .success(nil))
                    hud.hide(animated: true, afterDelay: 1.3)
                } else {
                    hud.hide(animated: true)
                }
            }
        }
    }
}

struct ASCShareAccessRowModel: Identifiable {
    var id = UUID().uuidString
    var uiImage: UIImage?
    var name: String
    var isChecked: Bool
    var onTap: () -> Void
}

struct RoomSharingAccessRowView: View {
    var model: ASCShareAccessRowModel

    var body: some View {
        HStack {
            if let image = model.uiImage {
                Image(uiImage: image)
                    .frame(width: 20, height: 20).foregroundColor(.gray)
                    .padding(.trailing, 8)
            }
            Text(model.name)
            Spacer()
            if model.isChecked {
                Image(systemName: "checkmark")
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.onTap()
        }
    }
}

#Preview {
    RoomSharingAccessTypeView(viewModel: RoomSharingAccessTypeViewModel(room: .init(), user: .init()))
}
