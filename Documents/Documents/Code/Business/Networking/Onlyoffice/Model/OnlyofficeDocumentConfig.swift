//
//  OnlyofficeDocument.swift
//  Documents
//
//  Created by Alexander Yuzhin on 17.08.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

// MARK: - OnlyofficeDocumentConfig

struct OnlyofficeDocumentConfig: Codable {
    var document: OnlyofficeDocument?
    var editorConfig: OnlyofficeDocumentEditorConfig?
    var token, documentType, type: String?
}

// MARK: - OnlyofficeDocument

struct OnlyofficeDocument: Codable {
    var info: OnlyofficeDocumentInfo?
    var permissions: OnlyofficeDocumentPermissions?
    var referenceData: OnlyofficeDocumentReferenceData?
    var fileType, key, title: String?
    var url: String?

    // Additional
    var supportShare, favorite, denyDownload: Bool?
}

// MARK: - OnlyofficeDocumentInfo

struct OnlyofficeDocumentInfo: Codable {
    var owner, uploaded: String?
}

// MARK: - OnlyofficeDocumentPermissions

struct OnlyofficeDocumentPermissions: Codable {
    var changeHistory, comment, download, edit: Bool?
    var fillForms, print, modifyFilter, rename: Bool?
    var review: Bool?
}

// MARK: - OnlyofficeDocumentReferenceData

struct OnlyofficeDocumentReferenceData: Codable {
    var fileKey, instanceID: String?

    enum CodingKeys: String, CodingKey {
        case fileKey
        case instanceID = "instanceId"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            fileKey = try String(container.decode(Int.self, forKey: .fileKey))
        } catch DecodingError.typeMismatch {
            fileKey = try container.decode(String.self, forKey: .fileKey)
        }

        do {
            instanceID = try String(container.decode(Int.self, forKey: .instanceID))
        } catch DecodingError.typeMismatch {
            instanceID = try container.decode(String.self, forKey: .instanceID)
        }
    }
}

// MARK: - OnlyofficeDocumentEditorConfig

struct OnlyofficeDocumentEditorConfig: Codable {
    var customization: OnlyofficeDocumentCustomization?
    var user: OnlyofficeDocumentUser?
    var callbackURL: String?
    var lang, mode: String?

    enum CodingKeys: String, CodingKey {
        case customization, user
        case callbackURL = "callbackUrl"
        case lang, mode
    }
}

// MARK: - OnlyofficeDocumentCustomization

struct OnlyofficeDocumentCustomization: Codable {
    var logo: OnlyofficeDocumentLogo?
    var about: Bool?
    var feedback: OnlyofficeDocumentFeedback?
    var mentionShare: Bool?
    var uiTheme: String?
}

// MARK: - OnlyofficeDocumentFeedback

struct OnlyofficeDocumentFeedback: Codable {
    var url: String?
    var visible: Bool?
}

// MARK: - OnlyofficeDocumentLogo

struct OnlyofficeDocumentLogo: Codable {
    var image, imageDark: String?
}

// MARK: - OnlyofficeDocumentUser

struct OnlyofficeDocumentUser: Codable {
    var id, name: String?
}
