//
//  ASCSortViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 4/11/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSortViewController: ASCBaseTableViewController {
    static let identifier = String(describing: ASCSortViewController.self)
    
    class override var storyboard: Storyboard { return Storyboard.sort }

    public typealias ASCSortTypes = (description: String, name: String, active: Bool)
    public typealias ASCSortComplation = (_ name: String, _ ascending: Bool) -> Void
    
    // MARK: - Properties

    var types: [ASCSortTypes] = []
    var ascending = false
    var onDone: ASCSortComplation?

    // MARK: - Outlets

    @IBOutlet weak var sortTypeLabel: UILabel!
    @IBOutlet weak var ascendingSwitch: UISwitch!
    @IBOutlet var sortTypeTable: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Button title"),
            style: .done,
            target: self,
            action: #selector(onDone(_:))
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Action

    @IBAction func onDone(_ sender: UIBarButtonItem) {
        if let option = types.first(where: { $0.2 }) {
            onDone?(option.1, ascending)
        }

        if let parentViewController = parent {
            parentViewController.dismiss(animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - Table view data source

extension ASCSortViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return types.count
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("Type", comment: "")
        } else if section == 1 {
            return NSLocalizedString("Order", comment: "")
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sortType = "cellSortType"
        let sortOrder = "cellSortOrder"

        if indexPath.section == 0 {
            if let sortTypeCell = tableView.dequeueReusableCell(withIdentifier: sortType) as? ASCSortViewCell {
                sortTypeCell.textLabel?.text = types[indexPath.row].0
                sortTypeCell.accessoryType = types[indexPath.row].2 ? .checkmark : .none

                return sortTypeCell
            }
        } else if indexPath.section == 1 {
            if let sortOrderCell = tableView.dequeueReusableCell(withIdentifier: sortOrder) as? ASCSortViewCell {
                sortOrderCell.ascendingSwitch?.isOn = ascending
                sortOrderCell.onAscendingChange = { [weak self] ascending in
                    self?.ascending = ascending
                }

                return sortOrderCell
            }
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for (index, option) in types.enumerated() {
            types[index] = (option.0, option.1, false)

            if index == indexPath.row {
                types[index] = (option.0, option.1, true)
            }
        }

        tableView.reloadData()
    }
}
