//
//  ASCRoomTemplatesListView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import UIKit


struct ASCRoomTemplatesListView: View {
    @ObservedObject var viewModel: ASCRoomTemplatesViewModel

    var body: some View {
        List(viewModel.templates, id: \.id) { template in
            TemplateViewRow(
                model: TemplateViewRowModel(
                    title: template.title,
                    subtitle: template.roomType?.name ?? "",
                    imageURL: URL(string: template.logo?.medium ?? ""),
                    placeholderColor: UIColor(hex: "#\(template.logo?.color ?? "")")
                )
            )
        }
        .navigationTitle(NSLocalizedString("Form templates", comment: ""))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.fetchTemplates()
        }
    }
}

