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
}

struct ASCFileSwiftUICell: View {
    let model: ASCFileSwiftUICellModel

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter
    }()

    var body: some View {
        HStack {
            model.icon
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.dateFormatter.string(from: model.date))
                    .font(.footnote)
                    .fontWeight(.semibold)

                Text(model.author)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(model.comment)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
