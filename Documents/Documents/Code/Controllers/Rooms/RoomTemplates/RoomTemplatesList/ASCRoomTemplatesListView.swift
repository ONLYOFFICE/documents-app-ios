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
    @State private var isFirstLoad = true

    var onCreateFromTemplate: ((ASCFolder) -> Void)?

    var body: some View {
        Group {
            if viewModel.templates.isEmpty && !isFirstLoad {
                emptyTemplatedView
            } else {
                templatesList
            }
        }
        .navigationTitle(NSLocalizedString("From templates", comment: ""))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if isFirstLoad {
                isFirstLoad = false
                Task {
                    await viewModel.fetchTemplates()
                }
            }
        }
    }

    private var templatesList: some View {
        List(viewModel.templates, id: \.id) { template in
            TemplateViewRow(
                model: TemplateViewRowModel(
                    title: template.title,
                    subtitle: template.roomType?.name ?? "",
                    imageURL: makeTemplateImageURL(for: template),
                    placeholderColor: UIColor(hex: "#\(template.logo?.color ?? "")"),
                    provider: viewModel.provider
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
    }

    private func makeTemplateImageURL(for template: ASCFolder) -> URL? {
        guard let urlStr = template.logo?.small,
              !urlStr.isEmpty,
              let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed
        else {
            return nil
        }
        return URL(string: portal + urlStr)
    }

    @ViewBuilder
    private var emptyTemplatedView: some View {
        VStack {
            Asset.Images.emptyFolder.swiftUIImage
                .padding(.top, .emptyViewImageInsets)
            Text("No templates here yet")
                .font(.title2)
                .padding(.top, .emptyViewTitleInset)
            Text("You can create a template from\na room in the Room section")
                .font(.caption)
                .foregroundColor(.secondaryLabel)
                .padding(.top, .emptyViewSubtitleInset)
            Spacer()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func destinationView() -> some View {
        if let template = selectedTemplate {
            ManageRoomView(viewModel: ManageRoomViewModel(
                screenMode: .createFromTemplate(template),
                selectedRoomType: template.roomTypeModel,
                onCreate: { createdRoom in
                    Task { @MainActor in
                        presentationMode.wrappedValue.dismiss()
                        onCreateFromTemplate?(createdRoom)
                    }
                }
            ))
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

private extension CGFloat {
    static let emptyViewTitleInset: CGFloat = 32
    static let emptyViewSubtitleInset: CGFloat = 16
    static let emptyViewImageInsets: CGFloat = 80
}
