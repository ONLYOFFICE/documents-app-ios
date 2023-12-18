//
//  ASCDocSpaceExternalLinkView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 28.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

// MARK: - TODO ckeck mark, single chosing

struct ASCDocSpaceExternalLinkView: View {
    
    @ObservedObject var viewModel: ASCDocSpaceExternalLinkViewModel
    
    var body: some View {
        list()
            .navigationBarTitle(Text(viewModel.screenState.title))
            .navigationBarItems(trailing: Button(action: {
                viewModel.onShareAction()
            }, label: {
                Text(viewModel.screenState.rightBarButtonTitle)
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
            }))
    }
    
    private func list() -> some View {
        List {
            ForEach(viewModel.screenState.tableData.sections) { section in
                sectionView(section)
            }
        }
    }
    
    private func sectionView(_ section: ExternalLinkStateModel.Section) -> some View {
        Section(header: Text(section.header ?? "")) {
            ForEach(section.cells) { cell in
                cellView(cell)
            }
        }
    }
    
    @ViewBuilder
    private func cellView(_ cell: ExternalLinkStateModel.Cell) -> some View {
        switch cell {
        case let .accessRights(model):
            ImagedDetailCellView(model: model)
        case let .linkLifeTime(model):
            SubTitledDetailCellView(model: model)
        case let .selectable(model):
            SelectableLabledCellView(model: model)
        case let .centeredLabled(model):
            ASCLabledCellView(model: model)
        case let .datePicker(model):
            TimeLimitCellView(model: model)
        }
    }
}

/*
struct ASCDocSpaceExternalLinkView: View {
    @State private var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isLinkLifeTimeViewPresenting = false

    var body: some View {
        VStack {
            List {
                Section(header: Text(NSLocalizedString("General", comment: ""))) {
                    HStack {
                        Text(NSLocalizedString("Acces rights", comment: ""))
                        Spacer()
                        Image(systemName: "eye.fill")
                            .foregroundColor(Asset.Colors.grayLight.swiftUIColor)
                        Button(action: {
                            // MARK: - TODO add action
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }

                    HStack {
                        Text(NSLocalizedString("Link life time", comment: ""))
                        Spacer()

                        Text(NSLocalizedString("Custom", comment: "")) // MARK: - TODO

                            .foregroundColor(Asset.Colors.grayLight.swiftUIColor) // MARK: - TODO

                        Button(action: {
                            // MARK: - TODO add action
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .onTapGesture {
                        isLinkLifeTimeViewPresenting = true
                    }
                    .navigation(isActive: $isLinkLifeTimeViewPresenting) {
                        ASCDocSpaceLinkLifeTimeView()
                    }
                }

                Section(header: Text(NSLocalizedString("Time limit", comment: ""))) {
                    HStack {
                        DatePicker(
                            NSLocalizedString("Valid through", comment: ""),
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.automatic)

                        // MARK: TODO date picker
                    }
                }

                Section(header: Text(NSLocalizedString("Type", comment: ""))) {
                    Text(NSLocalizedString("Anyone with the link", comment: ""))
                    Text(NSLocalizedString("DocSpace users only", comment: ""))
                }

                Section {
                    ASCLabledCellView(textString: NSLocalizedString("Copy link", comment: ""), cellType: .standard, textAlignment: .center)
                }

                Section {
                    ASCLabledCellView(textString: NSLocalizedString("Delete link", comment: ""), cellType: .deletable, textAlignment: .center)
                }
            }
        }
        .navigationBarTitle(Text(NSLocalizedString("External link", comment: "")), displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            // MARK: - TODO add share btn action
        }, label: {
            Text(NSLocalizedString("Share", comment: ""))
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
        }))
    }
}
*/
struct ASCDocSpaceExternalLinkView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ASCDocSpaceExternalLinkView(
                viewModel: .init(screenState: .customLinkLifeTime)
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Custom Link Life Time")
            
            ASCDocSpaceExternalLinkView(
                viewModel: .init(screenState: .systemLinkLifeTime)
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("System Link Life Time")
        }
    }
}
