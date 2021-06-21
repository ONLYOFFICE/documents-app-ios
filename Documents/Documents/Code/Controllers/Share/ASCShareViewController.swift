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
    var users: [OnlyofficeShare] = []
    var groups: [OnlyofficeShare] = []
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
        let requestHandler: (OnlyofficeResponseArray<OnlyofficeShare>?, Error?) -> Void = { response, error in
            self.showLoadingView(false)
            
            if let sharedItems = response?.result {
                self.users.removeAll()
                self.groups.removeAll()
                
                self.users = sharedItems.filter { $0.user != nil }
                self.groups = sharedItems.filter { $0.group != nil }
            }
            
            self.updateData()
        }
        
        if let file = entity as? ASCFile {
            allowReview = file.title.fileExtension().lowercased() == "docx"
            
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Sharing.file(file: file)) { response, error in
                requestHandler(response, error)
            }
        } else if let folder = entity as? ASCFolder {
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Sharing.folder(folder: folder)) { response, error in
                requestHandler(response, error)
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
        let share = OnlyofficeShareRequest()
        share.notify = false
        share.share = (showUsers ? users : groups).map {
            OnlyofficeShareItemRequest(
                shareTo: (showUsers ? $0.user?.userId : $0.group?.id) ?? "",
                access: $0.access
            )
        }
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Sharing", comment: "Caption of the process")
        
        let requestHandler: (UIViewController?, Error?) -> Void = { viewController, error in
            if let error = error {
                hud?.hide(animated: false)
                if let viewController = viewController {
                    UIAlertController.showError(in: viewController, message: error.localizedDescription)
                }
            } else {
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: 1)
            }
        }
        
        if let file = entity as? ASCFile {
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Sharing.file(file: file), share.toJSON()) { [weak self] response, error in
                requestHandler(self, error)
            }
        } else if let folder = entity as? ASCFolder {
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Sharing.folder(folder: folder), share.toJSON()) { [weak self] response, error in
                requestHandler(self, error)
            }
        }
    }
    
    private func removeShare(at indexPath: IndexPath) {
        let index = indexPath.row
        var itemId: String!

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
        
        let share = OnlyofficeShareRequest()
        share.notify = false
        share.share = [OnlyofficeShareItemRequest(shareTo: itemId ?? "", access: .none)]
        
        modifed = true
        
        if let file = entity as? ASCFile {
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Sharing.file(file: file), share.toJSON()) { response, error in
                if let error = error {
                    log.error(error)
                }
            }
        } else if let folder = entity as? ASCFolder {
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Sharing.folder(folder: folder), share.toJSON()) { response, error in
                if let error = error {
                    log.error(error)
                }
            }
        }
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
        if identifier == StoryboardSegue.Share.segueAccessShare.rawValue {
            if let sharedCell = sender as? ASCShareCell, sharedCell.share?.locked ?? true {
                return false
            }
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        let shareSegue = StoryboardSegue.Share(rawValue: identifier)
        
        switch shareSegue {
        case .segueAccessShare:
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
        case .segueAddShare:
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
        case .none:
            break
        }        
     }
}
