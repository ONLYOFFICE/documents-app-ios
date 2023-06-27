//
//  ASCMultiAccountScreenModel.swift
//  Documents-opensource
//
//  Created by Лолита Чернышева on 03.04.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

struct ASCMultiAccountScreenModel {
    struct TableData {
        enum Cell {
            case addAccount(AddAccountCellModel)
            case account(AccountCellModel)
        }

        enum Section {
            case simple([Cell])
        }

        let sections: [Section]
    }

    let title: String
    let tableData: TableData

    init(title: String, tableData: TableData) {
        self.title = title
        self.tableData = tableData
    }

    static let empty: ASCMultiAccountScreenModel = .init(title: "",
                                                         tableData: .init(sections: []))
}
