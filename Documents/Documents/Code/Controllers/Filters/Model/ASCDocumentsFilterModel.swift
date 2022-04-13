//
//  ASCDocumentsFilterModel.swift
//  Documents
//
//  Created by Лолита Чернышева on 05.04.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

struct ASCDocumentsFilterModel {
    var filterName: String
    var isSelected: Bool
    var filter: FilterType
}

struct ASCDocumentsSectionModel {
    var sectionName: String
    var filters: [ASCDocumentsFilterModel]
}

enum FilterType: String {
    case none = "None"
    case files = "FilesOnly"
    case folders = "FoldersOnly"
    case documents = "DocumentsOnly"
    case presentations = "PresentationsOnly"
    case spreadsheets = "SpreadsheetsOnly"
    case images = "ImagesOnly"
    case user = "ByUser"
    case group = "ByDepartment"
    case archive = "ArchiveOnly"
    case byExtension = "ByExtension"
    case media = "MediaOnly"
}
