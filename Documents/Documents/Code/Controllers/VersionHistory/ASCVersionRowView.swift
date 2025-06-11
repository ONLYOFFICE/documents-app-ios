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
                Button(NSLocalizedString("Open", comment: ""), systemImage: "arrow.up.right.square") {
                    onOpen()
                }

                Button(NSLocalizedString("Edit comment", comment: ""), systemImage: "text.bubble") {
                    onEditComment()
                }

                if version.canRestore {
                    Button(NSLocalizedString("Restore", comment: ""), systemImage: "arrowshape.turn.up.right") {
                        onRestore()
                    }
                }

                Button(NSLocalizedString("Download", comment: ""), systemImage: "square.and.arrow.down") {
                    onDownload()
                }

                Divider()

                if version.canDelete {
                    if #available(iOS 15.0, *) {
                        Button(NSLocalizedString("Delete", comment: ""), systemImage: "trash", role: .destructive) {
                            onDelete()
                        }
                    } else {
                        Button(NSLocalizedString("Delete", comment: ""), systemImage: "trash") {
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
