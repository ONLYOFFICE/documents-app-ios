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

extension RoomTypeModel: Equatable {}

struct RoomSelectionView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel = RoomSelectionViewModel()

    @Binding var selectedRoomType: RoomTypeModel?
    @State var dismissOnSelection = false
    @State private var isPresenting = true
    @State private var maxHeights: CGFloat = 0

    var body: some View {
        List(viewModel.roomsTypeModels, id: \.name) { model in
            RoomTypeViewRow(roomTypeModel: model)
                .frame(minHeight: maxHeights)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: SizePreferenceKey.self,
                                value: proxy.size
                            )
                    })
                .onPreferenceChange(SizePreferenceKey.self) { preferences in
                    if preferences.height > maxHeights {
                        maxHeights = preferences.height
                    }
                }
                .onTapGesture {
                    selectedRoomType = model
                    if dismissOnSelection {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        }
        .navigationBarTitle(Text(NSLocalizedString("Choose room type", comment: "")), displayMode: .inline)
        .navigationBarItems(
            trailing: Button(ASCLocalization.Common.cancel) {
                presentationMode.wrappedValue.dismiss()
            }
        )
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
    static func make(fromRoomType roomType: CreatingRoomType) -> RoomTypeModel {
        RoomTypeModel(
            type: roomType,
            name: roomType.name,
            description: roomType.description,
            icon: roomType.icon
        )
    }
}

#Preview {
    RoomSelectionView(selectedRoomType: .constant(nil))
}
