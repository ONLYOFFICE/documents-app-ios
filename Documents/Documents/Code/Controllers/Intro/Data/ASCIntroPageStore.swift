//
//  ASCIntroPageStore.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.10.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

final class ASCIntroPageStore: ASCIntroPageStoreProtocol {
    func fetch() -> [ASCIntroPage] {
        [
            /// 1
            ASCIntroPage(
                title: NSLocalizedString("Getting started", comment: "Introduction Step One - Title"),
                subtitle: String.localizedStringWithFormat(NSLocalizedString("Welcome to %@ mobile editing suite!\nSwipe to learn more about the app.", comment: "Introduction Step One - Description"), ASCConstants.Name.appNameShort),
                image: Asset.Images.introStepOne.image
            ),
            /// 2
            ASCIntroPage(
                title: NSLocalizedString("Work with office files", comment: "Introduction Step Two - Title"),
                subtitle: NSLocalizedString("Create and edit documents with our comprehensive toolbar: work with complex objects in text documents, perform extensive calculations in spreadsheets, create stunning presentations and view PDF files with no formatting loss.", comment: "Introduction Step Two - Description"),
                image: Asset.Images.introStepTwo.image
            ),
            /// 3
            ASCIntroPage(
                title: NSLocalizedString("Third-party storage", comment: "Introduction Step Three - Title"),
                subtitle: String.localizedStringWithFormat(NSLocalizedString("Connect third-party storage\nlike Nextcloud, ownCloud, Dropbox and\nothers which use WebDAV protocol.", comment: "Introduction Step Three - Description"), ASCConstants.Name.appNameShort),
                image: Asset.Images.introStepThree.image
            ),
            /// 4
            ASCIntroPage(
                title: NSLocalizedString("Edit documents locally", comment: "Introduction Step Four - Title"),
                subtitle: NSLocalizedString("Work with documents offline.\nCreated files can later be uploaded to online portal and\nthen accessed from any other device.", comment: "Introduction Step Four - Description"),
                image: Asset.Images.introStepFour.image
            ),
            /// 5
            ASCIntroPage(
                title: NSLocalizedString("Collaborate with your team", comment: "Introduction Step Five - Title"),
                subtitle: String.localizedStringWithFormat(NSLocalizedString("In online mode, use real-time co-editing features of %@ to work on documents together with your portal members, share documents and create common storage folders.", comment: "Introduction Step Five - Description"), ASCConstants.Name.appNameShort),
                image: Asset.Images.introStepFive.image
            ),
        ]
    }
}
