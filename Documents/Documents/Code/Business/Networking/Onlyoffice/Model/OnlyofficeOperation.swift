//
//  OnlyofficeOperation.swift
//  Documents
//
//  Created by Pavel Chernyshev on 22.01.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

protocol OnlyofficeOperation {
    var id: String? { get }
    var error: String? { get }
    var percentage: Int? { get }
    var isCompleted: Bool { get }
    var resultFileUrl: String? { get }
}

extension OnlyofficeRoomIndexExportOperation: OnlyofficeOperation {}
