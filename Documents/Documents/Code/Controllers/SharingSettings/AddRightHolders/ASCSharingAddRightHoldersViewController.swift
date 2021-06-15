//
//  ASCAddRightHoldersViewController.swift
//  Documents
//
//  Created by Павел Чернышев on 15.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingAddRightHoldersViewController: UIViewController {
    
    private lazy var usersTableViewDataSourceAndDelegate = ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<ASCSharingAddRightHoldersUserTableViewCell>(models: self.usersModels)
    private lazy var groupsTableViewDataSourceAndDelegate = ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<ASCSharingAddRightHoldersGroupTableViewCell>(models: self.groupsModels)
    
    private lazy var usersTableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = usersTableViewDataSourceAndDelegate
        tableView.delegate = usersTableViewDataSourceAndDelegate
        return tableView
    }()
    
    private lazy var groupsTableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = groupsTableViewDataSourceAndDelegate
        tableView.delegate = groupsTableViewDataSourceAndDelegate
        return tableView
    }()
    
    var usersModels: [ASCSharingAddRightHolderUserModel] = [
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Abel – Abe, Abie;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Abner – Ab, Abbie;", type: "Manager", isSelected: true),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Abraham, Abram – Abe, Abie, Bram;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Adam – Ad, Addie, Addy, Ade;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Benjamin – Ben, Bennie, Benny, Benjy Benjie;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Bennet, Bennett – Ben, Bennie, Benny;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Bernard, Barnard – Bernie, Berney, Barney, Barnie", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Christopher Kit, Kester, Kristof, Toph,", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Clarence – Clare, Clair;", type: "Manager", isSelected: true),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Clare, Clair;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Clark, Clarke;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Claude, Claud;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Donald – Don, Donnie, Donny", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Donovan – Don, Donnie, Donny;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Dorian;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Dougls, Douglass – Doug;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Doyle;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Drew (see Andrew);", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Elliot, Elliott – El;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Ellis – El;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Elmer – El;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Elton, Alton – El, Al;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Elvin, Elwin, Elwyn – El, Vin, Vinny, Win;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Elvis – El;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Herman – Manny, Mannie;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Hilary, Hillary – Hill, Hillie, Hilly;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Homer;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Horace, Horatio;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Howard – Howie;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Hubert – Hugh, Bert, Bertie", type: "Manager")
    ]
    
    var groupsModels: [ASCSharingAddRightHoldersGroupModel] = [
        ASCSharingAddRightHoldersGroupModel(image: Asset.Images.avatarDefaultGroup.image, name: "Admins", isSelected: false),
        ASCSharingAddRightHoldersGroupModel(image: Asset.Images.avatarDefaultGroup.image, name: "Disigners", isSelected: false)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

// MARK: - Users and Groupd TableView data source and delegate
extension ASCSharingAddRightHoldersViewController {
    class ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<T: UITableViewCell & ASCReusedIdentifierProtocol & ASCViewModelSetter>:
        NSObject, UITableViewDataSource, UITableViewDelegate {
        
        var models: [T.ViewModel]
        
        init(models: [T.ViewModel]) {
            self.models = models
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            models.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard var cell = tableView.dequeueReusableCell(withIdentifier: T.reuseId) as? T else {
                fatalError("Couldn't cast cell to \(T.self)")
            }
            let viewModel = models[indexPath.row]
            cell.viewModel = viewModel
            return cell
        }
    }
}


