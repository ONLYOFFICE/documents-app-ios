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
                        icon: getFileIcon(fileExt: version.versionFile.title.fileExtension().lowercased()),
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
                        },
                        onMoreButton: {
                            viewModel.triggerMoreSheet(version: version)
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
        .applyVersionConfirmationDialogIfAvailable(
            isPresented: $viewModel.screenModel.isShowingBottomSheet,
            version: viewModel.screenModel.versionForBottomSheet,
            onOpen: { version in
                viewModel.triggerOpenVersion(version) {
                    presentationMode.wrappedValue.dismiss()
                }
            },
            onEditComment: { version in
                viewModel.triggerEditComment(for: version)
            },
            onRestore: { version in
                viewModel.triggerRestoreAlert(for: version)
            },
            onDownload: { version in
                viewModel.triggerDownloadVersion(version) {
                    presentationMode.wrappedValue.dismiss()
                }
            },
            onDelete: { version in
                viewModel.triggerDeleteAlert(for: version)
            }
        )
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
                Text(verbatim: viewModel.fileTitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var versionHistoryToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(NSLocalizedString("Close", comment: "")) {
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

@available(iOS 15.0, *)
extension View {
    func versionSwipeActions(
        version: VersionViewModel,
        onMoreButton: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if version.canDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            Button {
                onMoreButton()
            } label: {
                Label("More", systemImage: "ellipsis")
            }
            .tint(.gray)
        }
    }
}

extension View {
    func applyVersionSwipeActionsIfAvailable(
        version: VersionViewModel,
        onMoreButton: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        Group {
            if #available(iOS 15.0, *) {
                self.versionSwipeActions(
                    version: version,
                    onMoreButton: onMoreButton,
                    onDelete: onDelete
                )
            } else {
                self
            }
        }
    }
}

@available(iOS 15.0, *)
extension View {
    func versionConfirmationDialog(
        isPresented: Binding<Bool>,
        version: VersionViewModel?,
        onOpen: @escaping (VersionViewModel) -> Void,
        onEditComment: @escaping (VersionViewModel) -> Void,
        onRestore: @escaping (VersionViewModel) -> Void,
        onDownload: @escaping (VersionViewModel) -> Void,
        onDelete: @escaping (VersionViewModel) -> Void
    ) -> some View {
        confirmationDialog(
            "",
            isPresented: isPresented,
            titleVisibility: .hidden
        ) {
            if let version = version {
                Button(NSLocalizedString("Open", comment: ""), systemImage: "arrow.up.right.square") {
                    onOpen(version)
                }
                Button(NSLocalizedString("Edit comment", comment: ""), systemImage: "text.bubble") {
                    onEditComment(version)
                }
                if version.canRestore {
                    Button(NSLocalizedString("Restore", comment: ""), systemImage: "arrowshape.turn.up.right") {
                        onRestore(version)
                    }
                }
                Button(NSLocalizedString("Download", comment: ""), systemImage: "square.and.arrow.down") {
                    onDownload(version)
                }
                if version.canDelete {
                    Button(NSLocalizedString("Delete", comment: ""), systemImage: "trash", role: .destructive) {
                        onDelete(version)
                    }
                }
            }
        }
    }
}

extension View {
    func applyVersionConfirmationDialogIfAvailable(
        isPresented: Binding<Bool>,
        version: VersionViewModel?,
        onOpen: @escaping (VersionViewModel) -> Void,
        onEditComment: @escaping (VersionViewModel) -> Void,
        onRestore: @escaping (VersionViewModel) -> Void,
        onDownload: @escaping (VersionViewModel) -> Void,
        onDelete: @escaping (VersionViewModel) -> Void
    ) -> some View {
        Group {
            if #available(iOS 15.0, *) {
                self.versionConfirmationDialog(
                    isPresented: isPresented,
                    version: version,
                    onOpen: onOpen,
                    onEditComment: onEditComment,
                    onRestore: onRestore,
                    onDownload: onDownload,
                    onDelete: onDelete
                )
            } else {
                self
            }
        }
    }
}

extension ASCVersionHistoryView {
    private func getFileIcon(fileExt: String) -> Image {
        switch fileExt {
        case ASCConstants.FileExtensions.txt:
            return Asset.Images.listFormatTxt.swiftUIImage
        case _ where ASCConstants.FileExtensions.documents.contains(fileExt):
            return Asset.Images.listFormatDocument.swiftUIImage
        case _ where ASCConstants.FileExtensions.spreadsheets.contains(fileExt):
            return Asset.Images.listFormatSpreadsheet.swiftUIImage
        case _ where ASCConstants.FileExtensions.presentations.contains(fileExt):
            return Asset.Images.listFormatPresentation.swiftUIImage
        case ASCConstants.FileExtensions.docxf:
            return Asset.Images.listFormatDocxf.swiftUIImage
        case ASCConstants.FileExtensions.oform:
            return Asset.Images.listFormatOform.swiftUIImage
        case _ where ASCConstants.FileExtensions.forms.contains(fileExt),
             _ where ASCConstants.FileExtensions.pdfs.contains(fileExt):
            return Asset.Images.listFormatPdf.swiftUIImage
        default:
            return Asset.Images.listFormatUnknown.swiftUIImage
        }
    }
}
