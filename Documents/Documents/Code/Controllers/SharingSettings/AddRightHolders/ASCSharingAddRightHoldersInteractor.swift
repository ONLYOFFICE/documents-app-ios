//
//  ASCSharingAddRightHoldersInteractor.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingAddRightHoldersBusinessLogic {
    func makeRequest(requestType: ASCSharingAddRightHolders.Model.Request.RequestType)
}

protocol ASCSharingAddRightHoldersDataStore {
    var sharedInfoItems: [ASCShareInfo] { get set }
    var itemsForSharing: [ASCShareInfo] { get }
}

class ASCSharingAddRightHoldersInteractor: ASCSharingAddRightHoldersBusinessLogic, ASCSharingAddRightHoldersDataStore {
    
    var sharedInfoItems: [ASCShareInfo] = []
    var itemsForSharing: [ASCShareInfo] = []
    
    var presenter: ASCSharingAddRightHoldersPresentationLogic?
    
    func makeRequest(requestType: ASCSharingAddRightHolders.Model.Request.RequestType) {
        switch requestType {
        case .loadUsers:
            ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiUsers) { (results, error, response) in
                if let results = results as? [[String: Any]] {
                    var users: [ASCUser] = []
                    for item in results {
                        if let user = ASCUser(JSON: item) {
                            users.append(user)
                        }
                    }
                    self.presenter?.presentData(responseType: .presentUsers(.init(users: users, sharedEntities: self.sharedInfoItems)))
                }
            }
        case .loadGroups: return
            ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiGroups) { (results, error, response) in
                if let results = results as? [[String: Any]] {
                    var groups: [ASCGroup] = []
                    for item in results {
                        if let group = ASCGroup(JSON: item) {
                            groups.append(group)
                        }
                    }
                    
                    self.presenter?.presentData(responseType: .presentGroups(.init(groups: groups, sharedEntities: self.sharedInfoItems)))
                }
            }
        }
    }
}
