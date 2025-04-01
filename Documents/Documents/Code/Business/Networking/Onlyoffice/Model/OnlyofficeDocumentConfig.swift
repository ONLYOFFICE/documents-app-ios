//
//  OnlyofficeDocumentConfig.swift
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
    var token: String?
    var documentType: String?
    var type: String?
    var startFilling: Bool?
    var fillingSessionId: String?
    var url: String?
    var size: Int?
    var updated: Int?
    var fileId: String?
    var canShareable: Bool?
    var editorType: Int?
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
    var changeHistory, chat, comment, download, edit, copy: Bool?
    var fillForms, print, modifyFilter, rename, review: Bool?
    var commentGroups: OnlyofficeDocumentCommentGroupsConfig?
    var deleteCommentAuthorOnly, editCommentAuthorOnly, modifyContentControl,
        protect: Bool?
    var reviewGroups: [String]?
    var userInfoGroups: [String]?
}

struct OnlyofficeDocumentCommentGroupsConfig: Codable {
    var edit, remove, view: [String]?
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

// MARK: - OnlyofficeDocumentSubmitForm

struct OnlyofficeDocumentSubmitForm: Codable {
    var visible: Bool
    var resultMessage: String?

    enum CodingKeys: String, CodingKey {
        case visible, resultMessage
    }
}

// MARK: - OnlyofficeDocumentCustomization

struct OnlyofficeDocumentCustomization: Codable {
    var logo: OnlyofficeDocumentLogo?
    var about: Bool?
    var anonymous: OnlyofficeDocumentAnonymous?
    var feedback: OnlyofficeDocumentFeedback?
    var forcesave: Bool?
    var mentionShare: Bool?
    var uiTheme: String?
    var submitForm: OnlyofficeDocumentSubmitForm?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        logo = try? container.decode(OnlyofficeDocumentLogo.self, forKey: .logo)
        about = try? container.decode(Bool.self, forKey: .about)
        anonymous = try? container.decode(OnlyofficeDocumentAnonymous.self, forKey: .anonymous)
        feedback = try? container.decode(OnlyofficeDocumentFeedback.self, forKey: .feedback)
        forcesave = try? container.decode(Bool.self, forKey: .forcesave)
        mentionShare = try? container.decode(Bool.self, forKey: .mentionShare)
        uiTheme = try? container.decode(String.self, forKey: .uiTheme)

        if container.contains(.submitForm) {
            do {
                submitForm = try container.decode(OnlyofficeDocumentSubmitForm.self, forKey: .submitForm)
            } catch DecodingError.typeMismatch {
                // Old version, just Bool
                if let visible = try? container.decode(Bool.self, forKey: .submitForm) {
                    submitForm = OnlyofficeDocumentSubmitForm(visible: visible, resultMessage: nil)
                }
            }
        } else {
            submitForm = nil
        }
    }
}

// MARK: - OnlyofficeDocumentFeedback

struct OnlyofficeDocumentFeedback: Codable {
    var url: String?
    var visible: Bool?
}

// MARK: - OnlyofficeDocumentLogo

struct OnlyofficeDocumentLogo: Codable {
    var image, imageDark, imageEmbedded, url: String?
    var visible: Bool?
}

// MARK: - OnlyofficeDocumentUser

struct OnlyofficeDocumentUser: Codable {
    var id, name, image: String?
    var roles: [String]?
}

// MARK: - OnlyofficeDocumentAnonymous

struct OnlyofficeDocumentAnonymous: Codable {
    var request: Bool?
    var label: String?
}
