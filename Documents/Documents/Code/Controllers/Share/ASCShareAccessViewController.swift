//
//  ASCShareAccessViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/9/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCShareAccessViewController: UITableViewController {

    // MARK: - Properties
    
    var allowReview: Bool = false
    var access: ASCShareAccess = .read {
        didSet {
            setup()
        }
    }
    var callback: ((ASCShareAccess) -> ())? = nil
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = nil
        
        setup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        callback?(access)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func setup() {
        func checkCell(_ index: Int) {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
                cell.accessoryType = .checkmark
            }
        }
        
        switch access {
        case .full:
            checkCell(0); break
        case .read:
            checkCell(1); break
        case .deny:
            checkCell(2); break
        case .review:
            checkCell(3); break
        default:
            checkCell(1)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allowReview ? 4 : 3
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        for index in 0..<tableView.numberOfRows(inSection: 0) {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
                cell.accessoryType = .none
            }
        }
        
        if let cell = super.tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            
            switch indexPath.row {
            case 0:
                access = .full; break
            case 1:
                access = .read; break
            case 2:
                access = .deny; break
            case 3:
                access = .review; break
            default:
                access = .read
            }
        }
    }

}
