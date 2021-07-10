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
    
}

class ASCSharingAddRightHoldersInteractor: ASCSharingAddRightHoldersBusinessLogic, ASCSharingAddRightHoldersDataStore {
    
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
                    self.presenter?.presentData(responseType: .presentUsers(.init(users: users)))
                }
            }
        case .loadGroups: return
        }
    }
    
}
