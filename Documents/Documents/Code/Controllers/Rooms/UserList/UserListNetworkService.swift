//
//  UserListNetworkService.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 16.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

protocol UserListNetworkServiceProtocol {
    func fetchUsers(filterValue: String?, completion: @escaping (Result<[ASCUser], Error>) -> Void)
}

class UserListNetworkService: UserListNetworkServiceProtocol {
    private let networkService = OnlyofficeApiClient.shared

    func fetchUsers(filterValue: String?, completion: @escaping (Result<[ASCUser], Error>) -> Void) {
        let endpoint = OnlyofficeAPI.Endpoints.People.filter
        var requestModel = PeopleFilterRequestModel()
        requestModel.filtervalue = filterValue

        networkService.request(endpoint, requestModel.dictionary) { response, error in
            if let error = error {
                log.error(error)
                completion(.failure(error))
                return
            }

            guard let users = response?.result else {
                completion(.success([]))
                return
            }

            completion(.success(users))
        }
    }
}
