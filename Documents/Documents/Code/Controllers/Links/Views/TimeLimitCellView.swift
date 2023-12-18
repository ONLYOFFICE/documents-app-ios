//
//  TimeLimitCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 05.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct TimeLimitCellView: View {
    @State var model: TimeLimitCellModel
    var body: some View {
        HStack {
            DatePicker(
                model.title,
                selection: $model.selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.automatic)
        }
    }
}

struct TimeLimitCellModel {
    @State var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    var title = ""
}


