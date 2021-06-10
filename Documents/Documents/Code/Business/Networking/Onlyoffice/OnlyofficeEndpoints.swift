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
        static public let files                  = "api/\(version)/files/"
        static public let file                   = "api/\(version)/files/file/%@"
        static public let folder                 = "api/\(version)/files/folder/%@"
        static public let favorite               = "api/\(version)/files/favorites"
        static public let filesShare             = "api/\(version)/files/share"
        static public let fileopsDelete          = "api/\(version)/files/fileops/delete"
        static public let thirdParty             = "api/\(version)/files/thirdparty"
        static public let insertFile             = "api/\(version)/files/%@/insert"
        static public let uploadFile             = "api/\(version)/files/%@/upload"
    }

    struct Endpoints {
        
        // MARK: Authentication
        
        struct Auth {
            static func authentication(with code: String? = nil) -> Endpoint<OnlyofficeDataResult<OnlyofficeAuth>> {
                var path = Path.authentication
                
                if let code = code {
                    path = "\(Path.authentication)/\(code)"
                }
                
                return Endpoint<OnlyofficeDataResult<OnlyofficeAuth>>.make(path, .post)
            }
            static let deviceRegistration: Endpoint<Parameters> = Endpoint<Parameters>.make(Path.deviceRegistration, .post)
            static let sendCode: Endpoint<Parameters> = Endpoint<Parameters>.make(Path.authenticationCode, .post)
            static let sendPhone: Endpoint<Parameters> = Endpoint<Parameters>.make(Path.authenticationPhone, .post)
        }
        
        // MARK: People
        
        struct People {
            static let me: Endpoint<OnlyofficeDataResult<ASCUser>> = Endpoint<OnlyofficeDataResult<ASCUser>>.make(Path.peopleSelf)
            static func photo(of user: ASCUser) -> Endpoint<OnlyofficeDataResult<OnlyofficeUserPhoto>> {
                return Endpoint<OnlyofficeDataResult<OnlyofficeUserPhoto>>.make(String(format: Path.peoplePhoto, user.userId ?? ""))
            }
        }
        
        // MARK: Folders
        
        struct Folders {
            static func path(of folder: ASCFolder) -> Endpoint<OnlyofficeDataResult<OnlyofficePath>> {
                return Endpoint<OnlyofficeDataResult<OnlyofficePath>>.make(Path.files + folder.id, .get, URLEncoding.default)
            }
            
            static func update(folder: ASCFolder) -> Endpoint<OnlyofficeDataResult<ASCFolder>> {
                return Endpoint<OnlyofficeDataResult<ASCFolder>>.make(String(format: Path.folder, folder.id), .put)
            }
        }
        
        // MARK: Files
        
        struct Files {
            static func update(file: ASCFile) -> Endpoint<OnlyofficeDataResult<ASCFile>> {
                return Endpoint<OnlyofficeDataResult<ASCFile>>.make(String(format: Path.file, file.id), .put)
            }

            static let addFavorite: Endpoint<OnlyofficeDataSingleResult<Bool>> = Endpoint<OnlyofficeDataSingleResult<Bool>>.make(Path.favorite, .post)
            static let removeFavorite: Endpoint<OnlyofficeDataSingleResult<Bool>> = Endpoint<OnlyofficeDataSingleResult<Bool>>.make(Path.favorite, .delete)
        }
        
        // MARK: Sharing
        
        struct Sharing {
            static let removeSharingRights: Endpoint<OnlyofficeDataSingleResult<Bool>> = Endpoint<OnlyofficeDataSingleResult<Bool>>.make(Path.filesShare, .delete)
        }
        
        // MARK: Operations
        
        struct Operations {
            static let removeEntities: Endpoint<OnlyofficeDataArrayResult<Parameters>> = Endpoint<OnlyofficeDataArrayResult<Parameters>>.make(Path.fileopsDelete, .put)
        }
        
        // MARK: Third-Party Integration
        
        struct ThirdPartyIntegration {
            static func remove(providerId: String) -> Endpoint<OnlyofficeDataSingleResult<String>> {
                return Endpoint<OnlyofficeDataSingleResult<String>>.make(Path.thirdParty.appendingPathComponent(providerId), .delete)
            }
        }
        
        // MARK: Uploads
        
        struct Uploads {
            static func upload(in path: String) -> Endpoint<OnlyofficeDataResult<ASCFile>> {
                return Endpoint<OnlyofficeDataResult<ASCFile>>.make(String(format: Path.uploadFile, path), .post)
            }
            static func insert(in path: String) -> Endpoint<OnlyofficeDataResult<ASCFile>> {
                return Endpoint<OnlyofficeDataResult<ASCFile>>.make(String(format: Path.insertFile, path), .post, URLEncoding.default)
            }
        }
        
        // MARK: Settings
        
        static let serversVersion: Endpoint<OnlyofficeDataResult<OnlyofficeVersion>> = Endpoint<OnlyofficeDataResult<OnlyofficeVersion>>.make(Path.serversVersion)
        static let serverCapabilities: Endpoint<OnlyofficeDataResult<OnlyofficeCapabilities>> = Endpoint<OnlyofficeDataResult<OnlyofficeCapabilities>>.make(Path.capabilities)
    }

}
