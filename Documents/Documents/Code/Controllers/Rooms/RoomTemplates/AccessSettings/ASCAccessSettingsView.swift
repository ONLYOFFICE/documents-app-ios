//
//  ASCAccessSettingsView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 06.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCAccessSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var viewModel: ASCAccessSettingsViewModel
    
    var body: some View {
        List {
            availableForEveryoneSection
            if !viewModel.isTemplateAvailableForEveryone {
                addUsersAndGroupsSection
                accessToTemplateSection
            }
        }
        .navigationTitle(Text("Access settings"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading:Button(
                action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                },
            trailing:Button("Save") {
                viewModel.save()
            }
        )
        .onAppear {
            viewModel.fetchAccessList()
        }
    }
}

//MARK: - Sections
private extension ASCAccessSettingsView {
    @ViewBuilder
    var availableForEveryoneSection: some View {
        Section(footer: Text("All DocSpace and Room admins will be able to create rooms using this template.")
        ) {
            templateAvailabiltyCell
        }
    }
    
    @ViewBuilder
    var addUsersAndGroupsSection: some View {
        Section(
            header: Text("Add Users or Groups"),
            footer: Text("The added administrators will be able to create rooms using this template.")
        ) {
            chooseFromListCell
        }
    }
    
    @ViewBuilder
    var accessToTemplateSection: some View {
        if !viewModel.accessToTemplate.isEmpty {
            Section(header: Text("Access to template")) {
                ForEach(viewModel.accessToTemplate) { model in
                    ASCAccessRow(model: model)
                }
                .onDelete(perform: viewModel.removeAccess)
            }
        }
    }
}

//MARK: - Cells

private extension ASCAccessSettingsView {
    var chooseFromListCell: some View {
        HStack {
            Text("Choose from list")
            Spacer()
            ChevronRightView()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.chooseFromListScreenDisplaying = true
        }
    }
    
    var templateAvailabiltyCell: some View {
        Toggle(isOn: $viewModel.isTemplateAvailableForEveryone) {
            Text("Template available to everyone")
        }
        .tintColor(Color(Asset.Colors.brend.color))
        .onChange(of: viewModel.isTemplateAvailableForEveryone) { newValue in
            viewModel.isTemplateAvailableForEveryone = newValue
        }
    }
}
