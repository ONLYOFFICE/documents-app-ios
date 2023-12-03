//
//  CreateRoomView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 22.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

struct CreateRoomView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var viewModel: CreateRoomViewModel
    @Binding var isParentPresenting: Bool

    var body: some View {
        List {
            Section {
                CreatingRoomViewRow(room: viewModel.roomType.toRoom())
            }
            Section {
                TextField("Room name", text: $viewModel.roomName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.isCreatingRoom)
            }
        }
        .navigationBarTitle(Text(NSLocalizedString("Create room", comment: "")), displayMode: .inline)
        .navigationBarItems(
            leading: Button("Back") {
                presentationMode.wrappedValue.dismiss()
            },
            trailing: Button("Create") {
                viewModel.createRoom()
            }
            .disabled(viewModel.roomName.isEmpty)
        )
        .overlay(
            creatingRoomActivityView()
        )
        .overlay(
            errorMessage()
        )
        .onChange(of: viewModel.dismissNavStack, perform: { dismissNavStack in
            if dismissNavStack {
                isParentPresenting = false
            }
        })
    }
    
    private func creatingRoomActivityView() -> some View {
        Group {
            if viewModel.isCreatingRoom {
                VStack {
                    Text("Creating...")
                    ActivityIndicatorView()
                }
            }
        }
    }
    
    private func errorMessage() -> some View {
        Group {
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                
            }
        }
    }
}

struct CreateRoomView_Previews: PreviewProvider {
    static var previews: some View {
        CreateRoomView(
            viewModel: CreateRoomViewModel(roomType: .publicRoom),
            isParentPresenting: .constant(true)
        )
    }
}
