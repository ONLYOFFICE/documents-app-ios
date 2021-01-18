//
//  ASCBaseFileProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 12/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

struct ASCEntityActions: OptionSet {
    let rawValue: Int

    static let open         = ASCEntityActions(rawValue: 1 << 0)
    static let edit         = ASCEntityActions(rawValue: 1 << 1)
    static let rename       = ASCEntityActions(rawValue: 1 << 2)
    static let copy         = ASCEntityActions(rawValue: 1 << 3)
    static let move         = ASCEntityActions(rawValue: 1 << 4)
    static let download     = ASCEntityActions(rawValue: 1 << 5)
    static let delete       = ASCEntityActions(rawValue: 1 << 6)
    static let restore      = ASCEntityActions(rawValue: 1 << 7)
    static let share        = ASCEntityActions(rawValue: 1 << 8)
    static let upload       = ASCEntityActions(rawValue: 1 << 9)
    static let export       = ASCEntityActions(rawValue: 1 << 10)
    static let unmount      = ASCEntityActions(rawValue: 1 << 11)
    static let duplicate    = ASCEntityActions(rawValue: 1 << 12)
    static let favarite     = ASCEntityActions(rawValue: 1 << 13)
}

typealias ASCProviderUserInfoHandler = ((_ success: Bool, _ error: Error?) -> Void)
typealias ASCProviderCompletionHandler = ((_ provider: ASCBaseFileProvider, _ result: Any?, _ success: Bool, _ error: Error?) -> Void)

protocol ASCProviderDelegate {
    func openProgressFile(title: String, _ progress: Float) -> ASCEditorManagerOpenHandler
    func closeProgressFile(title: String) -> ASCEditorManagerCloseHandler
}

protocol ASCBaseFileProvider {
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

    // Methods
    func copy() -> ASCBaseFileProvider
    func cancel()
    func reset()
    func userInfo(completeon: ASCProviderUserInfoHandler?)
    func fetch(for folder: ASCFolder, parameters: [String: Any?], completeon: ASCProviderCompletionHandler?)

    func serialize() -> String?
    func deserialize(_ jsonString: String)

    // Network
    func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void)
    func absoluteUrl(from string: String?) -> URL?
    func errorMessage(by errorObject: Any) -> String
    func handleNetworkError(_ error: Error?) -> Bool

    func modifyImageDownloader(request: URLRequest) -> URLRequest
    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler)
    func download(_ path: String, to: URL, processing: @escaping ASCApiProgressHandler)
    func upload(_ path: String, data: Data, overwrite: Bool, params: [String: Any]?, processing: @escaping ASCApiProgressHandler)
    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?)
    func favorite(_ entity: ASCEntity, favorite: Bool, completeon: ASCProviderCompletionHandler?)
    func delete(_ entities: [ASCEntity], from folder: ASCFolder, completeon: ASCProviderCompletionHandler?)
    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?)
    func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler)
    func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler)
    func createFolder(_ name: String, in folder: ASCFolder, params: [String: Any]?, completeon: ASCProviderCompletionHandler?)
    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler?)
    func transfer(items: [ASCEntity], to folder: ASCFolder, move: Bool, overwrite: Bool, handler: ASCEntityProgressHandler?)

    // Access
    func allowRead(entity: AnyObject?) -> Bool
    func allowEdit(entity: AnyObject?) -> Bool
    func allowDelete(entity: AnyObject?) -> Bool
    func actions(for entity: ASCEntity?) -> ASCEntityActions

    // Open files
    func open(file: ASCFile, viewMode: Bool)
    func preview(file: ASCFile, files: [ASCFile]?, in view: UIView?)
}

extension ASCBaseFileProvider {
    func cancel() {}
    func userInfo(completeon: ASCProviderUserInfoHandler?) {}
    func serialize() -> String? { return nil }
    func deserialize(_ jsonString: String) {}

    func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {}
    func absoluteUrl(from string: String?) -> URL? { return URL(string: string ?? "") }
    func errorMessage(by errorObject: Any) -> String  { return "" }
    func handleNetworkError(_ error: Error?) -> Bool { return false }
    func modifyImageDownloader(request: URLRequest) -> URLRequest { return request }
    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {}
    func download(_ path: String, to: URL, processing: @escaping ASCApiProgressHandler) {}
    func upload(_ path: String, data: Data, overwrite: Bool, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {}
    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?) {}
    func favorite(_ entity: ASCEntity, favorite: Bool, completeon: ASCProviderCompletionHandler?) {}
    func delete(_ entities: [ASCEntity], from folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {}
    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {}
    func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {}
    func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {}
    func createFolder(_ name: String, in folder: ASCFolder, params: [String: Any]?, completeon: ASCProviderCompletionHandler?) {}
    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler?) { handler?(.end, nil, nil) }
    func transfer(items: [ASCEntity], to folder: ASCFolder, move: Bool, overwrite: Bool, handler: ASCEntityProgressHandler?) { var cancel = false; handler?(.end, 1, nil, nil, &cancel) }

    func allowRead(entity: AnyObject?) -> Bool { return false }
    func allowEdit(entity: AnyObject?) -> Bool { return false }
    func allowDelete(entity: AnyObject?) -> Bool { return false }
    func actions(for entity: ASCEntity?) -> ASCEntityActions { return [] }
    func open(file: ASCFile, viewMode: Bool = false) {}
    func preview(file: ASCFile, files: [ASCFile]? = nil, in view: UIView? = nil) {}
}
