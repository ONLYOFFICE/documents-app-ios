//
//  ASCVersionHistoryView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 21.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Combine
import MBProgressHUD
import SwiftUI
import UIKit

enum VersionAlertType: Identifiable {
    case restore(VersionViewModel)
    case delete(VersionViewModel)

    var id: UUID {
        switch self {
        case let .restore(version), let .delete(version):
            return version.id
        }
    }
}

struct ASCVersionHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ASCVersionHistoryViewModel

    var body: some View {
        handleHUD()

        return NavigationView {
            List {
                ForEach(viewModel.versions) { version in
                    ASCVersionRowView(
                        version: version,
                        icon: Asset.Images.listFormatDocument.swiftUIImage,
                        onOpen: {
                            viewModel.triggerOpenVersion(version) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        },
                        onEditComment: {
                            viewModel.triggerEditComment(for: version)
                        },
                        onRestore: {
                            viewModel.triggerRestoreAlert(for: version)
                        },
                        onDelete: {
                            viewModel.triggerDeleteAlert(for: version)
                        },
                        onDownload: {
                            viewModel.triggerDownloadVersion(version) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    )
                }
            }
            .onAppear {
                viewModel.onAppear()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                versionHistoryTitle
                versionHistoryToolbar
            }
            .background(editCommentAlert)
        }
        .alert(item: $viewModel.screenModel.activeAlert, content: { alert(for: $0) })
    }

    // MARK: - View Components

    private var editCommentAlert: some View {
        TextFieldAlertSwiftUI(
            isPresented: $viewModel.screenModel.showEditCommentAlert,
            alert: TextFieldAlertSwiftUIModel(
                title: .editComment,
                message: nil,
                placeholder: "",
                accept: .save,
                cancel: .cancel
            ) { newText in
                if let newText = newText,
                   let version = viewModel.screenModel.versionToEdit
                {
                    viewModel.editComment(comment: newText, versionNumber: version.versionNumber)
                    viewModel.clearEditCommentState()
                }
            }
        )
        .allowsHitTesting(false)
    }

    private var versionHistoryTitle: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
                Text("Version History")
                    .font(.headline)
                Text(viewModel.fileTitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var versionHistoryToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private func alert(for type: VersionAlertType) -> Alert {
        switch type {
        case let .restore(version):
            return Alert(
                title: .restoreVersion,
                message: .restoreVersionAlert,
                primaryButton: .default(.restore) {
                    viewModel.restoreVersion(version: version)
                },
                secondaryButton: .cancel()
            )

        case let .delete(version):
            return Alert(
                title: .deleteVersion,
                message: .deleteVersionAlert,
                primaryButton: .destructive(.delete) {
                    viewModel.deleteVersion(version: version)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func handleHUD() {
        if viewModel.isActivityIndicatorVisible {
            MBProgressHUD.showTopMost(mode: .annularDeterminate)
        } else if let hud = MBProgressHUD.currentHUD {
            if let result = viewModel.resultModalModel {
                switch result.result {
                case .success:
                    hud.setState(result: .success(result.message))
                case .failure:
                    hud.setState(result: .failure(result.message))
                }
                hud.hide(animated: true, afterDelay: .twoSecondsDelay)
                DispatchQueue.main.async {
                    viewModel.resultModalModel = nil
                }
            } else {
                hud.hide(animated: true)
            }
        }
    }
}

struct ASCVersionRowView: View {
    let version: VersionViewModel
    let icon: Image
    let onOpen: () -> Void
    let onEditComment: () -> Void
    let onRestore: () -> Void
    let onDelete: () -> Void
    let onDownload: () -> Void

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

                if version.canDelete {
                    Button("Delete", systemImage: "trash") {
                        onDelete()
                    }
                }
            }
        }
    }
}

extension Text {
    static let deleteVersion = Text("Delete version")
    static let deleteVersionAlert = Text("You are about to delete a file version. It will be no possible to see or restore it anymore. Are you sure you want to continue?")
    static let restoreVersion = Text("Restore this version?")
    static let restoreVersionAlert = Text("Current file will be saved in version history.")
    static let restore = Text("Restore")
    static let delete = Text("Delete")
}

extension String {
    static let editComment = NSLocalizedString("Edit Comment", comment: "")
    static let save = NSLocalizedString("Save", comment: "")
    static let cancel = NSLocalizedString("Cancel", comment: "")
}
