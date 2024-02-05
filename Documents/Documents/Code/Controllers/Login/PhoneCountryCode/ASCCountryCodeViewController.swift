//
//  ASCCountryCodeViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/10/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import PhoneNumberKit
import UIKit

class ASCCountryCodeViewController: ASCBaseTableViewController {
    override class var storyboard: Storyboard { return Storyboard.login }

    typealias PhoneCountresByLetter = (literal: Character, countries: [ASCPhoneCountryCode])

    // MARK: - Properties

    var selectCountry: ((ASCPhoneCountryCode) -> Void)?

    private let phoneNumberKit = PhoneNumberKit()
    private var countresByLetter: [PhoneCountresByLetter] = []

    // Search
    private lazy var searchController: UISearchController = {
        $0.delegate = self
        $0.searchResultsUpdater = self
        $0.hidesNavigationBarDuringPresentation = false
        $0.searchBar.searchBarStyle = .minimal

        navigationItem.searchController = $0
        navigationItem.hidesSearchBarWhenScrolling = false

        return $0
    }(UISearchController(searchResultsController: nil))

    private lazy var searchBackground: UIView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        $0.backgroundColor = .white
        return $0
    }(UIView())

    private lazy var searchSeparator: UIView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        $0.backgroundColor = .lightGray
        return $0
    }(UIView())

    private var searchQuery: String = ""

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundView = UIView()
        tableView.tableFooterView = UIView()

        // Prepare data
        fetchData()

        navigationItem.searchController = searchController
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.phone ? .portrait : [.portrait, .landscape]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIDevice.phone ? .portrait : super.preferredInterfaceOrientationForPresentation
    }

    // MARK: - Private

    private func fetchData() {
        let allCountries = phoneNumberKit.allCountries()
        var phoneCountries: [ASCPhoneCountryCode] = []
        var search: String?

        countresByLetter.removeAll()

        if searchController.isActive {
            if let searchText = searchController.searchBar.text?.trimmed.lowercased(), searchText.length > 0 {
                search = searchText
            }
        }

        let validCountries = allCountries.filter { $0 != "001" }

        for country in validCountries {
            if let countryName = Locale.current.localizedString(forRegionCode: country),
               let code = phoneNumberKit.countryCode(for: country)
            {
                if let searchText = search {
                    if countryName.lowercased().contains(searchText) {
                        phoneCountries.append(
                            ASCPhoneCountryCode(
                                country: countryName,
                                code: code,
                                region: country
                            )
                        )
                    }
                } else {
                    phoneCountries.append(
                        ASCPhoneCountryCode(
                            country: countryName,
                            code: code,
                            region: country
                        )
                    )
                }
            }
        }

        countresByLetter = Dictionary(
            grouping: phoneCountries.sorted { $0.country.uppercased() < $1.country.uppercased() },
            by: { phoneCountry in
                phoneCountry.country.uppercased().first!
            }
        )
        .map { (key: String.Element, value: [ASCPhoneCountryCode]) in
            (literal: key, countries: value)
        }
        .sorted { left, right -> Bool in
            left.literal < right.literal
        }
    }
}

// MARK: - Table view data source

extension ASCCountryCodeViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        countresByLetter.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        countresByLetter[section].countries.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        String(countresByLetter[section].literal)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellCountryCode", for: indexPath)
        let phoneCountry = countresByLetter[indexPath.section].countries[indexPath.row]

        cell.textLabel?.text = phoneCountry.country
        cell.detailTextLabel?.text = "+\(phoneCountry.code)"

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectCountry?(countresByLetter[indexPath.section].countries[indexPath.row])
        navigationController?.popViewController(animated: true)
    }

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if index == 0 {
            tableView.contentOffset = CGPoint(x: 0, y: -64)
            return NSNotFound
        }

        return index - 1
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        var indexes = countresByLetter.map { String($0.literal) }
        indexes.insert(UITableView.indexSearch, at: 0)
        return indexes
    }
}

// MARK: - UISearchController Delegate

extension ASCCountryCodeViewController: UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        fetchData()
        tableView.reloadData()
    }
}

// MARK: - UISearchResults Updating

extension ASCCountryCodeViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        fetchData()
        tableView.reloadData()
    }
}
