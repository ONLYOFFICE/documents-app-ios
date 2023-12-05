//
//  CreateGeneralLinkViewModel.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 20.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

struct CreateGeneralLinkStateModel {
    var title = ""
    var leftNavButtonName = ""
    var tableData: TableData
    
    static let empty = CreateGeneralLinkStateModel(tableData: .init(sections: []))
    
    struct TableData {
        var sections: [Section]
    }
    
    struct Section: Identifiable {
        var id = UUID()
        var header: SectionHeader
        var cells: [Cell]
        var footer: String
    }
    
    enum Cell: Identifiable {
        var id: UUID { UUID() }
        
        case createLink(ASCCreateLinkCellModel)
        case link(ASCLinkCellModel)
    }
    
    struct SectionHeader {
        var title: String
        var subtitle: String?
        var icon: UIImage?
    }
}

class CreateGeneralLinkViewModel: ObservableObject {
    @Published var screenState: CreateGeneralLinkStateModel = .empty
    
    // MARK: temp
    init(screenState: CreateGeneralLinkStateModel) {
        self.screenState = screenState
    }

    func createAndCopyGeneralLink() {}
    func createAndCopyAdditionalLink() {}
}

extension CreateGeneralLinkStateModel {
    
    static var noLinksState = CreateGeneralLinkStateModel(
        tableData: CreateGeneralLinkStateModel.TableData(
            sections: [
                CreateGeneralLinkStateModel.Section(
                    header: .init(title: "General links"),
                    cells: [
                        .createLink(.init(textString: "Create and copy", onTapAction: {}))
                    ],
                    footer: "Provide general access to the document selecting the required permission level.")
            ]
        )
    )
    
    static var generalLinkState = CreateGeneralLinkStateModel(
        tableData: CreateGeneralLinkStateModel.TableData(
            sections: [
                CreateGeneralLinkStateModel.Section(
                    header: .init(title: "General links"),
                    cells: [
                        .link(.init(titleKey: "Anyone with the link", //TODO: -
                                    subTitleKey: "Expires after 7 days", //TODO: -
                                    onTapAction: {},
                                    onShareAction: {}))
                    ],
                    footer: "Provide general access to the document selecting the required permission level."),
                CreateGeneralLinkStateModel.Section(
                    header: .init(title: "Additional links",
                                  subtitle: "(0/5)"), //TODO: -
                    cells: [
                        .createLink(.init(textString: "Create and copy", onTapAction: {}))
                    ],
                    footer: "Create additional links to share the document with different access rights.")
            ]
        )
    )
    
    static var additionalLinkState = CreateGeneralLinkStateModel(
        tableData: CreateGeneralLinkStateModel.TableData(
            sections: [
                CreateGeneralLinkStateModel.Section(
                    header: .init(title: "General links"),
                    cells: [
                        .link(.init(titleKey: "Anyone with the link", //TODO: -
                                    subTitleKey: "Expires after 7 days", //TODO: -
                                    onTapAction: {},
                                    onShareAction: {}))
                    ],
                    footer: "Provide general access to the document selecting the required permission level."),
                CreateGeneralLinkStateModel.Section(
                    header: .init(title: "Additional links",
                                  subtitle: "(0/5)",
                                  icon: UIImage(systemName: "plus")
                                 ),
                    cells: [
                        .link(.init(titleKey: "Anyone with the link", //TODO: -
                                    subTitleKey: "Expires after 7 days", //TODO: -
                                    onTapAction: {},
                                    onShareAction: {}))
                    ],
                    footer: "Create additional links to share the document with different access rights."),
            ]
        )
    )
}
