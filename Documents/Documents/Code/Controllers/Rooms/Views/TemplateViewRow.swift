//
//  TemplateViewRow.swift
//  Documents
//
//  Created by Lolita Chernysheva on 04.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import SwiftUI

struct TemplateViewRowModel {
    var title: String
    var subtitle: String
    var imageURL: URL?
    var placeholderColor: UIColor
}

struct TemplateViewRow: View {
    let model: TemplateViewRowModel

    var body: some View {
        HStack(spacing: .rowSpacing) {
            ZStack {
                CornerFrame(color: Color(model.placeholderColor))
                    .frame(width: .imageSize, height: .imageSize)

                if let imageURL = model.imageURL {
                    KFImage(imageURL)
                        .resizable()
                        .scaledToFill()
                        .frame(width: .imageSize - .imagePadding, height: .imageSize - .imagePadding)
                        .clipShape(RoundedRectangle(cornerRadius: (.imageSize - .imagePadding) * .textCornerRadiusRatio))
                } else {
                    Text(verbatim: initials(from: model.title))
                        .font(.system(size: .imageSize * .initialsFontScale, weight: .semibold))
                        .foregroundColor(Color(model.placeholderColor))
                        .frame(width: .imageSize - .imagePadding, height: .imageSize - .imagePadding)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: (.imageSize - .imagePadding) * .textCornerRadiusRatio))
                }
            }

            VStack(alignment: .leading, spacing: .textSpacing) {
                Text(verbatim: model.title)
                    .font(.footnote)
                    .fontWeight(.semibold)
                Text(verbatim: model.subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondaryLabel)
        }
        .padding(.vertical, .verticalPadding)
    }

    private func initials(from title: String) -> String {
        let components = title.components(separatedBy: .whitespaces)
        let initials = components.prefix(2).compactMap { $0.first }
        return String(initials)
    }
}

struct CornerFrame: View {
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Top-left
                Path { path in
                    path.move(to: CGPoint(x: .inset, y: .lineLength + .inset))
                    path.addLine(to: CGPoint(x: .inset, y: .inset + .cornerRadius))
                    path.addQuadCurve(
                        to: CGPoint(x: .inset + .cornerRadius, y: .inset),
                        control: CGPoint(x: .inset, y: .inset)
                    )
                    path.addLine(to: CGPoint(x: .lineLength + .inset, y: .inset))
                }
                .stroke(color, lineWidth: .lineWidth)

                // Top-right
                Path { path in
                    path.move(to: CGPoint(x: w - .inset, y: .lineLength + .inset))
                    path.addLine(to: CGPoint(x: w - .inset, y: .inset + .cornerRadius))
                    path.addQuadCurve(
                        to: CGPoint(x: w - .inset - .cornerRadius, y: .inset),
                        control: CGPoint(x: w - .inset, y: .inset)
                    )
                    path.addLine(to: CGPoint(x: w - .lineLength - .inset, y: .inset))
                }
                .stroke(color, lineWidth: .lineWidth)

                // Bottom-left
                Path { path in
                    path.move(to: CGPoint(x: .inset, y: h - .lineLength - .inset))
                    path.addLine(to: CGPoint(x: .inset, y: h - .inset - .cornerRadius))
                    path.addQuadCurve(
                        to: CGPoint(x: .inset + .cornerRadius, y: h - .inset),
                        control: CGPoint(x: .inset, y: h - .inset)
                    )
                    path.addLine(to: CGPoint(x: .lineLength + .inset, y: h - .inset))
                }
                .stroke(color, lineWidth: .lineWidth)

                // Bottom-right
                Path { path in
                    path.move(to: CGPoint(x: w - .inset, y: h - .lineLength - .inset))
                    path.addLine(to: CGPoint(x: w - .inset, y: h - .inset - .cornerRadius))
                    path.addQuadCurve(
                        to: CGPoint(x: w - .inset - .cornerRadius, y: h - .inset),
                        control: CGPoint(x: w - .inset, y: h - .inset)
                    )
                    path.addLine(to: CGPoint(x: w - .lineLength - .inset, y: h - .inset))
                }
                .stroke(color, lineWidth: .lineWidth)
            }
        }
    }
}

private extension CGFloat {
    static let imageSize: CGFloat = 36
    static let lineLength: CGFloat = 12
    static let lineWidth: CGFloat = 2
    static let inset: CGFloat = 2
    static let cornerRadius: CGFloat = 4
    static let imagePadding: CGFloat = 12
    static let textCornerRadiusRatio: CGFloat = 0.2
    static let initialsFontScale: CGFloat = 0.4
    static let rowSpacing: CGFloat = 14
    static let verticalPadding: CGFloat = 8
    static let textSpacing: CGFloat = 2
}
