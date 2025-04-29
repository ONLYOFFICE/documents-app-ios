//
//  ASCFileProviderProtocol.swift
//  Documents
//
//  Created by Alexander Yuzhin on 12/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

struct ASCEntityActions: OptionSet {
    let rawValue: Int

    static let open = ASCEntityActions(rawValue: 1 << 0)
    static let edit = ASCEntityActions(rawValue: 1 << 1)
    static let rename = ASCEntityActions(rawValue: 1 << 2)
    static let copy = ASCEntityActions(rawValue: 1 << 3)
    static let move = ASCEntityActions(rawValue: 1 << 4)
    static let download = ASCEntityActions(rawValue: 1 << 5)
    static let delete = ASCEntityActions(rawValue: 1 << 6)
    static let restore = ASCEntityActions(rawValue: 1 << 7)
    static let share = ASCEntityActions(rawValue: 1 << 8)
    static let upload = ASCEntityActions(rawValue: 1 << 9)
    static let export = ASCEntityActions(rawValue: 1 << 10)
    static let unmount = ASCEntityActions(rawValue: 1 << 11)
    static let duplicate = ASCEntityActions(rawValue: 1 << 12)
    static let favarite = ASCEntityActions(rawValue: 1 << 13)
    static let new = ASCEntityActions(rawValue: 1 << 14)
    static let archive = ASCEntityActions(rawValue: 1 << 15)
    static let info = ASCEntityActions(rawValue: 1 << 16)
    static let addUsers = ASCEntityActions(rawValue: 1 << 17)
    static let pin = ASCEntityActions(rawValue: 1 << 18)
    static let unpin = ASCEntityActions(rawValue: 1 << 19)
    static let unarchive = ASCEntityActions(rawValue: 1 << 20)
    static let leave = ASCEntityActions(rawValue: 1 << 21)
    static let link = ASCEntityActions(rawValue: 1 << 22)
    static let transformToRoom = ASCEntityActions(rawValue: 1 << 23)
    static let disableNotifications = ASCEntityActions(rawValue: 1 << 24)
    static let select = ASCEntityActions(rawValue: 1 << 25)
    static let docspaceShare = ASCEntityActions(rawValue: 1 << 26)
    static let copySharedLink = ASCEntityActions(rawValue: 1 << 27)
    static let shareAsRoom = ASCEntityActions(rawValue: 1 << 28)
    static let fillForm = ASCEntityActions(rawValue: 1 << 29)
    static let editIndex = ASCEntityActions(rawValue: 1 << 30)
    static let reorderIndex = ASCEntityActions(rawValue: 1 << 31)
    static let changeRoomOwner = ASCEntityActions(rawValue: 1 << 32)
    static let exportRoomIndex = ASCEntityActions(rawValue: 1 << 33)
    static let startFilling = ASCEntityActions(rawValue: 1 << 34)
}

typealias ASCProviderUserInfoHandler = (_ success: Bool, _ error: Error?) -> Void
typealias ASCProviderCompletionHandler = (_ provider: ASCFileProviderProtocol, _ result: Any?, _ success: Bool, _ error: Error?) -> Void

// MARK: - ASCProviderDelegate protocol

protocol ASCProviderDelegate {
    func openProgress(file: ASCFile, title: String, _ progress: Float) -> ASCEditorManagerOpenHandler
    func closeProgress(file: ASCFile, title: String) -> ASCEditorManagerCloseHandler
    func updateItems(provider: ASCFileProviderProtocol)
    func presentShareController(provider: ASCFileProviderProtocol, entity: ASCEntity)
}

// MARK: - ASCProviderDelegate protocol optionals

extension ASCProviderDelegate {
    func updateItems(provider: ASCFileProviderProtocol) {}
    func presentShareController(provider: ASCFileProviderProtocol, entity: ASCEntity) {}
}

// MARK: - ASCBaseFileProvider protocol

protocol FileProviderHolder: AnyObject {
    var provider: ASCFileProviderProtocol? { get set }
}

enum ASCFiletProviderContentType {
    case files, folders, documents, spreadsheets, presentations, images, collaboration, `public`, custom, viewOnly, fillingForms
}

protocol ASCFileProviderProtocol: ASCEntityViewLayoutTypeProvider {
    // Information
    var id: String? { get }
    var type: ASCFileProviderType { get }

    // Data
    var rootFolder: ASCFolder { get }
    var user: ASCUser? { get }
    var items: [ASCEntity] { get set }
    var page: Int { get set }
    var total: Int { get }
    var authorization: String? { get }

    var delegate: ASCProviderDelegate? { get set }
    var filterController: ASCFiltersControllerProtocol? { get set }
    var contentTypes: [ASCFiletProviderContentType] { get }

    // Methods
    func title(for folder: ASCFolder?) -> String?
    func copy() -> ASCFileProviderProtocol
    func cancel()
    func reset()
    func userInfo(completeon: ASCProviderUserInfoHandler?)
    func fetch(for folder: ASCFolder, parameters: [String: Any?], completeon: ASCProviderCompletionHandler?)
    func updateSort(completeon: ASCProviderCompletionHandler?)
    func serialize() -> String?
    func deserialize(_ jsonString: String)

    // Items
    func add(item: ASCEntity, at index: Int)
    func add(items: [ASCEntity], at index: Int)
    func remove(at index: Int)

    // Network
    func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void)
    func isReachable(with info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCFileProviderProtocol?) -> Void))
    func absoluteUrl(from string: String?) -> URL?
    func errorMessage(by errorObject: Any) -> String
    func handleNetworkError(_ error: Error?) -> Bool

    func modifyImageDownloader(request: URLRequest) -> URLRequest
    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler)
    func download(_ path: String, to: URL, range: Range<Int64>?, processing: @escaping NetworkProgressHandler)
    func upload(_ path: String, data: Data, overwrite: Bool, params: [String: Any]?, processing: @escaping NetworkProgressHandler)
    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?)
    func favorite(_ entity: ASCEntity, favorite: Bool, completeon: ASCProviderCompletionHandler?)
    func markAsRead(_ entities: [ASCEntity], completeon: ASCProviderCompletionHandler?)
    func delete(_ entities: [ASCEntity], from folder: ASCFolder, move: Bool?, completeon: ASCProviderCompletionHandler?)
    func emptyTrash(completeon: ASCProviderCompletionHandler?)
    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?)
    func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler)
    func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler)
    func createFolder(_ name: String, in folder: ASCFolder, params: [String: Any]?, completeon: ASCProviderCompletionHandler?)
    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler?)
    func transfer(items: [ASCEntity], to folder: ASCFolder, move: Bool, conflictResolveType: ConflictResolveType, contentOnly: Bool, handler: ASCEntityProgressHandler?)

    // Access
    func allowAdd(toFolder folder: ASCFolder?) -> Bool
    func allowRead(entity: AnyObject?) -> Bool
    func allowEdit(entity: AnyObject?) -> Bool
    func allowComment(entity: AnyObject?) -> Bool
    func allowDelete(entity: AnyObject?) -> Bool
    func actions(for entity: ASCEntity?) -> ASCEntityActions
    func isTrash(for folder: ASCFolder?) -> Bool
    func allowDragAndDrop(for entity: ASCEntity?) -> Bool
    func getAccess(for folder: ASCFolder?, password: String, completion: @escaping (Result<ASCFolder?, Error>) -> Void)

    // Open files
    func open(file: ASCFile, openMode: ASCDocumentOpenMode, canEdit: Bool)
    func preview(file: ASCFile, openMode: ASCDocumentOpenMode, files: [ASCFile]?, in view: UIView?)

    // Action Handlers
    func handle(action: ASCEntityActions, folder: ASCFolder, handler: ASCEntityHandler?)

    // Subcategories
    func segmentCategory(of folder: ASCFolder) -> [ASCSegmentCategory]
}

// MARK: - ASCFileProvider protocol

extension ASCFileProviderProtocol {
    var contentTypes: [ASCFiletProviderContentType] {
        [.files, .folders, .documents, .spreadsheets, .presentations, .images]
    }

    func title(for folder: ASCFolder?) -> String? { folder?.title }
    func cancel() {}
    func userInfo(completeon: ASCProviderUserInfoHandler?) {}
    func updateSort(completeon: ASCProviderCompletionHandler?) {}
    func serialize() -> String? { nil }
    func deserialize(_ jsonString: String) {}

    func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {}
    func isReachable(with info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCFileProviderProtocol?) -> Void)) { complation(false, nil) }
    func absoluteUrl(from string: String?) -> URL? { URL(string: string ?? "") }
    func errorMessage(by errorObject: Any) -> String { "" }
    func handleNetworkError(_ error: Error?) -> Bool { false }
    func modifyImageDownloader(request: URLRequest) -> URLRequest { request }
    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {}
    func download(_ path: String, to: URL, range: Range<Int64>?, processing: @escaping NetworkProgressHandler) {}
    func upload(_ path: String, data: Data, overwrite: Bool, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {}
    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?) {}
    func favorite(_ entity: ASCEntity, favorite: Bool, completeon: ASCProviderCompletionHandler?) {}
    func markAsRead(_ entities: [ASCEntity], completeon: ASCProviderCompletionHandler?) {}
    func delete(_ entities: [ASCEntity], from folder: ASCFolder, move: Bool?, completeon: ASCProviderCompletionHandler?) {}
    func emptyTrash(completeon: ASCProviderCompletionHandler?) {}
    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {}
    func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {}
    func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {}
    func createFolder(_ name: String, in folder: ASCFolder, params: [String: Any]?, completeon: ASCProviderCompletionHandler?) {}
    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler?) { handler?(.end, nil, nil) }
    func transfer(items: [ASCEntity], to folder: ASCFolder, move: Bool, conflictResolveType: ConflictResolveType, contentOnly: Bool, handler: ASCEntityProgressHandler?) { var cancel = false; handler?(.end, 1, nil, nil, &cancel) }
    func allowAdd(toFolder folder: ASCFolder?) -> Bool { allowEdit(entity: folder) }
    func allowComment(entity: AnyObject?) -> Bool { allowEdit(entity: entity) }
    func allowRead(entity: AnyObject?) -> Bool { false }
    func allowEdit(entity: AnyObject?) -> Bool { false }
    func allowDelete(entity: AnyObject?) -> Bool { false }
    func allowDragAndDrop(for entity: ASCEntity?) -> Bool { true }
    func getAccess(for folder: ASCFolder?, password: String, completion: @escaping (Result<ASCFolder?, Error>) -> Void) { completion(.failure(ProtocolImplementationError.unsupported)) }
    func isTrash(for folder: ASCFolder?) -> Bool { false }
    func actions(for entity: ASCEntity?) -> ASCEntityActions { [] }
    func handle(action: ASCEntityActions, folder: ASCFolder, handler: ASCEntityHandler? = nil) {
        log.error("Handle action \(action.rawValue) for folder \(folder.title) doesn't supported")
        handler?(.error, folder, ASCProviderError(msg: "Unsupported handle action"))
    }

    func segmentCategory(of folder: ASCFolder) -> [ASCSegmentCategory] { [] }
}

// MARK: - ASCSortableFileProvider protocol

protocol ASCSortableFileProviderProtocol {
    var folder: ASCFolder? { get set }
    var fetchInfo: [String: Any?]? { get set }

    func sort(by info: [String: Any], entities: inout [ASCEntity])
    func sort(by info: [String: Any], folders: inout [ASCFolder], files: inout [ASCFile])
}

extension ASCSortableFileProviderProtocol {
    /// Sort records
    ///
    /// - Parameters:
    ///   - info: Sort information as dictinory
    ///   - folders: Sorted folders
    ///   - files: Sorted files
    func sort(by info: [String: Any], folders: inout [ASCFolder], files: inout [ASCFile]) {
        let sortBy = ASCDocumentSortType(info["type"] as? String ?? "az")
        let sortOrder = info["order"] as? String ?? "ascending"
        let ascending = sortOrder == "ascending"

        switch sortBy {
        case .type:
            files = ascending
                ? files.sorted { $0.title.fileExtension().lowercased() < $1.title.fileExtension().lowercased() }
                : files.sorted { $0.title.fileExtension().lowercased() > $1.title.fileExtension().lowercased() }
        case .dateandtime:
            let nowDate = Date()
            folders = ascending
                ? folders.sorted { $0.created ?? nowDate < $1.created ?? nowDate }
                : folders.sorted { $0.created ?? nowDate > $1.created ?? nowDate }
            files = ascending
                ? files.sorted { $0.updated ?? nowDate < $1.updated ?? nowDate }
                : files.sorted { $0.updated ?? nowDate > $1.updated ?? nowDate }
        case .size:
            files = ascending
                ? files.sorted { $0.pureContentLength < $1.pureContentLength }
                : files.sorted { $0.pureContentLength > $1.pureContentLength }
        default:
            folders = ascending
                ? folders.sorted { $0.title < $1.title }
                : folders.sorted { $0.title > $1.title }
            files = ascending
                ? files.sorted { $0.title < $1.title }
                : files.sorted { $0.title > $1.title }
        }
    }

    /// Sort records
    ///
    /// - Parameters:
    ///   - info: Sort information as dictinory
    ///   - entities: Sorted entities
    func sort(by info: [String: Any], entities: inout [ASCEntity]) {
        var folders = entities.filter { $0 is ASCFolder } as? [ASCFolder] ?? []
        var files = entities.filter { $0 is ASCFile } as? [ASCFile] ?? []

        sort(by: info, folders: &folders, files: &files)

        entities = folders as [ASCEntity] + files as [ASCEntity]
    }
}

// MARK: ConflictResolveType

enum ConflictResolveType: Int {
    case skip = 0
    case overwrite = 1
    case duplicate = 2
}

// MARK: External provider name

extension ASCFileProviderProtocol {
    func externalProviderName() -> String {
        let providerName: ((_ type: ASCFileProviderType) -> String) = { type in
            switch type {
            case .googledrive:
                return NSLocalizedString("Google Drive", comment: "")
            case .dropbox:
                return NSLocalizedString("Dropbox", comment: "")
            case .nextcloud:
                return NSLocalizedString("Nextcloud", comment: "")
            case .owncloud:
                return NSLocalizedString("ownCloud", comment: "")
            case .yandex:
                return NSLocalizedString("Yandex Disk", comment: "")
            case .webdav:
                return NSLocalizedString("WebDAV", comment: "")
            case .icloud:
                return NSLocalizedString("iCloud", comment: "")
            case .onedrive:
                return NSLocalizedString("OneDrive", comment: "")
            case .kdrive:
                return NSLocalizedString("kDrive", comment: "")
            default:
                return NSLocalizedString("Unknown", comment: "")
            }
        }

        return providerName(type)
    }
}

enum ProtocolImplementationError: Error {
    case unsupported
}
