//
//  ASCEntityItemProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 24/01/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

let ASCEntityItemProviderTypeId = "com.onlyoffice.documents.entityItemProvider"

class ASCEntityItemProvider: NSObject, Codable {
    public var providerId: String = ""
    public var entity: ASCEntity {
        return file ?? folder ?? ASCEntity()
    }
    private var file: ASCFile?
    private var folder: ASCFolder?

    private enum CodingKeys : String, CodingKey {
        case providerId
        case file
        case folder
    }

    required public init(providerId: String, entity: ASCEntity) {
        self.providerId = providerId
        self.file = entity as? ASCFile
        self.folder = entity as? ASCFolder
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: ASCEntityItemProvider.CodingKeys.self)
        do {
            let fileJson = try values.decode(String.self, forKey: .file)
            self.file = ASCFile(JSONString: fileJson)
        } catch { }

        do {
            let folderJson = try values.decode(String.self, forKey: .folder)
            self.folder = ASCFolder(JSONString: folderJson)
        } catch { }

        self.providerId = try values.decode(String.self, forKey: .providerId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ASCEntityItemProvider.CodingKeys.self)

        try container.encode(providerId, forKey: .providerId)

        if let file = entity as? ASCFile, let json = file.toJSONString() {
            try container.encode(json, forKey: .file)
        }

        if let folder = entity as? ASCFolder, let json = folder.toJSONString() {
            try container.encode(json, forKey: .folder)
        }
    }
}

extension ASCEntityItemProvider: NSItemProviderReading {
    static var readableTypeIdentifiersForItemProvider: [String] {
        return [ASCEntityItemProviderTypeId]
    }

    static func object(withItemProviderData data: Data,
                       typeIdentifier: String) throws -> Self {
        let decoder = JSONDecoder()
        let documentsItemProvider = try decoder.decode(ASCEntityItemProvider.self, from: data)

        return self.init(providerId: documentsItemProvider.providerId, entity: documentsItemProvider.entity)
    }
}

extension ASCEntityItemProvider: NSItemProviderWriting {
    static var writableTypeIdentifiersForItemProvider: [String] {
        return [ASCEntityItemProviderTypeId]
    }

    func loadData(withTypeIdentifier typeIdentifier: String,
                  forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 100)
        do {
            let data = try JSONEncoder().encode(self)
            progress.completedUnitCount = 100
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return progress
    }
}
