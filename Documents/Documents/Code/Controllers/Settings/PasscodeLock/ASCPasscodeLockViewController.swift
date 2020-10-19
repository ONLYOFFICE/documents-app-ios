//
//  ASCPasscodeLockViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/22/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import LocalAuthentication

enum ASCBiometryType: Int {
    case none, touchID, faceID
}

class ASCPasscodeLockViewController: UITableViewController {

    // MARK: - Properties
    
    fileprivate var configuration: PasscodeLockConfigurationType
    @IBOutlet weak var touchUnlockSwitch: UISwitch!
    @IBOutlet weak var unlockBiometricLabel: UILabel!
    
    // MARK: - Lifecycle Methods
    
    required init?(coder aDecoder: NSCoder) {
        let repository = ASCUserDefaultsPasscodeRepository()
        configuration = ASCPasscodeLockConfiguration(repository: repository)
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePasscodeView()
        
        if UIDevice.pad {
            navigationController?.navigationBar.prefersLargeTitles = false
            
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if UIDevice.pad {
            guard let navigationBar = navigationController?.navigationBar else { return }
            
            let transparent = (navigationBar.y + navigationBar.height + scrollView.contentOffset.y) > 0
            
            navigationBar.setBackgroundImage(transparent ? nil : UIImage(), for: .default)
            navigationBar.shadowImage = transparent ? nil : UIImage()
        }
    }
    
    func updatePasscodeView() {
        let hasPasscode = configuration.repository.hasPasscode

        if let turnCell = tableView.cellForRow(at: IndexPath(item: 0, section: 0)) {
            turnCell.textLabel?.text = hasPasscode
                ? NSLocalizedString("Turn Passcode Off", comment: "")
                : NSLocalizedString("Turn Passcode On", comment: "")
        }
        
        touchUnlockSwitch?.isOn = biometricsType() != .none && UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.allowTouchId)

        if biometricsType() != .none {
            unlockBiometricLabel?.text = biometricsType() == .faceID
                ? NSLocalizedString("Unlock with Face ID", comment: "")
                : NSLocalizedString("Unlock with Touch ID", comment: "")
        }
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        let hasPasscode = configuration.repository.hasPasscode
        return hasPasscode ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            let hasPasscode = configuration.repository.hasPasscode
            return hasPasscode ? 2 : 1
        } else {
            return biometricsType() != .none ? 1 : 0
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            let passcodeViewController: PasscodeLockViewController
            let hasPasscode = configuration.repository.hasPasscode
            
            if !hasPasscode {
                passcodeViewController = PasscodeLockViewController(state: .setPasscode, configuration: configuration)
            } else {
                passcodeViewController = PasscodeLockViewController(state: .removePasscode, configuration: configuration)
                passcodeViewController.successCallback = { lock in
                    lock.repository.deletePasscode()
                    self.updatePasscodeView()
                }
            }

            passcodeViewController.modalPresentationStyle = .fullScreen

            present(passcodeViewController, animated: true, completion: nil)
        } else if indexPath.row == 1 {
            let repo = ASCUserDefaultsPasscodeRepository()
            let config = ASCPasscodeLockConfiguration(repository: repo)
            let passcodeViewController = PasscodeLockViewController(state: .changePasscode, configuration: config)
            
            passcodeViewController.modalPresentationStyle = .fullScreen

            present(passcodeViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Private
    
    fileprivate func biometricsType() -> ASCBiometryType {
        let context = LAContext()
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            if #available(iOS 11.0, *) {
                if context.biometryType == .faceID {
                    return .faceID
                } else if context.biometryType == .touchID {
                    return .touchID
                }
            } else {
                return .touchID
            }
        }
        return .none
    }
    
    // MARK: - Actions

    @IBAction func onAllowTouchID(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: ASCConstants.SettingsKeys.allowTouchId)
    }
}
