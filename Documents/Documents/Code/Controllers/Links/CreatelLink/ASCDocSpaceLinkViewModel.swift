//
//  ASCDocSpaceLinkViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 20.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

struct ASCDocSpaceLinkStateModel {
    var title = ""
    var leftNavButtonName = ""
    var tableData: TableData

    static let empty = ASCDocSpaceLinkStateModel(tableData: .init(sections: []))

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

class ASCDocSpaceLinkViewModel: ObservableObject {
    @Published var screenState: ASCDocSpaceLinkStateModel = .empty

    // MARK: temp

    init(screenState: ASCDocSpaceLinkStateModel) {
        self.screenState = screenState
    }

    func createAndCopyGeneralLink() {}
    func createAndCopyAdditionalLink() {}
}

extension ASCDocSpaceLinkStateModel {
    static var noLinksState = ASCDocSpaceLinkStateModel(
        tableData: ASCDocSpaceLinkStateModel.TableData(
            sections: [
                ASCDocSpaceLinkStateModel.Section(
                    header: .init(title: NSLocalizedString("General links", comment: "")),
                    cells: [
                        .createLink(.init(textString: NSLocalizedString("Create and copy", comment: ""), imageNames: [], onTapAction: {})),
                    ],
                    footer: NSLocalizedString("Provide general access to the document selecting the required permission level.", comment: "")
                ),
            ]
        )
    )

    static var generalLinkState = ASCDocSpaceLinkStateModel(
        tableData: ASCDocSpaceLinkStateModel.TableData(
            sections: [
                ASCDocSpaceLinkStateModel.Section(
                    header: .init(title: NSLocalizedString("General links", comment: "")),
                    cells: [
                        .link(.init(titleKey: NSLocalizedString("Anyone with the link", comment: ""),
                                    subTitleKey: NSLocalizedString("Expires after 7 days", comment: ""),
                                    onTapAction: {},
                                    onShareAction: {})),
                    ],
                    footer: NSLocalizedString("Provide general access to the document selecting the required permission level.", comment: "")
                ),
                ASCDocSpaceLinkStateModel.Section(
                    header: .init(title: NSLocalizedString("Additional links", comment: ""),
                                  subtitle: "(0/5)"),
                    cells: [
                        .createLink(.init(textString: NSLocalizedString("Create and copy", comment: ""), imageNames: [], onTapAction: {})),
                    ],
                    footer: NSLocalizedString("Create additional links to share the document with different access rights.", comment: "")
                ),
            ]
        )
    )

    static var additionalLinkState = ASCDocSpaceLinkStateModel(
        tableData: ASCDocSpaceLinkStateModel.TableData(
            sections: [
                ASCDocSpaceLinkStateModel.Section(
                    header: .init(title: NSLocalizedString("General links", comment: "")),
                    cells: [
                        .link(.init(titleKey: NSLocalizedString("Anyone with the link", comment: ""),
                                    subTitleKey: NSLocalizedString("Expires after 7 days", comment: ""),
                                    onTapAction: {},
                                    onShareAction: {})),
                    ],
                    footer: NSLocalizedString("Provide general access to the document selecting the required permission level.", comment: "")
                ),
                ASCDocSpaceLinkStateModel.Section(
                    header: .init(title: NSLocalizedString("Additional links", comment: ""),
                                  subtitle: "(0/5)",
                                  icon: UIImage(systemName: "plus")),
                    cells: [
                        .link(.init(titleKey: NSLocalizedString("Anyone with the link", comment: ""),
                                    subTitleKey: NSLocalizedString("Expires after 7 days", comment: ""),
                                    onTapAction: {},
                                    onShareAction: {})),
                    ],
                    footer: NSLocalizedString("Create additional links to share the document with different access rights.", comment: "")
                ),
            ]
        )
    )
}
