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
            rolesSection
            deleteSection
        }
        .disabled(viewModel.isAccessChanging)
        .navigationBarTitle(Text("Access type"))
        .alert(item: $viewModel.error) { errorMessage in
            Alert(
                title: Text(verbatim: ASCLocalization.Common.error),
                message: Text(verbatim: errorMessage),
                dismissButton: .default(Text(verbatim: ASCLocalization.Common.ok), action: {
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
                    hud.hide(animated: true, afterDelay: .standardDelay)
                } else {
                    hud.hide(animated: true)
                }
            }
        }
    }

    @ViewBuilder
    private var rolesSection: some View {
        Section(
            header: Text("Roles"),
            footer: Text("Unauthorized members will be able only to view the document.")
        ) {
            ForEach(viewModel.accessModels) { model in
                RoomSharingAccessRowView(model: model)
            }
        }
    }

    @ViewBuilder
    private var deleteSection: some View {
        Section {
            ASCLabledCellView(
                model: ASCLabledCellModel(
                    textString: NSLocalizedString("Remove", comment: ""),
                    cellType: .deletable,
                    textAlignment: .leading,
                    onTapAction: {
                        viewModel.removeUser()
                    }
                )
            )
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
            Text(verbatim: model.name)
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
    RoomSharingAccessTypeView(viewModel: RoomSharingAccessTypeViewModel(room: .init(), user: .init(), onRemove: { _ in }))
}
