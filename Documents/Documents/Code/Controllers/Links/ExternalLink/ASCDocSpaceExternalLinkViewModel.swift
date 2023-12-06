//
//  ASCDocSpaceExternalLinkViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 28.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

struct ExternalLinkStateModel {
    var title = ""
    var leftBarButtonTitle = ""
    var rightBarButtonTitle = ""
    var tableData: TableData
    
    static let empty: ExternalLinkStateModel = .init(tableData: .init(sections: []))
    
    struct TableData {
        var sections: [Section]
    }
    
    struct Section {
        var id = UUID()
        var header: String?
        var cells: [Cell]
    }
    
    enum Cell: Identifiable {
        var id: UUID { UUID() }
        case accessRights(ImagedDetailCellModel)
        case linkLifeTime(SubTitledDetailCellModel)
        case selectable(SelectableLabledCellModel)
        case centeredLabled(ASCLabledCellModel)
        case datePicker(TimeLimitCellModel)
    }
}

extension ExternalLinkStateModel {
    static var systemLinkLifeTime: ExternalLinkStateModel = {
        let generalSection = configureGeneralSection()
        let typeSection = configureTypeSection()
        let copySection = configureCopySection()
        let deleteSection = configureDeleteSection()
        let tableData = ExternalLinkStateModel.TableData(sections: [
            generalSection, typeSection, copySection, deleteSection
        ])
        return ExternalLinkStateModel(
            title: NSLocalizedString("External link", comment: ""),
            leftBarButtonTitle: NSLocalizedString("Back", comment: ""),
            rightBarButtonTitle: NSLocalizedString("Share", comment: ""),
            tableData: tableData
        )
    }()
    
    static var customLinkLifeTime: ExternalLinkStateModel = {
        let generalSection = configureGeneralSection()
        let typeSection = configureTypeSection()
        let copySection = configureCopySection()
        let deleteSection = configureDeleteSection()
        let tableData = ExternalLinkStateModel.TableData(sections: [
            generalSection, typeSection, copySection, deleteSection
        ])
        return ExternalLinkStateModel(
            title: NSLocalizedString("External link", comment: ""),
            leftBarButtonTitle: NSLocalizedString("Back", comment: ""),
            rightBarButtonTitle: NSLocalizedString("Share", comment: ""),
            tableData: tableData
        )
        
    }()

    
    private static func configureGeneralSection() -> ExternalLinkStateModel.Section {
        .init(header: NSLocalizedString("General", comment: ""),
              cells: [
                .accessRights(.init(titleString: NSLocalizedString("Acces rights", comment: ""),
                                    image: UIImage(systemName: "eye.fill") ?? UIImage(), //TODO: -
                                    onTapAction: {
                                        //TODO: -
                                    })),
                .linkLifeTime(.init(title: NSLocalizedString("Link life time", comment: ""),
                                    subtitle: NSLocalizedString("", comment: "7 day"),
                                    onTapAction: {
                                        //TODO: -
                                    }))
              ])
    }
    
    private static func configureTypeSection() -> ExternalLinkStateModel.Section {
        .init(header: NSLocalizedString("Type", comment: ""),
              cells: [
                .selectable(.init(
                    title: NSLocalizedString("Anyone with the link", comment: ""),
                    onTapAction: {
                        //TODO: -
                    },
                    isSelected: true)), //TODO: -
                .selectable(.init(
                    title: NSLocalizedString("DoсSpace users only", comment: ""),
                    onTapAction: {
                        //TODO: -
                    },
                    isSelected: true)) //TODO: -
              ])
    }
    
    private static func configureCopySection() -> ExternalLinkStateModel.Section {
        .init(cells: [
            .centeredLabled(.init(
                textString: NSLocalizedString("Copy link", comment: ""),
                cellType: .standard,
                textAlignment: .center,
                onTapAction: {
                //TODO: -
            }))
        ])
    }
    
    private static func configureDeleteSection() -> ExternalLinkStateModel.Section {
        .init(cells: [
            .centeredLabled(.init(
                textString: NSLocalizedString("Delete link", comment: ""),
                cellType: .deletable,
                textAlignment: .center,
                onTapAction: {
                    //TODO: -
                }))
        ])
    }
    
    private static func configureTimeLimitSection() -> ExternalLinkStateModel.Section {
        .init(header: NSLocalizedString("Time limit", comment: ""),
              cells: [
                .datePicker(.init(
                    title: NSLocalizedString("Valid through", comment: "")))
              ])
    }
}

class ASCDocSpaceExternalLinkViewModel: ObservableObject {
    
    
}


