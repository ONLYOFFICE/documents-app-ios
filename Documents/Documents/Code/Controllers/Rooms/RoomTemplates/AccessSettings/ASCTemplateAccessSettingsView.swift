//
//  ASCTemplateAccessSettingsView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 06.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCTemplateAccessSettingsView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: ASCTemplateAccessSettingsViewModel

    var body: some View {
        ZStack {
            if viewModel.dataModel.isInitalFetchCompleted {
                List {
                    availableForEveryoneSection
                    if !viewModel.dataModel.isTemplateAvailableForEveryone {
                        addUsersAndGroupsSection
                        accessToTemplateSection
                    }
                }
            } else {
                ActivityIndicatorView()
            }
            if viewModel.isLoading {
                ActivityIndicatorView()
            }
        }
        .navigationTitle(Text("Access settings"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigateToChooseMembers(isActive: $viewModel.dataModel.isChooseFromListScreenDisplaying, viewModel: viewModel)
        .navigationBarItems(
            leading: Button(
                action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                },
            trailing: Button(NSLocalizedString("Save", comment: "")) {
                Task {
                    await viewModel.save()
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .disabled(!viewModel.dataModel.saveButtonIsEnabled)
        )
        .onAppear {
            viewModel.loadData()
        }
        .onReceive(viewModel.$dataModel) { _ in
            if viewModel.dataModel.dissmiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Sections

private extension ASCTemplateAccessSettingsView {
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
        if !viewModel.screenModel.accessRowModels.isEmpty {
            Section(header: Text("Access to template")) {
                ForEach(viewModel.screenModel.accessRowModels) { model in
                    ASCAccessRow(model: model)
                }
                .onDelete(perform: viewModel.removeAccess)
            }
        }
    }
}

// MARK: - Cells

private extension ASCTemplateAccessSettingsView {
    var chooseFromListCell: some View {
        HStack {
            Text("Choose from list")
            Spacer()
            ChevronRightView()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.didTapChooseFromList()
        }
    }

    var templateAvailabiltyCell: some View {
        Toggle(isOn: $viewModel.dataModel.isTemplateAvailableForEveryone) {
            Text("Template available to everyone")
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }
}

// MARK: - Navigation

private extension View {
    @ViewBuilder
    func navigateToChooseMembers(isActive: Binding<Bool>, viewModel: ASCTemplateAccessSettingsViewModel) -> some View {
        navigation(isActive: isActive, destination: {
            ASCChooseRoomTemplateMembersView(
                viewModel: ASCChooseRoomTemplateMembersViewModel(
                    ignoreMembersIds: Set(viewModel.screenModel.accessRowModels.compactMap(\.id))
                ) {
                    viewModel.onChooseMembersAdd(model: $0)
                }
            )
        })
    }
}
