//
//  ASCVersionHistoryView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 21.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import Combine
import UIKit
import MBProgressHUD

enum VersionAlertType: Identifiable {
    case restore(VersionViewModel)
    case delete(VersionViewModel)

    var id: UUID {
        switch self {
        case .restore(let version), .delete(let version):
            return version.id
        }
    }
}

struct ASCVersionHistoryView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ASCVersionHistoryViewModel
    
    @State private var activeAlert: VersionAlertType?
    @State private var isShowingRestoreAlert = false
    @State private var versionToRestore: VersionViewModel?
    @State private var isShowingDeleteAlert = false
    @State private var versionToDelete: VersionViewModel?
    
    @State private var showEditCommentAlert = false
    @State private var versionToEdit: VersionViewModel?

    
    var body: some View {
        handleHUD()
        
        return NavigationView {
            List {
                ForEach(viewModel.versions) { version in
                    Section(header: Text("Version \(version.versionNumber)")) {
                        ASCFileSwiftUICell(model: ASCFileSwiftUICellModel(
                            date: version.dateDescription,
                            author: version.author,
                            comment: version.comment,
                            icon: Asset.Images.listFormatDocument.swiftUIImage)
                        )
                        .contextMenu {
                            Button("Open", systemImage: "arrow.up.right.square") { }

                            Button("Edit comment", systemImage: "text.bubble") {
                                versionToEdit = version
                                showEditCommentAlert = true
                            }

                            if version.canRestore {
                                Button("Restore", systemImage: "arrowshape.turn.up.right") {
                                    activeAlert = .restore(version)
                                }
                            }

                            Button("Download", systemImage: "square.and.arrow.down") {
                            }

                            if version.canDelete {
                                Button("Delete", systemImage: "trash") {
                                    activeAlert = .delete(version)
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchVersions()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                versionHistoryTitle
                versionHistoryToolbar
            }
            .background(
                TextFieldAlertSwiftUI(isPresented: $showEditCommentAlert, alert: TextFieldAlertSwiftUIModel(
                    title: NSLocalizedString("Edit Comment", comment: ""),
                    message: nil,
                    placeholder: "",
                    accept: NSLocalizedString("Save", comment: ""),
                    cancel: NSLocalizedString("Cancel", comment: "")
                ) { newText in
                    if let newText = newText,
                       let version = versionToEdit {
                        viewModel.editComment(comment: newText, versionNumber: version.versionNumber)
                    }
                })
                .allowsHitTesting(false)
            )
        }
        .alert(item: $activeAlert, content: { alert(for: $0) })
    }

    // MARK: - View Components

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
                title: Text("Restore this version?"),
                message: Text("Current file will be saved in version history."),
                primaryButton: .default(Text("Restore")) {
                    viewModel.restoreVersion(version: version)
                },
                secondaryButton: .cancel()
            )
            
        case let .delete(version):
            return Alert(
                title: Text("Delete version"),
                message: Text("You are about to delete a file version. It will be no possible to see or restore it anymore. Are you sure you want to continue?"),
                primaryButton: .destructive(Text("Delete")) {
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
