//
//  ASCShareItemsViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/7/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCShareItemsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating {

    // MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var typeControl: UISegmentedControl!
    @IBOutlet weak var categoryTopConstarint: NSLayoutConstraint!
    @IBOutlet weak var categoryBackgroundView: UIView!
    @IBOutlet var emptyView: UIView!
    @IBOutlet var loadingView: UIView!
    
    private var users: [(ASCShareInfo, Bool)] = []
    private var groups: [(ASCShareInfo, Bool)] = []
    private var tableData: [(ASCShareInfo, Bool)] = []
    private var access: ASCShareAccess = .read
    
    var showUsers: Bool = true {
        didSet {
            updateInfo()
        }
    }
    var allowReview: Bool = false
    var existUsers: [ASCShareInfo] = []
    var existGroups: [ASCShareInfo] = []
    var callback: (([ASCShareInfo]) -> ())? = nil
    
    // Search
    private var searchController: UISearchController!
    private var searchBackground: UIView!
    private var searchSeparator: UIView!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView?.backgroundView = UIView()
        tableView?.tableFooterView = UIView()
        tableView?.setEditing(true, animated: false)
        
        if allowReview {
            typeControl?.insertSegment(withTitle: NSLocalizedString("Review", comment: "Share status"), at: 3, animated: false)
        }
        
        configureSearchController()
        showLoadingView(true)
        fillData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        var result: [ASCShareInfo] = []
        
        result = (showUsers ? users : groups)
            .map({ (share, selected) in
                if selected {
                    var localShare = share
                    localShare.access = self.access
                    localShare.locked = false
                    return localShare
                }
                return nil
            })
            .compactMap{ $0 }
        
        
        callback?(result)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func configureSearchController() {
        // Initialize and perform a minimum configuration to the search controller.
        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        definesPresentationContext = true
        searchController.searchBar.tintColor = view.tintColor
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = true
        } else {
            searchController.searchBar.isHidden = true
            tableView.tableHeaderView = searchController.searchBar
        }
        
        searchBackground = UIView()
        searchSeparator = UIView()
    }
    
    func fillData() {
        users.removeAll()
        groups.removeAll()
        
        ASCOnlyOfficeApi.get(showUsers ? ASCOnlyOfficeApi.apiUsers : ASCOnlyOfficeApi.apiGroups) { (results, error, response) in
            self.showLoadingView(false)
            
            if let results = results as? [[String: Any]] {
                self.users.removeAll()
                self.groups.removeAll()
                
                if self.showUsers {
                    for item in results {
                        if let user = ASCUser(JSON: item) {
                            var share = ASCShareInfo()
                            share.user = user
                            share.locked = true
                            self.users.append((share, false))
                        }
                    }
                } else {
                    for item in results {
                        if let group = ASCGroup(JSON: item) {
                            var share = ASCShareInfo()
                            share.group = group
                            share.locked = true
                            
                            self.groups.append((share, false))
                        }
                    }
                }
            }
            
            self.prepareData()
        }
    }
    
    private func updateInfo() {
        title = showUsers ? NSLocalizedString("Users", comment: "") : NSLocalizedString("Groups", comment: "")
    }
    
    private func prepareData() {
        if showUsers {
            let userIds: [String] = existUsers.map { $0.user?.userId ?? "" }
            
            let filterUsers = users
                .sorted(by: { $0.0.user?.lastName ?? "" < $1.0.user?.lastName ?? "" })
                .filter { !userIds.contains($0.0.user?.userId ?? "") }
            
            users = filterUsers
            tableData = users
        } else {
            let groupIds: [String] = existGroups.map { $0.group?.id ?? "" }
            
            let filterGroups = groups
                .sorted(by: { $0.0.group?.name ?? "" < $1.0.group?.name ?? "" })
                .filter { !groupIds.contains($0.0.group?.id ?? "") }
            
            groups = filterGroups
            tableData = groups
        }
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = tableData.count < 1 ? nil : searchController
        } else {
            searchController.searchBar.isHidden = tableData.count < 1
        }
        
        tableView.reloadData()
        showEmptyView(tableData.count < 1)
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
        if show {
            tableView.addSubview(emptyView)
            
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            emptyView.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive = true
        } else {
            emptyView.removeFromSuperview()
        }
    }

    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ShareItemCell", for: indexPath) as? ASCShareCell {
            cell.share = tableData[indexPath.row].0
            
            if showUsers {
                let titleFont = cell.title.font ?? UIFont.systemFont(ofSize: 16)
                let firstName = cell.share?.user?.firstName ?? ""
                let lastName = cell.share?.user?.lastName ?? ""
                let attrFirstName = NSAttributedString(string: firstName)
                let attrLastName = NSAttributedString(string: " " + lastName, attributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: titleFont.pointSize)
                    ])
                
                let combination = NSMutableAttributedString()
                
                combination.append(attrFirstName)
                combination.append(attrLastName)
                
                cell.title.attributedText = combination
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableData[indexPath.row].1 {
            cell.setSelected(true, animated: false)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ASCShareCell {
            tableData[indexPath.row].1 = cell.isSelected
            
            if showUsers {
                if let index = users.firstIndex(where: { $0.0.user?.userId == cell.share?.user?.userId }) {
                    users[index].1 = cell.isSelected
                }
            } else {
                if let index = groups.firstIndex(where: { $0.0.group?.id == cell.share?.group?.id }) {
                    groups[index].1 = cell.isSelected
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ASCShareCell {
            tableData[indexPath.row].1 = cell.isSelected
            
            if showUsers {
                if let index = users.firstIndex(where: { $0.0.user?.userId == cell.share?.user?.userId }) {
                    users[index].1 = cell.isSelected
                }
            } else {
                if let index = groups.firstIndex(where: { $0.0.group?.id == cell.share?.group?.id }) {
                    groups[index].1 = cell.isSelected
                }
            }
        }
    }

    // MARK: - UISearchResults Updating
    
    public func updateSearchResults(for searchController: UISearchController) {
        if searchController.isActive {
            if let searchText = searchController.searchBar.text?.trimmed.lowercased(), searchText.length > 0 {
                if showUsers {
                    tableData = users.filter() { info in
                        let displayName = info.0.user?.displayName
                        return displayName?.lowercased().range(of: searchText) != nil
                    }
                } else {
                    tableData = groups.filter() { info in
                        let displayName = info.0.group?.name                       
                        return displayName?.lowercased().range(of: searchText) != nil
                    }
                }
            } else {
                tableData = showUsers ? users : groups
            }
        }
        
        tableView.reloadData()
        showEmptyView(tableData.count < 1)
    }
    
    // MARK: - UISearchController Delegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        categoryTopConstarint.constant = -categoryBackgroundView.frame.height

        UIView.animate(withDuration: 0.3) {
            self.categoryBackgroundView.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        searchSeparator.alpha = 0
        
        tableData = showUsers ? users : groups
        tableView.reloadData()
        showEmptyView(tableData.count < 1)
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        if #available(iOS 11.0, *) {
            //
        } else {
            searchBackground.frame = CGRect(x: 0, y: 0, width: searchController.searchBar.frame.size.width, height: searchController.searchBar.frame.size.height + ASCCommon.statusBarHeight)
            searchBackground.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            searchBackground.backgroundColor = .white
            searchController.view?.insertSubview(searchBackground, at: 0)
            
            searchSeparator.frame = CGRect(x: 0, y: searchController.searchBar.frame.size.height + ASCCommon.statusBarHeight, width: searchController.searchBar.frame.size.width, height: 1.0 / UIScreen.main.scale)
            searchSeparator.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            searchSeparator.backgroundColor = .lightGray
            searchSeparator.alpha = 1
            searchController.view?.insertSubview(searchSeparator, at: 0)
        }
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        categoryTopConstarint.constant = 0
        searchSeparator.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            self.categoryBackgroundView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onTypeChange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
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
