//
//  ASCShareViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/7/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD

class ASCShareViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties
    
    var entity: Any? = nil
    var users: [ASCShareInfo] = []
    var groups: [ASCShareInfo] = []
    var showUsers: Bool = true {
        didSet {
            updateData()
        }
    }
    
    private var allowReview: Bool = false
    private var modifed: Bool = false
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categoryControl: UISegmentedControl!
    @IBOutlet var emptyView: UIView!
    @IBOutlet var loadingView: UIView!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showLoadingView(true)
        loadShareInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func loadShareInfo() {
        var request: String? = nil
        
        if let file = entity as? ASCFile {
            request = String(format: ASCOnlyOfficeApi.apiShareFile, file.id)
            allowReview = file.title.fileExtension().lowercased() == "docx"
        } else if let folder = entity as? ASCFolder {
            request = String(format: ASCOnlyOfficeApi.apiShareFolder, folder.id)
        }
        
        if let apiRequest = request {
            ASCOnlyOfficeApi.get(apiRequest) { (results, error, response) in
                self.showLoadingView(false)
                
                if let results = results as? [[String: Any]] {
                    self.users.removeAll()
                    self.groups.removeAll()
                    
                    for item in results {
                        var sharedItem = ASCShareInfo()
                        
                        sharedItem.access = ASCShareAccess(item["access"] as? Int ?? 0)
                        sharedItem.locked = item["isLocked"] as? Bool ?? false
                        sharedItem.owner = item["isOwner"] as? Bool ?? false
                        sharedItem.shareLink = item["sharedItem"] as? String
                    
                        // Link for portal users
                        if let _ = sharedItem.shareLink {
                            continue
                        }
                        
                        if let sharedTo = item["sharedTo"] as? [String: Any] {
                            if let _ = sharedTo["userName"] {
                                // User
                                sharedItem.user = ASCUser(JSON: sharedTo)
                            } else if let _ = sharedTo["name"] {
                                // Group
                                sharedItem.group = ASCGroup(JSON: sharedTo)
                            }
                        }
                        
                        if let _ = sharedItem.user {
                            self.users.append(sharedItem)
                        } else if let _ = sharedItem.group {
                            self.groups.append(sharedItem)
                        }
                    }
                }
                
                self.updateData()
            }
        }
    }
    
    func updateData() {
        tableView.reloadData()
        displayEmptyViewIfNeed()
    }
    
    // MARK: - Table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return showUsers ? users.count : groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ShareCell", for: indexPath) as? ASCShareCell {
            cell.share = showUsers ? users[indexPath.row] : groups[indexPath.row]
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if showUsers {
            return !users[indexPath.row].locked
        } else {
            return !groups[indexPath.row].locked
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            removeShare(at: indexPath)
        }
    }
    
    // MARK: - Private
    
    private func applyShare() {
        var shares: [[String: Any]] = []
        var request: String!
        
        if let file = entity as? ASCFile {
            request = String(format: ASCOnlyOfficeApi.apiShareFile, file.id)
        } else if let folder = entity as? ASCFolder {
            request = String(format: ASCOnlyOfficeApi.apiShareFolder, folder.id)
        }
        
        for share in showUsers ? users : groups {
            if let itemId = showUsers ? share.user?.userId : share.group?.id {
                shares.append([
                    "ShareTo": itemId,
                    "Access": share.access.rawValue
                    ])
            }
        }
        
        let baseParams: Parameters = [
            "notify": "false"
        ]
        let sharesParams = sharesToParams(shares: shares)
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Sharing", comment: "Caption of the process")
        
        ASCOnlyOfficeApi.put(request, parameters: baseParams + sharesParams) { [weak self] (results, error, response) in
            if let _ = results as? [[String: Any]] {
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: 1)
            } else if let response = response, let strongSelf = self {
                hud?.hide(animated: false)
                UIAlertController.showError(in: strongSelf, message: ASCOnlyOfficeApi.errorMessage(by: response))
            }
        }
    }
    
    private func removeShare(at indexPath: IndexPath) {
        let index = indexPath.row
        var itemId: String!
        var request: String!
        
        if let file = entity as? ASCFile {
            request = String(format: ASCOnlyOfficeApi.apiShareFile, file.id)
        } else if let folder = entity as? ASCFolder {
            request = String(format: ASCOnlyOfficeApi.apiShareFolder, folder.id)
        }
        
        if showUsers {
            itemId = users[index].user?.userId ?? ""
            users.remove(at: index)
        } else {
            itemId = groups[index].group?.id ?? ""
            groups.remove(at: index)
        }
        
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .left)
        tableView.endUpdates()
        
        displayEmptyViewIfNeed()
        
        let baseParams: Parameters = [
            "notify": "false"
        ]
        let sharesParams = sharesToParams(shares: [
            [
                "ShareTo": itemId,
                "Access": ASCShareAccess.none.rawValue
            ]
        ])
        
        modifed = true
        
        ASCOnlyOfficeApi.put(request, parameters: baseParams + sharesParams) { (results, error, response) in
            if let _ = results as? [[String: Any]] {
                //
            }
        }
    }
    
//    private func createShareQuery(from shares: [[String: Any]]) -> String {
//        return shares.enumerated().map { (index, dictinory) in
//            return dictinory.map { element in
//                return "share[\(index)].\(element.key)=\(element.value)"
//            }.joined(separator: "&")
//        }.joined(separator: "&")
//    }
    
    private func sharesToParams(shares: [[String: Any]]) -> [String: Any] {
        var params: [String: Any] = [:]
        
        for (index, dictinory) in shares.enumerated() {
            for (key, value) in dictinory {
                params["share[\(index)].\(key)"] = value
            }
        }

        return params
    }
    
    private func showLoadingView(_ show: Bool) {
        if show {
            tableView.addSubview(loadingView)
            
            loadingView.translatesAutoresizingMaskIntoConstraints = false
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            
            tableView.isUserInteractionEnabled = false
        } else {
            loadingView.removeFromSuperview()
            tableView.isUserInteractionEnabled = true
        }
    }
    
    private func showEmptyView(_ show: Bool) {
        emptyView.isHidden = !show
        
        if emptyView.superview == nil {
            tableView.addSubview(emptyView)
            
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            emptyView.centerYAnchor.constraint(equalTo: tableView.topAnchor, constant: (view.frame.height - emptyView.frame.height) * 0.5).isActive = true
        }
    }
    
    private func displayEmptyViewIfNeed() {
        if showUsers {
            showEmptyView(users.count < 2)
        } else {
            showEmptyView(groups.count < 1)
        }
    }
    
    // MARK: - Action
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        if modifed {
            applyShare()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCategoryChange(_ sender: UISegmentedControl) {
        showUsers = sender.selectedSegmentIndex == 0
    }

    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "segueAccessShare" {
            if let sharedCell = sender as? ASCShareCell, sharedCell.share?.locked ?? true {
                return false
            }
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueAddShare" {
            if let sharedItemsController = segue.destination as? ASCShareItemsViewController {
                sharedItemsController.existUsers = users
                sharedItemsController.existGroups = groups
                sharedItemsController.showUsers = showUsers
                sharedItemsController.allowReview = allowReview
                sharedItemsController.callback = { shares in
                    if self.showUsers {
                        self.users += shares
                    } else {
                        self.groups += shares
                    }
                    
                    self.modifed = true
                    self.tableView.reloadData()
                    self.displayEmptyViewIfNeed()
                }
            }
        } else if segue.identifier == "segueAccessShare" {
            if let sharedAccessController = segue.destination as? ASCShareAccessViewController {
                sharedAccessController.allowReview = allowReview
                
                if let sharedCell = sender as? ASCShareCell {
                    sharedAccessController.title = sharedCell.share?.user?.displayName
                    sharedAccessController.access = sharedCell.share?.access ?? .read
                    sharedAccessController.callback = { access in
                        sharedCell.share?.access = access
                        
                        if let indexPath = self.tableView.indexPath(for: sharedCell) {
                            if self.showUsers {
                                self.users[indexPath.row].access = access
                            } else {
                                self.groups[indexPath.row].access = access
                            }
                            
                            self.tableView.reloadData()
                            self.modifed = true
                        }
                    }
                }
            }
        }
        
     }
}
