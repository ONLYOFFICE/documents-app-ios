//
//  RoomSelectionView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 16.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct RoomTypeModel {
    var type: CreatingRoomType
    var name: String
    var description: String
    var icon: UIImage
    var showDisclosureIndicator: Bool = true
}

struct RoomTypeRowModel {
    var name: String
    var description: String
    var icon: UIImage
    var showDisclosureIndicator: Bool = true
    var onTap: () -> Void = {}
}

extension RoomTypeModel {
    func mapToRowModel(onTap: @escaping () -> Void) -> RoomTypeRowModel {
        RoomTypeRowModel(
            name: name,
            description: description,
            icon: icon,
            onTap: onTap
        )
    }
}

extension RoomTypeModel: Equatable {}

struct RoomSelectionView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: RoomSelectionViewModel

    @Binding var selectedRoomType: RoomTypeModel?
    @State var dismissOnSelection = false
    @State private var isPresenting = true
    @State private var maxHeights: CGFloat = 0
    @State private var showTemplates = false

    var body: some View {
        List(viewModel.roomTypeModel(showDisclosureIndicator: !dismissOnSelection), id: \.name) { model in
            RoomTypeViewRow(roomTypeModel: model)
                .frame(minHeight: maxHeights)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: SizePreferenceKey.self, value: proxy.size)
                    }
                )
                .onPreferenceChange(SizePreferenceKey.self) { preferences in
                    if preferences.height > maxHeights {
                        maxHeights = preferences.height
                    }
                }
                .onReceive(viewModel.$selectedType) { newType in
                    if let type = newType {
                        selectedRoomType = type
                        if dismissOnSelection {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        }
        .navigationTitle(NSLocalizedString("Choose room type", comment: ""))
        .navigationBarItems(isLastInNCStack: dismissOnSelection, presentationMode: presentationMode)
        .background(
            NavigationLink(
                destination: ASCRoomTemplatesListView(viewModel: ASCRoomTemplatesViewModel()),
                isActive: $showTemplates,
                label: { EmptyView() }
            )
        )
        .onAppear {
            viewModel.onShowTemplates = {
                showTemplates = true
            }
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: Value = .zero

    static func reduce(value: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

extension RoomTypeModel {
    static func make(fromRoomType roomType: CreatingRoomType, isRoomTemplate: Bool? = false) -> RoomTypeModel {
        RoomTypeModel(
            type: roomType,
            name: roomType.name,
            description: roomType.description,
            icon: roomType.icon(isTemplate: isRoomTemplate ?? false)
        )
    }
}

private extension View {
    func navigationBarItems(isLastInNCStack: Bool, presentationMode: Binding<PresentationMode>) -> some View {
        navigationBarItems(
            leading: isLastInNCStack
                ? Button("") {}
                : Button(ASCLocalization.Common.close) {
                    presentationMode.wrappedValue.dismiss()
                }
        )
    }
}

#Preview {
    RoomSelectionView(viewModel: RoomSelectionViewModel(), selectedRoomType: .constant(nil))
}
