//
//  OnlyofficeEndpoints.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire

class OnlyofficeAPI {

    struct Path {
        // Api version
        static private let version = "2.0"
        
        // Api paths
        static public let authentication         = "api/\(version)/authentication"
        static public let authenticationPhone    = "api/\(version)/authentication/setphone"
        static public let authenticationCode     = "api/\(version)/authentication/sendsms"
        static public let serversVersion         = "api/\(version)/settings/version/build"
        static public let capabilities           = "api/\(version)/capabilities"
        static public let deviceRegistration     = "api/\(version)/portal/mobile/registration"
        static public let peopleSelf             = "api/\(version)/people/@self"
        static public let peoplePhoto            = "api/\(version)/people/%@/photo"
        static public let files                  = "api/\(version)/files/%@"
        static public let file                   = "api/\(version)/files/file/%@"
        static public let folder                 = "api/\(version)/files/folder/%@"
        static public let favorite               = "api/\(version)/files/favorites"
        static public let filesShare             = "api/\(version)/files/share"
        static public let operations             = "api/\(version)/files/fileops"
        static public let operationCopy          = "api/\(version)/files/fileops/copy"
        static public let operationMove          = "api/\(version)/files/fileops/move"
        static public let operationDelete        = "api/\(version)/files/fileops/delete"
        static public let emptyTrash             = "api/\(version)/files/fileops/emptytrash"
        static public let thirdParty             = "api/\(version)/files/thirdparty"
        static public let thirdPartyCapabilities = "api/\(version)/files/thirdparty/capabilities"
        static public let insertFile             = "api/\(version)/files/%@/insert"
        static public let uploadFile             = "api/\(version)/files/%@/upload"
        static public let createFile             = "api/\(version)/files/%@/file"
        static public let openEditFile           = "api/\(version)/files/file/%@/openedit"
        static public let saveEditing            = "api/\(version)/files/file/%@/saveediting"
        static public let startEdit              = "api/\(version)/files/file/%@/startedit"
        static public let trackEdit              = "api/\(version)/files/file/%@/trackeditfile"
        static public let documentService        = "api/\(version)/files/docservice"
        static public let people                 = "api/\(version)/people"
        static public let groups                 = "api/\(version)/group"
        static public let shareFile              = "api/\(version)/files/file/%@/share"
        static public let shareFolder            = "api/\(version)/files/folder/%@/share"
        static public let forgotPassword         = "api/\(version)/people/password"
        
        struct Forlder {
            static public let root      = "@root"
            static public let my        = "@my"
            static public let share     = "@share"
            static public let common    = "@common"
            static public let projects  = "@projects"
            static public let trash     = "@trash"
            static public let favorites = "@favorites"
            static public let recent    = "@recent"
        }
    }

    struct Endpoints {
        
        // MARK: Authentication
        
        struct Auth {
            static func authentication(with code: String? = nil) -> Endpoint<OnlyofficeResponse<OnlyofficeAuth>> {
                var path = Path.authentication
                
                if let code = code {
                    path = "\(Path.authentication)/\(code)"
                }
                
                return Endpoint<OnlyofficeResponse<OnlyofficeAuth>>.make(path, .post)
            }
            static let deviceRegistration: Endpoint<Parameters> = Endpoint<Parameters>.make(Path.deviceRegistration, .post)
            static let sendCode: Endpoint<Parameters> = Endpoint<Parameters>.make(Path.authenticationCode, .post)
            static let sendPhone: Endpoint<Parameters> = Endpoint<Parameters>.make(Path.authenticationPhone, .post)
        }
        
        // MARK: People
        
        struct People {
            static let me: Endpoint<OnlyofficeResponse<ASCUser>> = Endpoint<OnlyofficeResponse<ASCUser>>.make(Path.peopleSelf)
            static let all: Endpoint<OnlyofficeResponseArray<ASCUser>> = Endpoint<OnlyofficeResponseArray<ASCUser>>.make(Path.people)
            static let groups: Endpoint<OnlyofficeResponseArray<ASCGroup>> = Endpoint<OnlyofficeResponseArray<ASCGroup>>.make(Path.groups)
            static func photo(of user: ASCUser) -> Endpoint<OnlyofficeResponse<OnlyofficeUserPhoto>> {
                return Endpoint<OnlyofficeResponse<OnlyofficeUserPhoto>>.make(String(format: Path.peoplePhoto, user.userId ?? ""))
            }
        }
        
        // MARK: Folders
        
        struct Folders {
            static let roots: Endpoint<OnlyofficeResponseArray<OnlyofficePath>> = Endpoint<OnlyofficeResponseArray<OnlyofficePath>>.make(String(format: Path.files, Path.Forlder.root))
            static func path(of folder: ASCFolder) -> Endpoint<OnlyofficeResponse<OnlyofficePath>> {
                return Endpoint<OnlyofficeResponse<OnlyofficePath>>.make(String(format: Path.files, folder.id), .get, URLEncoding.default)
            }
            static func info(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.folder, folder.id))
            }
            static func update(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.folder, folder.id), .put)
            }
            static func create(in folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.folder, folder.id), .post)
            }
            static func delete(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.folder, folder.id), .delete)
            }
        }
        
        // MARK: Files
        
        struct Files {
            static func info(file: ASCFile) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.file, file.id))
            }
            static func update(file: ASCFile) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.file, file.id), .put)
            }
            static func saveEditing(file: ASCFile) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.saveEditing, file.id), .put)
            }
            static func create(in folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.createFile, folder.id), .post)
            }
            static func delete(file: ASCFile) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.file, file.id), .delete)
            }
            static func openEdit(file: ASCFile) -> Endpoint<OnlyofficeResponseType<Parameters>> {
                return Endpoint<OnlyofficeResponseType<Parameters>>.make(String(format: Path.openEditFile, file.id))
            }
            static func startEdit(file: ASCFile) -> Endpoint<OnlyofficeResponseType<String>> {
                return Endpoint<OnlyofficeResponseType<String>>.make(String(format: Path.startEdit, file.id), .post, URLEncoding.default)
            }
            static func trackEdit(file: ASCFile) -> Endpoint<OnlyofficeResponseType<Parameters>> {
                return Endpoint<OnlyofficeResponseType<Parameters>>.make(String(format: Path.trackEdit, file.id), .get, URLEncoding.default)
            }
            static let addFavorite: Endpoint<OnlyofficeResponseType<Bool>> = Endpoint<OnlyofficeResponseType<Bool>>.make(Path.favorite, .post)
            static let removeFavorite: Endpoint<OnlyofficeResponseType<Bool>> = Endpoint<OnlyofficeResponseType<Bool>>.make(Path.favorite, .delete)
        }
        
        // MARK: Sharing
        
        struct Sharing {
            static let removeSharingRights: Endpoint<OnlyofficeResponseType<Bool>> = Endpoint<OnlyofficeResponseType<Bool>>.make(Path.filesShare, .delete)
            static func file(file: ASCFile) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>> {
                return Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>.make(String(format: Path.shareFile, file.id), .put)
            }
            static func folder(folder: ASCFolder) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>> {
                return Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>.make(String(format: Path.shareFolder, folder.id), .put)
            }
        }
        
        // MARK: Operations
        
        struct Operations {
            static let removeEntities: Endpoint<OnlyofficeResponseArrayType<Parameters>> = Endpoint<OnlyofficeResponseArrayType<Parameters>>.make(Path.operationDelete, .put)
            static let emptyTrash: Endpoint<OnlyofficeResponseType<Parameters>> = Endpoint<OnlyofficeResponseType<Parameters>>.make(Path.emptyTrash, .put)
            static let check: Endpoint<OnlyofficeResponseArray<ASCFile>> = Endpoint<OnlyofficeResponseArray<ASCFile>>.make(Path.operationMove, .get, URLEncoding.default)
            static let copy: Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>> = Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>>.make(Path.operationCopy, .put)
            static let move: Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>> = Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>>.make(Path.operationMove, .put)
            static let list: Endpoint<OnlyofficeResponseArray<OnlyofficeFileOperation>> = Endpoint<OnlyofficeResponseArray<OnlyofficeFileOperation>>.make(Path.operations)
        }
        
        // MARK: Third-Party Integration
        
        struct ThirdPartyIntegration {
            static func remove(providerId: String) -> Endpoint<OnlyofficeResponseType<String>> {
                return Endpoint<OnlyofficeResponseType<String>>.make(Path.thirdParty.appendingPathComponent(providerId), .delete)
            }
            static let capabilities: Endpoint<OnlyofficeResponseType<[[String]]>> = Endpoint<OnlyofficeResponseType<[[String]]>>.make(Path.thirdPartyCapabilities)
            static let connect: Endpoint<OnlyofficeResponse<ASCFolder>> = Endpoint<OnlyofficeResponse<ASCFolder>>.make(Path.thirdParty, .post)
        }
        
        // MARK: Uploads
        
        struct Uploads {
            static func upload(in path: String) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.uploadFile, path), .post)
            }
            static func insert(in path: String) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.insertFile, path), .post, URLEncoding.default)
            }
        }
        
        // MARK: Settings
        
        struct Settings {
            static let documentService: Endpoint<OnlyofficeResponseType<Any>> = Endpoint<OnlyofficeResponseType<Any>>.make(Path.documentService, .get, URLEncoding.default)
            static let versions: Endpoint<OnlyofficeResponse<OnlyofficeVersion>> = Endpoint<OnlyofficeResponse<OnlyofficeVersion>>.make(Path.serversVersion)
            static let capabilities: Endpoint<OnlyofficeResponse<OnlyofficeCapabilities>> = Endpoint<OnlyofficeResponse<OnlyofficeCapabilities>>.make(Path.capabilities)
            static let forgotPassword: Endpoint<OnlyofficeResponseType<String>> = Endpoint<OnlyofficeResponseType<String>>.make(Path.forgotPassword, .post)
        }
    }

}
