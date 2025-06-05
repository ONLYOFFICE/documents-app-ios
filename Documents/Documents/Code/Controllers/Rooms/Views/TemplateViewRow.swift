//
//  TemplateViewRow.swift
//  Documents
//
//  Created by Lolita Chernysheva on 04.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import Kingfisher

struct TemplateViewRowModel {
    var title: String
    var subtitle: String
    var imageURL: URL?
    var placeholderColor: UIColor
}

struct TemplateViewRow: View {
    let model: TemplateViewRowModel
    let size: CGFloat = 36

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: size / 6)
                    .stroke(Color(model.placeholderColor), lineWidth: 2)
                    .frame(width: size, height: size)

                if let imageURL = model.imageURL {
                    KFImage(imageURL)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size - 12, height: size - 12)
                        .clipShape(RoundedRectangle(cornerRadius: (size - 12) * 0.2))
                } else {
                    Text(initials(from: model.title))
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(Color(model.placeholderColor))
                        .frame(width: size - 12, height: size - 12)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: (size - 12) * 0.2))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(.footnote)
                    .fontWeight(.semibold)
                Text(model.subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondaryLabel)
        }
        .padding(.vertical, 8)
    }

    private func initials(from title: String) -> String {
        let components = title.components(separatedBy: .whitespaces)
        let initials = components.prefix(2).compactMap { $0.first }
        return String(initials)
    }
}
