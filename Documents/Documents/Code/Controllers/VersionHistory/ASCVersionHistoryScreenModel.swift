//
//  ASCVersionHistoryScreenModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 30.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

struct ASCVersionHistoryScreenModel {
    var activeAlert: VersionAlertType?
    var isShowingRestoreAlert: Bool = false
    var versionToRestore: VersionViewModel?
    var isShowingDeleteAlert: Bool = false
    var versionToDelete: VersionViewModel?
    var showEditCommentAlert: Bool = false
    var versionToEdit: VersionViewModel?
}
