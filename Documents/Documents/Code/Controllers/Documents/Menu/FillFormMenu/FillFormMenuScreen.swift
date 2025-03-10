//
//  FillFormMenuScreen.swift
//  Documents
//
//  Created by Pavel Chernyshev on 9.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct FillFormMenuScreen: View {
    let onOpenTapped: () -> Void
    let onShareTapped: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                List {
                    menuItem(
                        title: NSLocalizedString("Fill out the form yourself", comment: "Title for opening form filling"),
                        subtitle: NSLocalizedString("Fill in the fields of the original form in the editor window.", comment: "Subtitle for form filling"),
                        action: {
                            presentationMode.wrappedValue.dismiss()
                            onOpenTapped()
                        }
                    )

                    menuItem(
                        title: NSLocalizedString("Share & collect", comment: "Title for sharing and collecting form"),
                        subtitle: NSLocalizedString("Share your form and collect responses via a Form filling room.", comment: "Subtitle for sharing form"),
                        action: {
                            presentationMode.wrappedValue.dismiss()
                            onShareTapped()
                        }
                    )
                }
                .listStyle(InsetGroupedListStyle())
                .navigationBarTitle(NSLocalizedString("Fill in as", comment: "Title for fill-in options screen"), displayMode: .inline)
                .navigationBarItems(trailing: Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }

    @ViewBuilder
    private func menuItem(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(verbatim: title)
                        .font(.body)
                        .foregroundColor(.label)
                    Text(verbatim: subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
    }
}
