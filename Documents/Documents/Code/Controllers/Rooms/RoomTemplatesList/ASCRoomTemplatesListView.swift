//
//  ASCRoomTemplatesListView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import UIKit

struct ASCRoomTemplatesListView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var viewModel: ASCRoomTemplatesViewModel
    @State private var selectedTemplate: ASCFolder?
    @State private var isNavigationActive = false

    var body: some View {
        List(viewModel.templates, id: \.id) { template in
            TemplateViewRow(
                model: TemplateViewRowModel(
                    title: template.title,
                    subtitle: template.roomType?.name ?? "",
                    imageURL: URL(string: template.logo?.medium ?? ""),
                    placeholderColor: UIColor(hex: "#\(template.logo?.color ?? "")")
                )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selectedTemplate = template
                isNavigationActive = true
            }
        }
        .background(
            NavigationLink(
                destination: destinationView(),
                isActive: $isNavigationActive
            ) {
                EmptyView()
            }
        )
        .navigationTitle(NSLocalizedString("Form templates", comment: ""))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.fetchTemplates()
        }
    }

    @ViewBuilder
    private func destinationView() -> some View {
        if let template = selectedTemplate {
            ManageRoomView(viewModel: ManageRoomViewModel(
                screenMode: .createFromTemplate(template),
                selectedRoomType: template.roomTypeModel,
                onCreate: { _ in
                    presentationMode.wrappedValue.dismiss()
                }))
        } else {
            EmptyView()
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
