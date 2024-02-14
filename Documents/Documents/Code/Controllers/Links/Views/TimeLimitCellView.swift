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
    
    var minimumDate: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
    }
    
    var body: some View {
        HStack {
            DatePicker(
                model.title,
                selection: model.$selectedDate,
                in: minimumDate...,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }
}
struct TimeLimitCellModel {
    @Binding var selectedDate: Date
    var title = ""
}
