//
//  ASCVersionRowView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 10.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCVersionRowView: View {
    let version: VersionViewModel
    let icon: Image
    let onOpen: () -> Void
    let onEditComment: () -> Void
    let onRestore: () -> Void
    let onDelete: () -> Void
    let onDownload: () -> Void
    let onMoreButton: () -> Void

    var body: some View {
        Section(header: Text("Version \(version.versionNumber)")) {
            ASCFileSwiftUICell(model: ASCFileSwiftUICellModel(
                date: version.dateDescription,
                author: version.author,
                comment: version.comment,
                icon: icon,
                action: {
                    onOpen()
                }
            ))
            .contextMenu {
                Button("Open", systemImage: "arrow.up.right.square") {
                    onOpen()
                }

                Button("Edit comment", systemImage: "text.bubble") {
                    onEditComment()
                }

                if version.canRestore {
                    Button("Restore", systemImage: "arrowshape.turn.up.right") {
                        onRestore()
                    }
                }

                Button("Download", systemImage: "square.and.arrow.down") {
                    onDownload()
                }

                Divider()

                if version.canDelete {
                    if #available(iOS 15.0, *) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            onDelete()
                        }
                    } else {
                        Button("Delete", systemImage: "trash") {
                            onDelete()
                        }
                    }
                }
            }
            .applyVersionSwipeActionsIfAvailable(
                version: version,
                onMoreButton: onMoreButton,
                onDelete: onDelete
            )
        }
    }
}
