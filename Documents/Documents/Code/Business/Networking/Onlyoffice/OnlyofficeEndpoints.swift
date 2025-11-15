//
//  OnlyofficeEndpoints.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

enum OnlyofficeAPI {
    enum Path {
        // Api version
        private static let version = "2.0"

        // Api paths

        static let authentication = "api/\(version)/authentication"
        static let authenticationPhone = "api/\(version)/authentication/setphone"
        static let authenticationCode = "api/\(version)/authentication/sendsms"
        static let serversVersion = "api/\(version)/settings/version/build"
        static let capabilities = "api/\(version)/capabilities"
        static let deviceRegistration = "api/\(version)/portal/mobile/registration"
        static let peopleSelf = "api/\(version)/people/@self"
        static let peoplePhoto = "api/\(version)/people/%@/photo"
        static let files = "api/\(version)/files/%@"
        static let file = "api/\(version)/files/file/%@"
        static let fileLinks = "api/\(version)/files/file/%@/links"
        static let createAndCopyFileLink = "api/\(version)/files/file/%@/link"
        static let folder = "api/\(version)/files/folder/%@"
        static let folderLinks = "api/\(version)/files/folder/%@/links"
        static let favorite = "api/\(version)/files/favorites"
        static let filesShare = "api/\(version)/files/share"
        static let filesSharePassword = "api/\(version)/files/share/%@/password"
        static let filesOrder = "api/\(version)/files/order"
        static let operations = "api/\(version)/files/fileops"
        static let operationsTerminate = "api/\(version)/files/fileops/terminate"
        static let operationCopy = "api/\(version)/files/fileops/copy"
        static let operationMove = "api/\(version)/files/fileops/move"
        static let operationDelete = "api/\(version)/files/fileops/delete"
        static let operationDownload = "api/\(version)/files/fileops/bulkdownload"
        static let operationRoomDuplicate = "api/\(version)/files/fileops/duplicate"
        static let operationRoomIndexExport = "api/\(version)/files/rooms/indexexport"
        static let operationSaveRoomAsTemplate = "api/\(version)/files/roomtemplate"
        static let roomTemplateStatus = "api/\(version)/files/roomtemplate/status"
        static let roomFromTemplate = "api/\(version)/files/rooms/fromTemplate"
        static let roomFromTemplateStatus = "api/\(version)/files/rooms/fromTemplate/status"
        static let emptyTrash = "api/\(version)/files/fileops/emptytrash"
        static let thirdParty = "api/\(version)/files/thirdparty"
        static let logos = "api/\(version)/files/logos"
        static let thirdPartyCapabilities = "api/\(version)/files/thirdparty/capabilities"
        static let insertFile = "api/\(version)/files/%@/insert"
        static let uploadFile = "api/\(version)/files/%@/upload"
        static let createFile = "api/\(version)/files/%@/file"
        static let openEditFile = "api/\(version)/files/file/%@/openedit"
        static let saveEditing = "api/\(version)/files/file/%@/saveediting"
        static let startEdit = "api/\(version)/files/file/%@/startedit"
        static let trackEdit = "api/\(version)/files/file/%@/trackeditfile"
        static let documentService = "api/\(version)/files/docservice"
        static let people = "api/\(version)/people"
        static let peopleFilter = "api/\(version)/people/filter"
        static let peopleRoom = "api/\(version)/people/room/%@"
        static let groups = "api/\(version)/group"
        static let shareFile = "api/\(version)/files/file/%@/share"
        static let sharedUsers = "api/\(version)/files/file/%@/sharedusers"
        static let shareFolder = "api/\(version)/files/folder/%@/share"
        static let shareRoom = "api/\(version)/files/rooms/%@/share"
        static let changeOwner = "api/\(version)/files/owner"
        static let forgotPassword = "api/\(version)/people/password"
        static let deleteAccount = "api/\(version)/people/self/delete"
        static let pushRegisterDevice = "/api/\(version)/settings/push/docregisterdevice"
        static let pushSubscribe = "/api/\(version)/settings/push/docsubscribe"
        static let markAsRead = "api/\(version)/files/fileops/markasread"
        static let paymentQuota = "api/\(version)/portal/payment/quota"
        static let paymentQuotaSettings = "api/\(version)/settings/roomquotasettings"
        static let rooms = "api/\(version)/files/rooms"
        static let roomsThirdparty = "api/\(version)/files/rooms/thirdparty/%@"
        static let room = "api/\(version)/files/rooms/%@"
        static let roomPin = "api/\(version)/files/rooms/%@/pin"
        static let roomUnpin = "api/\(version)/files/rooms/%@/unpin"
        static let roomArchive = "api/\(version)/files/rooms/%@/archive"
        static let roomUnarchive = "api/\(version)/files/rooms/%@/unarchive"
        static let tags = "api/\(version)/files/tags"
        static let roomTags = "api/\(version)/files/rooms/%@/tags"
        static let roomLogo = "api/\(version)/files/rooms/%@/logo"
        static let roomLink = "api/\(version)/files/rooms/%@/link"
        static let roomLinks = "api/\(version)/files/rooms/%@/links"
        static let roomReorder = "api/\(version)/files/rooms/%@/reorder"
        static let roomIndexExport = "api/\(version)/files/rooms/%@/indexexport"
        static let disableNotifications = "api/\(version)/settings/notification/rooms"
        static let fillFormDidSend = "api/\(version)/files/file/fillresult"
        static let fillingStatus = "api/\(version)/files/file/%@/formroles"
        static let formRoleMapping = "api/\(version)/files/file/%@/formrolemapping"
        static let manageFormFilling = "api/\(version)/files/file/%@/manageformfilling"
        static let fileVersionHistory = "api/\(version)/files/file/%@/history"
        static let deleteFileVersion = "api/\(version)/files/fileops/deleteversion"
        static let editComment = "api/\(version)/files/file/%@/comment"
        static let customFilter = "api/\(version)/files/file/%@/customfilter"
        static let publicRoomTemplate = "api/\(version)/files/roomtemplate/public"
        static let isTemplatePublic = "api/\(version)/files/roomtemplate/%@/public"

        static let defaultGeneralLink = "rooms/shared/filter"

        enum Folder {
            static let root = "@root"
            static let my = "@my"
            static let share = "@share"
            static let common = "@common"
            static let projects = "@projects"
            static let trash = "@trash"
            static let favorites = "@favorites"
            static let recent = "@recent"
            static let room = "rooms"
            static let recentRaw = "recent" // Recently accessible via link
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
            static let filter: Endpoint<OnlyofficeResponseArray<ASCUser>> =
                Endpoint<OnlyofficeResponseArray<ASCUser>>.make(Path.peopleFilter, .get, URLEncoding.default)
            static let groups: Endpoint<OnlyofficeResponseArray<ASCGroup>> = Endpoint<OnlyofficeResponseArray<ASCGroup>>.make(Path.groups)

            static func room(roomId: String) -> Endpoint<OnlyofficeResponseArray<ASCUser>> { Endpoint<OnlyofficeResponseArray<ASCUser>>
                .make(
                    String(format: Path.peopleRoom, roomId),
                    .get,
                    URLEncoding.default
                )
            }

            static func photo(of user: ASCUser) -> Endpoint<OnlyofficeResponse<OnlyofficeUserPhoto>> {
                return Endpoint<OnlyofficeResponse<OnlyofficeUserPhoto>>.make(String(format: Path.peoplePhoto, user.userId ?? ""))
            }
        }

        // MARK: Folders

        enum Folders {
            static let roots: Endpoint<OnlyofficeResponseArray<OnlyofficePath>> = Endpoint<OnlyofficeResponseArray<OnlyofficePath>>.make(String(format: Path.files, Path.Folder.root))
            static func path(of folder: ASCFolder) -> Endpoint<OnlyofficeResponse<OnlyofficePath>> {
                return Endpoint<OnlyofficeResponse<OnlyofficePath>>.make(String(format: Path.files, folder.id), .get, URLEncoding.default)
            }

            static func roomsPath() -> Endpoint<OnlyofficeResponse<OnlyofficePath>> {
                return Endpoint<OnlyofficeResponse<OnlyofficePath>>.make(String(format: Path.room, ""), .get, URLEncoding.default)
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
            static func deleteLink(folder: ASCFolder) -> Endpoint<OnlyofficeResponseBase> {
                return Endpoint<OnlyofficeResponseBase>.make(String(format: Path.folderLinks, folder.id), .put)
            }
            
            static func getLinks(folder: ASCFolder) -> Endpoint<OnlyofficeResponseArrayCodable<SharingInfoLinkResponseModel>> {
                return Endpoint<OnlyofficeResponseArrayCodable<SharingInfoLinkResponseModel>>.make(String(format: Path.folderLinks, folder.id), .get, URLEncoding.default)
            }
            
            static func users(folder: ASCFolder) -> Endpoint<OnlyofficeResponseArrayCodable<RoomUsersResponseModel>> {
                return Endpoint<OnlyofficeResponseArrayCodable<RoomUsersResponseModel>>.make(String(format: Path.shareFolder, folder.id), .get, URLEncoding.default)
            }
        }

        // MARK: Tags

        enum Tags {
            static func create() -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<OnlyofficeResponseBase>>.make(Path.tags, .post)
            }

            static func addToRoom(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<OnlyofficeResponseBase>>.make(String(format: Path.roomTags, folder.id), .put)
            }

            static func deleteFromRoom(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<OnlyofficeResponseBase>>.make(String(format: Path.roomTags, folder.id), .delete)
            }

            static func getList() -> Endpoint<OnlyofficeResponseArrayCodable<String>> {
                return Endpoint<OnlyofficeResponseArrayCodable<String>>.make(Path.tags, .get, URLEncoding.queryString)
            }
        }

        // MARK: Rooms

        enum Rooms {
            static let paymentQuota: Endpoint<OnlyofficeResponse<ASCPaymentQuota>> = Endpoint<OnlyofficeResponse<ASCPaymentQuota>>.make(Path.paymentQuota, .get)

            static let roomQuotaSettings: Endpoint<OnlyofficeResponse<ASCPaymentQuotaSettings>> = Endpoint<OnlyofficeResponse<ASCPaymentQuotaSettings>>.make(Path.paymentQuotaSettings, .post)

            static func createThirdparty(providerId: String) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.roomsThirdparty, providerId), .post)
            }

            static func rooms() -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(Path.rooms, .get, URLEncoding.default)
            }

            static func roomTemplates() -> Endpoint<OnlyofficeResponse<ASCRoomTemplate>> {
                return Endpoint<OnlyofficeResponse<ASCRoomTemplate>>.make(Path.rooms, .get, URLEncoding.default)
            }

            static func create() -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(Path.rooms, .post)
            }

            static func pin(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.roomPin, folder.id), .put)
            }

            static func unpin(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.roomUnpin, folder.id), .put)
            }

            static func archive(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>> {
                return Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>>.make(String(format: Path.roomArchive, folder.id), .put)
            }

            static func unarchive(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.roomUnarchive, folder.id), .put)
            }

            static func setLogo(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.roomLogo, folder.id), .post)
            }

            static func deleteLogo(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.roomLogo, folder.id), .delete)
            }

            static func getLink(folder: ASCFolder) -> Endpoint<OnlyofficeResponseCodable<SharingInfoLinkResponseModel>> {
                return Endpoint<OnlyofficeResponseCodable<SharingInfoLinkResponseModel>>.make(String(format: Path.roomLink, folder.id), .get, URLEncoding.default)
            }

            static func removeLink(folder: ASCFolder) -> Endpoint<OnlyofficeResponseBase> {
                return Endpoint<OnlyofficeResponseBase>.make(String(format: Path.roomLinks, folder.id), .put)
            }

            static func revokeLink(folder: ASCFolder) -> Endpoint<OnlyofficeResponseBase> {
                return Endpoint<OnlyofficeResponseBase>.make(String(format: Path.roomLinks, folder.id), .put)
            }

            static func setLinks(folder: ASCFolder) -> Endpoint<OnlyofficeResponseCodable<SharingInfoLinkResponseModel>> {
                return Endpoint<OnlyofficeResponseCodable<SharingInfoLinkResponseModel>>.make(String(format: Path.roomLinks, folder.id), .put)
            }

            static func getLinks(room: ASCFolder) -> Endpoint<OnlyofficeResponseArrayCodable<SharingInfoLinkResponseModel>> {
                return Endpoint<OnlyofficeResponseArrayCodable<SharingInfoLinkResponseModel>>.make(String(format: Path.roomLinks, room.id), .get, URLEncoding.default)
            }

            static func users(room: ASCFolder) -> Endpoint<OnlyofficeResponseArrayCodable<RoomUsersResponseModel>> {
                return Endpoint<OnlyofficeResponseArrayCodable<RoomUsersResponseModel>>.make(String(format: Path.shareRoom, room.id), .get, URLEncoding.default)
            }

            static func update(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.room, folder.id), .put)
            }

            static func toggleRoomNotifications(room: ASCFolder) -> Endpoint<OnlyofficeResponseCodable<RoomNotificationsResponceModel>> {
                return Endpoint<OnlyofficeResponseCodable<RoomNotificationsResponceModel>>.make(String(format: Path.disableNotifications), .post)
            }

            static func roomReorder(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<ASCFolder>> {
                return Endpoint<OnlyofficeResponse<ASCFolder>>.make(String(format: Path.roomReorder, folder.id), .put)
            }

            static func roomIndexExport(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<OnlyofficeRoomIndexExportOperation>> {
                return Endpoint<OnlyofficeResponse<OnlyofficeRoomIndexExportOperation>>.make(String(format: Path.roomIndexExport, folder.id), .post)
            }

            static func getRoomTemplateAccessList(template: ASCFolder) -> Endpoint<OnlyofficeResponseArray<ASCTemplateAccessModel>> {
                return Endpoint<OnlyofficeResponseArray<ASCTemplateAccessModel>>.make(String(format: Path.shareRoom, template.id), .get)
            }

            static func setRoomTemplateAccess(template: ASCFolder) -> Endpoint<OnlyofficeResponse<OnlyofficeInviteResponseModel>> {
                return Endpoint<OnlyofficeResponse<OnlyofficeInviteResponseModel>>.make(String(format: Path.shareRoom, template.id), .put)
            }

            static func setRoomTemplateAsPublic() -> Endpoint<OnlyofficeResponseBase> {
                return Endpoint<OnlyofficeResponseBase>.make(String(format: Path.publicRoomTemplate), .put)
            }

            static func getRoomTemplateIsPiblic(template: ASCFolder) -> Endpoint<OnlyofficeResponseType<Bool>> {
                return Endpoint<OnlyofficeResponseType<Bool>>.make(String(format: Path.isTemplatePublic, template.id), .get)
            }
        }

        // MARK: Files

        enum Files {
            static func fillFormDidSend() -> Endpoint<OnlyofficeResponse<CompletedFormResponceModel>> {
                return Endpoint<OnlyofficeResponse<CompletedFormResponceModel>>.make(String(format: Path.fillFormDidSend), .get, URLEncoding.queryString)
            }

            static func info(file: ASCFile) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.file, file.id))
            }

            static func getLinksShort(file: ASCFile) -> Endpoint<OnlyofficeResponseArrayCodable<SharedSettingsLinkResponceModel>> {
                return Endpoint<OnlyofficeResponseArrayCodable<SharedSettingsLinkResponceModel>>.make(String(format: Path.fileLinks, file.id), .get)
            }
            
            static func getLinks(file: ASCFile) -> Endpoint<OnlyofficeResponseArrayCodable<SharingInfoLinkResponseModel>> {
                return Endpoint<OnlyofficeResponseArrayCodable<SharingInfoLinkResponseModel>>.make(String(format: Path.fileLinks, file.id), .get)
            }

            static func customFilter(file: ASCFile) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.customFilter, file.id), .put)
            }

            static func createAndCopyLink(file: ASCFile, method: HTTPMethod) -> Endpoint<OnlyofficeResponseCodable<SharedSettingsLinkResponceModel>> {
                return Endpoint<OnlyofficeResponseCodable<SharedSettingsLinkResponceModel>>.make(String(format: Path.createAndCopyFileLink, file.id), method)
            }

            static func setLinkAccess(file: ASCFile) -> Endpoint<OnlyofficeResponseCodable<SharedSettingsLinkResponceModel>> {
                return Endpoint<OnlyofficeResponseCodable<SharedSettingsLinkResponceModel>>.make(String(format: Path.fileLinks, file.id), .put)
            }

            static func regenerateLink(file: ASCFile) -> Endpoint<OnlyofficeResponseCodable<SharedSettingsLinkResponceModel>> {
                return Endpoint<OnlyofficeResponseCodable<SharedSettingsLinkResponceModel>>.make(String(format: Path.fileLinks, file.id), .put)
            }

            static func addLink(file: ASCFile) -> Endpoint<OnlyofficeResponseCodable<SharedSettingsLinkResponceModel>> {
                return Endpoint<OnlyofficeResponseCodable<SharedSettingsLinkResponceModel>>.make(String(format: Path.fileLinks, file.id), .put)
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
            
            static func deleteLink(file: ASCFile) -> Endpoint<OnlyofficeResponseBase> {
                return Endpoint<OnlyofficeResponseBase>.make(String(format: Path.fileLinks, file.id), .put)
            }

            static func openEdit(file: ASCFile) -> Endpoint<OnlyofficeResponseCodable<OnlyofficeDocumentConfig>> {
                guard let requestToken = file.requestToken else {
                    return Endpoint<OnlyofficeResponseCodable<OnlyofficeDocumentConfig>>.make(String(format: Path.openEditFile, file.id), .get, URLEncoding.default)
                }
                return Endpoint<OnlyofficeResponseCodable<OnlyofficeDocumentConfig>>.make(
                    String(format: Path.openEditFile, file.id),
                    .get,
                    URLEncoding.default,
                    ["Request-Token": requestToken]
                )
            }

            static func startEdit(file: ASCFile) -> Endpoint<OnlyofficeResponseType<String>> {
                return Endpoint<OnlyofficeResponseType<String>>.make(String(format: Path.startEdit, file.id), .post)
            }

            static func trackEdit(file: ASCFile) -> Endpoint<OnlyofficeResponseType<Parameters>> {
                return Endpoint<OnlyofficeResponseType<Parameters>>.make(String(format: Path.trackEdit, file.id), .get, URLEncoding.default)
            }

            static func getFillingStatus(file: ASCFile) -> Endpoint<OnlyofficeResponseArrayCodable<VDRFillingStatusResponceModel>> {
                return Endpoint<OnlyofficeResponseArrayCodable<VDRFillingStatusResponceModel>>.make(String(format: Path.fillingStatus, file.id), .get, URLEncoding.default)
            }

            static func mapFormRolesToUsers(file: ASCFile) -> Endpoint<OnlyofficeResponseBase> {
                return Endpoint<OnlyofficeResponseBase>.make(String(format: Path.formRoleMapping, file.id), .post)
            }

            static func manageFormFilling(file: ASCFile) -> Endpoint<OnlyofficeResponseBase> {
                Endpoint<OnlyofficeResponseBase>.make(String(format: Path.manageFormFilling, file.id), .put)
            }

            static func getVersionHistory(file: ASCFile) -> Endpoint<OnlyofficeResponseArray<ASCFile>> {
                return Endpoint<OnlyofficeResponseArray<ASCFile>>.make(String(format: Path.fileVersionHistory, file.id), .get, URLEncoding.default)
            }

            static func restoreFileVersion(file: ASCFile) -> Endpoint<OnlyofficeResponse<ASCFile>> {
                return Endpoint<OnlyofficeResponse<ASCFile>>.make(String(format: Path.file, file.id), .put)
            }

            static func editComment(file: ASCFile) -> Endpoint<OnlyofficeResponseType<String>> {
                return Endpoint<OnlyofficeResponseType<String>>.make(String(format: Path.editComment, file.id), .put)
            }

            static let addFavorite: Endpoint<OnlyofficeResponseType<Bool>> = Endpoint<OnlyofficeResponseType<Bool>>.make(Path.favorite, .post)
            static let removeFavorite: Endpoint<OnlyofficeResponseType<Bool>> = Endpoint<OnlyofficeResponseType<Bool>>.make(Path.favorite, .delete)
            static let order: Endpoint<OnlyofficeResponseBase> = Endpoint<OnlyofficeResponseBase>.make(Path.filesOrder, .put)
        }

        // MARK: Sharing

        enum Sharing {
            static let removeSharingRights: Endpoint<OnlyofficeResponseType<Bool>> = Endpoint<OnlyofficeResponseType<Bool>>.make(Path.filesShare, .delete)
            static func entitiesShare() -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>> {
                Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>.make(Path.filesShare, .post)
            }

            static func changeOwner() -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>> {
                Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>.make(Path.changeOwner, .post)
            }

            static func fileShare(file: ASCFile, method: HTTPMethod) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>> {
                return Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>.make(String(format: Path.shareFile, file.id), method)
            }
            
            static func fileUsers(file: ASCFile, method: HTTPMethod) -> Endpoint<OnlyofficeResponseArrayCodable<RoomUsersResponseModel>> {
                return Endpoint<OnlyofficeResponseArrayCodable<RoomUsersResponseModel>>.make(String(format: Path.shareFile, file.id), method)
            }

            static func users(fileId: String, method: HTTPMethod) -> Endpoint<OnlyofficeResponseArray<OnlyofficeSharedUser>> {
                return Endpoint<OnlyofficeResponseArray<OnlyofficeSharedUser>>.make(String(format: Path.sharedUsers, fileId), method)
            }

            static func password(token: String) -> Endpoint<OnlyofficeResponseCodable<SharePasswordResponseModel>> {
                return Endpoint<OnlyofficeResponseCodable<SharePasswordResponseModel>>.make(String(format: Path.filesSharePassword, token), .post)
            }

            static func folder(folder: ASCFolder, method: HTTPMethod) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>> {
                return Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>.make(String(format: Path.shareFolder, folder.id), method)
            }

            static func room(folder: ASCFolder, method: HTTPMethod) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>> {
                if method == .get {
                    return Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>.make(String(format: Path.shareRoom, folder.id), method, URLEncoding.default)
                } else {
                    return Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>.make(String(format: Path.shareRoom, folder.id), method)
                }
            }

            static func inviteRequest(folder: ASCFolder) -> Endpoint<OnlyofficeResponse<OnlyofficeInviteRequestModel>> {
                return Endpoint<OnlyofficeResponse<OnlyofficeInviteResponseModel>>.make(String(format: Path.shareRoom, folder.id), .put)
            }

            static func inviteRequestBase(folder: ASCFolder) -> Endpoint<OnlyofficeResponseBase> {
                return Endpoint<OnlyofficeResponseBase>.make(String(format: Path.shareRoom, folder.id), .put)
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
            static let terminate: Endpoint<OnlyofficeResponseArray<OnlyofficeFileOperation>> = Endpoint<OnlyofficeResponseArray<OnlyofficeFileOperation>>.make(Path.operationsTerminate)
            static let markAsRead: Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>> = Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>>.make(Path.markAsRead, .put)
            static let download: Endpoint<OnlyofficeResponseArray<OnlyofficeFileOperation>> = Endpoint<OnlyofficeResponseArray<OnlyofficeFileOperation>>.make(Path.operationDownload, .put)
            static let duplicateRoom: Endpoint<OnlyofficeResponse<OnlyofficeRoomOperation>> = Endpoint<OnlyofficeResponse<OnlyofficeRoomOperation>>.make(Path.operationRoomDuplicate, .put)
            static let roomIndexExport: Endpoint<OnlyofficeResponse<OnlyofficeRoomIndexExportOperation>> = Endpoint<OnlyofficeResponse<OnlyofficeRoomIndexExportOperation>>.make(Path.operationRoomIndexExport, .get)
            static let deleteVersion: Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>> = Endpoint<OnlyofficeResponse<OnlyofficeFileOperation>>.make(Path.deleteFileVersion, .put)
            static let saveRoomAsTemplate: Endpoint<OnlyofficeResponse<OnlyofficeTemplateOperation>> = Endpoint<OnlyofficeResponse<OnlyofficeTemplateOperation>>.make(Path.operationSaveRoomAsTemplate, .post)
            static let roomTemplateStatus: Endpoint<OnlyofficeResponse<OnlyofficeTemplateOperation>> = Endpoint<OnlyofficeResponse<OnlyofficeTemplateOperation>>.make(Path.roomTemplateStatus, .get)
            static let createRoomFromTemplate: Endpoint<OnlyofficeResponse<ASCRoomFromTemplateOperation>> = Endpoint<OnlyofficeResponse<ASCRoomFromTemplateOperation>>.make(Path.roomFromTemplate, .post)
            static let createRoomFromTemplateStatus: Endpoint<OnlyofficeResponse<ASCRoomFromTemplateOperation>> = Endpoint<OnlyofficeResponse<ASCRoomFromTemplateOperation>>.make(Path.roomFromTemplateStatus, .get)

            static func list(urlEncoding: URLEncoding) -> Endpoint<OnlyofficeResponseArray<OnlyofficeFileOperation>> {
                Endpoint<OnlyofficeResponseArray<OnlyofficeFileOperation>>.make(Path.operations, .get, urlEncoding)
            }
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
            static func logos() -> Endpoint<OnlyofficeResponseCodable<LogoUploadResult>> {
                Endpoint<OnlyofficeResponseBase>.make(Path.logos, .post)
            }

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
