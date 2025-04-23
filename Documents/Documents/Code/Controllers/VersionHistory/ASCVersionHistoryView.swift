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

struct ASCVersionHistoryView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ASCVersionHistoryViewModel
    
    @State private var isShowingRestoreAlert = false
    @State private var versionToRestore: VersionViewModel?

    var body: some View {
        ZStack {
            NavigationView {
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
                                
                                Button("Edit comment", systemImage: "text.bubble") { }
                                
                                Button("Restore", systemImage: "arrowshape.turn.up.right") {
                                    versionToRestore = version
                                    isShowingRestoreAlert = true
                                }
                                
                                Button("Download", systemImage: "square.and.arrow.down") { }
                                
                                Button("Delete", systemImage: "trash") { }
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
            }
        }
        .alert(isPresented: $isShowingRestoreAlert, content: { restoreAlert })
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

    private var restoreAlert: Alert {
        Alert(
            title: Text("Restore this version?"),
            message: Text("Current file will be saved in version history."),
            primaryButton: .default(Text("Restore")) {
                if let version = versionToRestore {
                    viewModel.restoreVersion(version: version)
                }
            },
            secondaryButton: .cancel()
        )
    }
}
