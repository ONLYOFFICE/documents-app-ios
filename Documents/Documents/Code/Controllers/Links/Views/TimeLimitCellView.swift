//
//  TimeLimitCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 05.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct TimeLimitCellView: View {
    var model: TimeLimitCellModel
    var body: some View {
        HStack {
            DatePicker(
                model.title,
                selection: model.$selectedDate,
                in: min(model.selectedDate, Date())...,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }
}

struct TimeLimitCellModel {
    @Binding var selectedDate: Date
    var title = ""
}
