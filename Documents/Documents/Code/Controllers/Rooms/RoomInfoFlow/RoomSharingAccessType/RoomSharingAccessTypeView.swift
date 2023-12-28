//
//  RoomSharingAccessTypeView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28/12/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct RoomSharingAccessTypeView: View {
    @ObservedObject var viewModel: RoomSharingAccessTypeViewModel

    var body: some View {
        List {
            Section {
                ForEach(viewModel.accessModels) { model in
                    RoomSharingAccessRowView(model: model)
                }
            }
        }
        .disabled(viewModel.isAccessChanging)
        .overlay(creatingView)
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

    @ViewBuilder
    private var creatingView: some View {
        if viewModel.isAccessChanging {
            VStack {
                ActivityIndicatorView()
                Text("Changing access")
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
