//
//  MenuView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 07.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct MenuViewItem: Identifiable {
    var id = UUID()
    var text: String
    var customImage: Image?
    var systemImageName: String?
    var action: () -> Void
}

struct MenuView<Content>: View where Content: View {
    @State private var showingActionSheet = false
    let menuItems: [MenuViewItem]
    let content: () -> Content

    private var actionSheetButtons: [ActionSheet.Button] {
        var btns: [ActionSheet.Button] = menuItems.map {
            .default(Text($0.text), action: $0.action)
        }
        btns.append(.cancel())
        return btns
    }

    var body: some View {
        if #available(iOS 14.0, *) {
            menu
        } else {
            actionSheet
        }
    }

    var actionSheet: some View {
        content()
            .onTapGesture {
                showingActionSheet = true
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text(""),
                    buttons: actionSheetButtons
                )
            }
    }

    var menu: some View {
        Menu {
            ForEach(menuItems) { item in
                Button(action: item.action) {
                    HStack {
                        if let customImage = item.customImage {
                            customImage
                        } else if let systemImageName = item.systemImageName {
                            Image(systemName: systemImageName)
                        }
                        Text(item.text)
                    }
                }
            }
        } label: {
            content()
        }
    }
}
