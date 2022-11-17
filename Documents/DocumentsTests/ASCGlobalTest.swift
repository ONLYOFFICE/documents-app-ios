//
//  ASCGlobalTest.swift
//  DocumentsTests
//
//  Created by Alexander Yuzhin on 17.11.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Alamofire
@testable import Documents
import XCTest

extension XCTestCase {
    typealias ASCAccount = Documents.ASCAccount
    typealias ASCEntity = Documents.ASCEntity
    typealias ASCEntityLinkMakerProtocol = Documents.ASCEntityLinkMakerProtocol
    typealias ASCFile = Documents.ASCFile
    typealias ASCFolder = Documents.ASCFolder
    typealias ASCGroup = Documents.ASCGroup
    typealias ASCOnlyofficeFileInternalLinkMaker = Documents.ASCOnlyofficeFileInternalLinkMaker
    typealias ASCShareAccess = Documents.ASCShareAccess
    typealias ASCShareSettingsAPIWorkerProtocol = Documents.ASCShareSettingsAPIWorkerProtocol
    typealias ASCSharingAddRightHoldersInteractor = Documents.ASCSharingAddRightHoldersInteractor
    typealias ASCSharingAddRightHoldersRAMDataStore = Documents.ASCSharingAddRightHoldersRAMDataStore
    typealias ASCSharingOptions = Documents.ASCSharingOptions
    typealias ASCSharingOptionsPresentationLogic = Documents.ASCSharingOptionsPresentationLogic
    typealias ASCSharingOptionsViewController = Documents.ASCSharingOptionsViewController
    typealias ASCSharingSettingsAccessNotesProviderProtocol = Documents.ASCSharingSettingsAccessNotesProviderProtocol
    typealias ASCSharingSettingsAccessViewController = Documents.ASCSharingSettingsAccessViewController
    typealias ASCUser = Documents.ASCUser
    typealias Endpoint = Documents.Endpoint
    typealias MultipartFormData = Alamofire.MultipartFormData
    typealias NetworkingError = Documents.NetworkingError
    typealias NetworkingRequestingProtocol = Documents.NetworkingRequestingProtocol
    typealias OnlyofficeAPI = Documents.OnlyofficeAPI
    typealias OnlyofficeResponseArray = Documents.OnlyofficeResponseArray
    typealias OnlyofficeShare = Documents.OnlyofficeShare
    typealias OnlyofficeShareItemRequestModel = Documents.OnlyofficeShareItemRequestModel
    typealias Parameters = Alamofire.Parameters
    typealias ShareAccessNote = Documents.ShareAccessNote
    typealias ShareSettingsAPIWorkerReason = Documents.ShareSettingsAPIWorkerReason
}
