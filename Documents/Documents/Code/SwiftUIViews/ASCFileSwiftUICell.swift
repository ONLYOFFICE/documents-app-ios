//
//  ASCFileSwiftUICell.swift
//  Documents
//
//  Created by Lolita Chernysheva on 22.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCFileSwiftUICellModel: Identifiable {
    let id = UUID()
    let date: Date
    let author: String
    let comment: String
    let icon: Image

    var action: () -> Void
}

struct ASCFileSwiftUICell: View {
    let model: ASCFileSwiftUICellModel

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter
    }()

    private var dateString: String {
        if #available(iOS 15.0, *) {
            return "\(model.date.formatted(date: .numeric, time: .omitted)) \(model.date.formatted(date: .omitted, time: .standard))"
        } else {
            return Self.dateFormatter.string(from: model.date)
        }
    }

    var body: some View {
        HStack {
            model.icon
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: dateString)
                    .font(.footnote)
                    .fontWeight(.semibold)

                Text(verbatim: model.author)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(verbatim: model.comment)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            model.action()
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    ASCFileSwiftUICell(
        model: ASCFileSwiftUICellModel(
            date: Date().adding(.day, value: -10),
            author: "John Doe",
            comment: "Updated the document with the latest information on user roles and permissions.",
            icon: Image("highlighter"),
            action: {}
        )
    )
}
