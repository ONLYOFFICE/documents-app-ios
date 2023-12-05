//
//  CreateGeneralLinkView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 20.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct CreateGeneralLinkView: View {
    @ObservedObject var viewModel: CreateGeneralLinkViewModel
    
    @State private var isGeneralLinkCreated = false
    @State private var isAdditionalLinkCreated = false //MARK: - TODO add constraint to 5 links
    
    @State private var isExternalLinkViewPresenting = false

    var body: some View {
        list()
        .navigationBarTitle(Text(NSLocalizedString("Sharing settings", comment: "")), displayMode: .inline)
        .navigationBarItems(leading: Button(action: { //TODO: - get from model
            // TODO:  add close btn action
        }, label: {
            Text(NSLocalizedString("Close", comment: "")) //TODO: - get from model
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
        }))
    }
    
    func list() -> some View {
        List {
            ForEach(viewModel.screenState.tableData.sections) { section in
                sectionView(section)
            }
        }
    }
    
    func sectionView(_ section: CreateGeneralLinkStateModel.Section) -> some View {
        Section(header: sectionHeader(section.header),
                footer: Text(section.footer))
        {
            ForEach(section.cells) { cell in
                cellView(cell)
            }
        }
    }
    
    func sectionHeader(_ header: CreateGeneralLinkStateModel.SectionHeader) -> some View {
        let hasSubtitle = header.subtitle != nil
        let hasIcon = header.icon != nil
        return HStack {
            switch (hasSubtitle, hasIcon) {
            case (true, true):
                Text(header.title)
                Text(header.subtitle ?? "")
                Spacer()
                Image(uiImage: header.icon ?? UIImage())
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
            case (true, false):
                Text(header.title)
                Text(header.subtitle ?? "")
            default:
                Text(header.title)
                Spacer()
            }
        }
    }
    
    private func cellView(_ cell: CreateGeneralLinkStateModel.Cell) -> some View {
        switch cell {
        case let .createLink(model):
            return AnyView(configureCreateLinkCellView(model: model))
            
        // TODO: handle new cases
        case let .link(model):
            return AnyView(configureLinkCellView(model: model))
        }
    }
    
    private func configureCreateLinkCellView(model: ASCCreateLinkCellModel) -> some View {
        ASCCreateLinkCellView(model: model)
            .onTapGesture {
                model.onTapAction()
            }
    }
    
    private func configureLinkCellView(model: ASCLinkCellModel) -> some View {
        ASCLinkCellView(model: model)
            .onTapGesture {
                model.onTapAction() //TODO: -
            }
    }
}

struct CreateGeneralLinkView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
           CreateGeneralLinkView(
               viewModel: .init(screenState: .noLinksState)
           )
           .previewLayout(.sizeThatFits)
           .previewDisplayName("No Links State")

           CreateGeneralLinkView(
            viewModel: .init(screenState: .generalLinkState)
           )
           .previewLayout(.sizeThatFits)
           .previewDisplayName("General link State")
            
            CreateGeneralLinkView(
                viewModel: .init(screenState: .additionalLinkState)
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Additional link State")
            
       }
    }
}
