//
//  VDRFillingStatusEventRowView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 7.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import SwiftUI

/// Row view for a single timeline event

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct VDRFillingHistoryElement: Identifiable {
    var id: Date { date }

    var statusCode: String
    var date: Date

    var description: String {
        switch statusCode {
        case "0":
            return "Opened the form to fill out"
        case "1":
            return "Submitted their part. The form was sent to the next role."
        case "2":
            return "Filling was stopped by"
        default:
            return "Unknown status"
        }
    }
}

struct VDRFillingStatusEventRowViewModel: Identifiable {
    let id: UUID
    let user: ASCUser?
    let stopedBy: ASCUser?
    let secuence: Int
    let roleName: String
    let imageBorderColor: Color
    let statusBorderColor: Color
    let roleColor: Color
    let borderType: BorderType
    let actorName: String
    let history: [VDRFillingHistoryElement]
    let fillingStatus: FormFillingStatus

    enum BorderType: Int {
        case solid
        case dashed
    }

    enum ImageSourceType {
        case url(String)
        case asset(ImageAsset)
    }
}

struct VDRFillingStatusEventRowView: View {
    let model: VDRFillingStatusEventRowViewModel

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            secuence
                .padding(.top, 12)

            HStack(alignment: .center, spacing: 22) {
                VStack(alignment: .center) {
                    avatar
                    connector
                }
            }
            .padding(.leading, 8)

            VStack(alignment: .leading, spacing: 4) {
                roleName
                actorName
                statusHistory
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: HeightPreferenceKey.self, value: geo.size.height)
                }
            )

            Spacer()
        }
        .onPreferenceChange(HeightPreferenceKey.self) { height in
            self.contentHeight = height
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var roleName: some View {
        Text(verbatim: model.roleName)
            .foregroundColor(.primary)
            .font(.subheadline)
    }

    @ViewBuilder
    private var actorName: some View {
        Text(verbatim: model.actorName)
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var statusHistory: some View {
        ForEach(model.history) { element in
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    Text(element.description)
                        .font(.caption2)
                    if element.statusCode == "2", let stopedBy = model.stopedBy {
                        Text(verbatim: stopedBy.displayName ?? "")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                }

                Text(historyDisplayFormatter.string(from: element.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var secuence: some View {
        Text(verbatim: "\(model.secuence)")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var avatar: some View {
        ZStack {
            switch model.borderType {
            case .dashed:
                Circle()
                    .stroke(style: StrokeStyle(
                        lineWidth: 1.4,
                        dash: [2.5, 2.5]
                    ))
                    .foregroundColor(model.imageBorderColor)
                    .frame(width: 40, height: 40)
            case .solid:
                Circle()
                    .stroke(model.imageBorderColor, lineWidth: 1.4)
                    .frame(width: 40, height: 40)
            }

            imageView(for: .url(model.user?.avatar ?? ""))
        }
    }

    @ViewBuilder
    private var connector: some View {
        let lineHeight = max(30, contentHeight - 50)
        switch model.borderType {
        case .dashed:
            Path { path in
                let x = 0.5
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: lineHeight))
            }
            .stroke(style: StrokeStyle(
                lineWidth: 1.4,
                dash: [2, 2]
            ))
            .foregroundColor(model.statusBorderColor)
            .frame(width: 1, height: lineHeight)
            .padding(.top, 4)

        case .solid:
            Rectangle()
                .fill(model.statusBorderColor)
                .frame(width: 1, height: lineHeight)
                .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func imageView(for imageType: VDRFillingStatusEventRowViewModel.ImageSourceType) -> some View {
        switch imageType {
        case let .url(string):
            if let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed,
               !string.contains(String.defaultUserPhotoSize),
               let url = URL(string: portal + string)
            {
                KFImage(url)
                    .resizable()
                    .frame(width: .imageWidth, height: .imageHeight)
                    .cornerRadius(.imageCornerRadius)
                    .clipped()
            } else {
                Image(asset: Asset.Images.avatarDefault)
                    .resizable()
                    .frame(width: .imageWidth, height: .imageHeight)
            }
        case let .asset(asset):
            Image(asset: asset)
                .resizable()
                .frame(width: .imageWidth, height: .imageHeight)
        }
    }
}

private extension CGFloat {
    static let imageWidth: CGFloat = 34
    static let imageHeight: CGFloat = 34
    static let imageCornerRadius: CGFloat = 17
}

private let historyDisplayFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "M/d/yyyy h:mm a"
    df.locale = Locale(identifier: "en_US_POSIX")
    return df
}()
