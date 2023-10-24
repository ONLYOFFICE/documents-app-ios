//
//  ASCCreateEntityUI.swift
//  Documents
//
//  Created by Alexander Yuzhin on 08.08.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCCreateEntityUI: View {
    // MARK: - Properties

    @Binding var allowClouds: Bool
    @Binding var onAction: ((CreateEntityUIType) -> Void)?

    private var createEntities: [CreateEntityViewModel] {
        [
            .init(
                type: .folder,
                caption: NSLocalizedString("New Folder", comment: ""),
                icon: Image(uiImage: Asset.Images.createFolder.image),
                action: { type in
                    onAction?(type)
                }
            ),
            .init(
                type: .importFile,
                caption: NSLocalizedString("Import File", comment: ""),
                icon: Image(uiImage: Asset.Images.createImport.image),
                action: { type in
                    onAction?(type)
                }
            ),
            .init(
                type: .importImage,
                caption: NSLocalizedString("Import Image", comment: ""),
                icon: Image(uiImage: Asset.Images.createPicture.image),
                action: { type in
                    onAction?(type)
                }
            ),
            .init(
                type: .makePicture,
                caption: NSLocalizedString("Take a Picture", comment: ""),
                icon: Image(uiImage: Asset.Images.createCamera.image),
                action: { type in
                    onAction?(type)
                }
            ),
            allowClouds
                ? .init(
                    type: .connectCloud,
                    caption: NSLocalizedString("Connect Storage", comment: ""),
                    icon: Image(uiImage: Asset.Images.createIcloud.image),
                    action: { type in
                        onAction?(type)
                    }
                )
                : nil,
        ].compactMap { $0 }
    }

    // MARK: - Lifecycle Methods

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                    .frame(width: 10)

                Button(NSLocalizedString("Document", comment: "")) {
                    onAction?(.document)
                }
                .buttonStyle(
                    CreateDocumentButtonStyle(
                        color: Color(Asset.Colors.documentEditor.color)
                            .opacity(0.1),
                        icon: Image(uiImage: Asset.Images.createDocument.image)
                    )
                )
                .padding(16)

                Spacer()

                Button(NSLocalizedString("Spreadsheet", comment: "")) {
                    onAction?(.spreadsheet)
                }
                .buttonStyle(
                    CreateDocumentButtonStyle(
                        color: Color(Asset.Colors.spreadsheetEditor.color)
                            .opacity(0.1),
                        icon: Image(uiImage: Asset.Images.createSpreadsheet.image)
                    )
                )
                .padding(16)

                Spacer()

                Button(NSLocalizedString("Presentation", comment: "")) {
                    onAction?(.presentation)
                }
                .buttonStyle(
                    CreateDocumentButtonStyle(
                        color: Color(Asset.Colors.presentationEditor.color)
                            .opacity(0.1),
                        icon: Image(uiImage: Asset.Images.createPresentation.image)
                    )
                )
                .padding(16)

                Spacer()
                    .frame(width: 10)
            }
            .fixedSize(horizontal: false, vertical: true)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .padding(16)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(createEntities.enumerated()), id: \.offset) { index, item in
                    Button(item.caption) {
                        item.action(item.type)
                    }
                    .buttonStyle(
                        CreateEntityButtonStyle(
                            icon: item.icon,
                            hasSeparator: index < createEntities.count - 1
                        )
                    )
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .padding([.leading, .trailing, .bottom], 16)
        }
        .background(Color(Asset.Colors.createPanel.color))
    }
}

struct CreateDocumentButtonStyle: ButtonStyle {
    var color: Color
    var icon: Image

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .cornerRadius(12)

                icon
            }
        }
        .scaleEffect(configuration.isPressed ? 0.95 : 1)

        configuration.label
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .font(Font(UIFont.preferredFont(forTextStyle: .caption2)))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct CreateEntityButtonStyle: ButtonStyle {
    var icon: Image
    var hasSeparator = true

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                configuration.label
                    .font(Font(UIFont.preferredFont(forTextStyle: .body)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding([.leading, .trailing], 16)

                Spacer()

                icon
                    .frame(width: 24, height: 24)
                    .padding(16)
            }
            .padding(0)
            .frame(height: 52)

            if hasSeparator {
                Rectangle()
                    .frame(height: 1.0 / UIScreen.main.scale)
                    .overlay(Color(UIColor.opaqueSeparator))
            }
        }
        .background(configuration.isPressed
            ? Color(UIColor.tertiarySystemGroupedBackground)
            : Color(UIColor.secondarySystemGroupedBackground))
    }
}

#if DEBUG
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ASCCreateEntityUI(
                allowClouds: .constant(true),
                onAction: .constant { type in
                    print("\(type)")
                }
            )
        }
    }
#endif
