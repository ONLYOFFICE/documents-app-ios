//
//  OnlyofficeEndpoints.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

class OnlyofficeAPI {
    enum Path {
        // Api version
        private static let version = "2.0"

        // Api paths
        public static let authentication = "api/\(version)/authentication"
        public static let authenticationPhone = "api/\(version)/authentication/setphone"
        public static let authenticationCode = "api/\(version)/authentication/sendsms"
        public static let serversVersion = "api/\(version)/settings/version/build"
        public static let capabilities = "api/\(version)/capabilities"
        public static let deviceRegistration = "api/\(version)/portal/mobile/registration"
        public static let peopleSelf = "api/\(version)/people/@self"
        public static let peoplePhoto = "api/\(version)/people/%@/photo"
        public static let files = "api/\(version)/files/%@"
        public static let file = "api/\(version)/files/file/%@"
        public static let folder = "api/\(version)/files/folder/%@"
        public static let favorite = "api/\(version)/files/favorites"
        public static let filesShare = "api/\(version)/files/share"
        public static let operations = "api/\(version)/files/fileops"
        public static let operationCopy = "api/\(version)/files/fileops/copy"
        public static let operationMove = "api/\(version)/files/fileops/move"
        public static let operationDelete = "api/\(version)/files/fileops/delete"
        public static let emptyTrash = "api/\(version)/files/fileops/emptytrash"
        public static let thirdParty = "api/\(version)/files/thirdparty"
        public static let thirdPartyCapabilities = "api/\(version)/files/thirdparty/capabilities"
        public static let insertFile = "api/\(version)/files/%@/insert"
        public static let uploadFile = "api/\(version)/files/%@/upload"
        public static let createFile = "api/\(version)/files/%@/file"
        public static let openEditFile = "api/\(version)/files/file/%@/openedit"
        public static let saveEditing = "api/\(version)/files/file/%@/saveediting"
        public static let startEdit = "api/\(version)/files/file/%@/startedit"
        public static let trackEdit = "api/\(version)/files/file/%@/trackeditfile"
        public static let documentService = "api/\(version)/files/docservice"
        public static let people = "api/\(version)/people"
        public static let groups = "api/\(version)/group"
        public static let shareFile = "api/\(version)/files/file/%@/share"
        public static let shareFolder = "api/\(version)/files/folder/%@/share"
        public static let forgotPassword = "api/\(version)/people/password"
        public static let deleteAccount = "api/\(version)/people/self/delete"
        public static let pushRegisterDevice = "/api/\(version)/settings/push/docregisterdevice"
        public static let pushSubscribe = "/api/\(version)/settings/push/docsubscribe"
        public static let markAsRead = "api/\(version)/files/fileops/markasread"

        enum Forlder {
            public static let root = "@root"
            public static let my = "@my"
            public static let share = "@share"
            public static let common = "@common"
            public static let projects = "@projects"
            public static let trash = "@trash"
            public static let favorites = "@favorites"
            public static let recent = "@recent"
            public static let room = "rooms"
        }
    }

    enum Endpoints {
        // MARK: Authentication

        enum Auth {
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

        enum People {
            static let me: Endpoint<OnlyofficeResponse<ASCUser>> = Endpoint<OnlyofficeResponse<ASCUser>>.make(Path.peopleSelf)
            static let all: Endpoint<OnlyofficeResponseArray<ASCUser>> = Endpoint<OnlyofficeResponseArray<ASCUser>>.make(Path.people)
            static let groups: Endpoint<OnlyofficeResponseArray<ASCGroup>> = Endpoint<OnlyofficeResponseArray<ASCGroup>>.make(Path.groups)
            static func photo(of user: ASCUser) -> Endpoint<OnlyofficeResponse<OnlyofficeUserPhoto>> {
                return Endpoint<OnlyofficeResponse<OnlyofficeUserPhoto>>.make(String(format: Path.peoplePhoto, user.userId ?? ""))
            }
        }

        // MARK: Folders

        enum Folders {
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

            static func filter(folderId: String) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.files, folderId), .get, URLEncoding.queryString)
            }
        }

        // MARK: Files

        enum Files {
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
                return Endpoint<OnlyofficeResponseType<String>>.make(String(format: Path.startEdit, file.id), .post)
            }

            static func trackEdit(file: ASCFile) -> Endpoint<OnlyofficeResponseType<Parameters>> {
                return Endpoint<OnlyofficeResponseType<Parameters>>.make(String(format: Path.trackEdit, file.id), .get, URLEncoding.default)
            }

            static let addFavorite: Endpoint<OnlyofficeResponseType<Bool>> = Endpoint<OnlyofficeResponseType<Bool>>.make(Path.favorite, .post)
            static let removeFavorite: Endpoint<OnlyofficeResponseType<Bool>> = Endpoint<OnlyofficeResponseType<Bool>>.make(Path.favorite, .delete)
        }

        // MARK: Sharing

        enum Sharing {
            static let removeSharingRights: Endpoint<OnlyofficeResponseType<Bool>> = Endpoint<OnlyofficeResponseType<Bool>>.make(Path.filesShare, .delete)
            static func entitiesShare() -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>> {
                Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>.make(Path.filesShare, .post)
            }

            static func file(file: ASCFile) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>> {
                return Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>.make(String(format: Path.shareFile, file.id), .put)
            }

            static func folder(folder: ASCFolder) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>> {
                return Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>.make(String(format: Path.shareFolder, folder.id), .put)
            }
        }

        // MARK: Operations

        enum Operations {
            static let removeEntities: Endpoint<OnlyofficeResponseArrayType<Parameters>> = Endpoint<OnlyofficeResponseArrayType<Parameters>>.make(Path.operationDelete, .put)
            static let emptyTrash: Endpoint<OnlyofficeResponseType<Parameters>> = Endpoint<OnlyofficeResponseType<Parameters>>.make(Path.emptyTrash, .put)
            static let check: Endpoint<OnlyofficeResponseArray<ASCFile>> = Endpoint<OnlyofficeResponseArray<ASCFile>>.make(Path.operationMove, .get, URLEncoding.default)
            static let copy: Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>> = Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>>.make(Path.operationCopy, .put)
            static let move: Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>> = Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>>.make(Path.operationMove, .put)
            static let list: Endpoint<OnlyofficeResponseArray<OnlyofficeFileOperation>> = Endpoint<OnlyofficeResponseArray<OnlyofficeFileOperation>>.make(Path.operations)
            static let markAsRead: Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>> = Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>>.make(Path.markAsRead, .put)
        }

        // MARK: Third-Party Integration

        enum ThirdPartyIntegration {
            static func remove(providerId: String) -> Endpoint<OnlyofficeResponseType<String>> {
                return Endpoint<OnlyofficeResponseType<String>>.make(Path.thirdParty.appendingPathComponent(providerId), .delete)
            }

            static let capabilities: Endpoint<OnlyofficeResponseType<[[String]]>> = Endpoint<OnlyofficeResponseType<[[String]]>>.make(Path.thirdPartyCapabilities)
            static let connect: Endpoint<OnlyofficeResponse<ASCFolder>> = Endpoint<OnlyofficeResponse<ASCFolder>>.make(Path.thirdParty, .post)
        }

        // MARK: Uploads

        enum Uploads {
            static func upload(in path: String) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.uploadFile, path), .post)
            }

            static func insert(in path: String) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.insertFile, path), .post, URLEncoding.default)
            }
        }

        // MARK: Settings

        enum Settings {
            static let documentService: Endpoint<OnlyofficeResponseType<Any>> = Endpoint<OnlyofficeResponseType<Any>>.make(Path.documentService, .get, URLEncoding.default)
            static let versions: Endpoint<OnlyofficeResponse<OnlyofficeVersion>> = Endpoint<OnlyofficeResponse<OnlyofficeVersion>>.make(Path.serversVersion)
            static let capabilities: Endpoint<OnlyofficeResponse<OnlyofficeCapabilities>> = Endpoint<OnlyofficeResponse<OnlyofficeCapabilities>>.make(Path.capabilities)
            static let forgotPassword: Endpoint<OnlyofficeResponseType<String>> = Endpoint<OnlyofficeResponseType<String>>.make(Path.forgotPassword, .post)
            static let deleteAccount: Endpoint<OnlyofficeResponseBase> = Endpoint<OnlyofficeResponseBase>.make(Path.deleteAccount, .put)
        }

        // MARK: Push

        enum Push {
            static let pushRegisterDevice: Endpoint<OnlyofficeResponseType<ASCPushSubscribed>> = Endpoint<OnlyofficeResponseType<ASCPushSubscribed>>.make(Path.pushRegisterDevice, .post)
            static let pushSubscribe: Endpoint<OnlyofficeResponseType<ASCPushSubscribed>> = Endpoint<OnlyofficeResponseType<ASCPushSubscribed>>.make(Path.pushSubscribe, .put)
        }
    }
}
