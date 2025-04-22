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
    
    var body: some View {
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
                            Button("Open", systemImage: "arrow.up.right.square") {
                                
                            }
                            Button("Edit comment", systemImage: "text.bubble") {
                            }
                            
                            Button("Restore", systemImage: "arrowshape.turn.up.right") {
                                
                            }
                            
                            Button("Download", systemImage: "square.and.arrow.down") {
                                
                            }
                            
                            Button("Delete", systemImage: "trash") {
                                
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
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Version History")
                            .font(.headline)
                        Text("General financial report 2022.docx")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            
        }
    }
}

