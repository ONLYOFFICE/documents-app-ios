//
//  ASCCreatePortalStatus.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03/06/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

enum ASCCreatePortalStatus: String, CaseIterable {
    case successReadyToRegister = "portalNameReadyToRegister"
    case failureTooShortError = "tooShortError"
    case failurePortalNameExist = "portalNameExist"
    case failurePortalNameIncorrect = "portalNameIncorrect"
    case failurePassPolicyError = "passPolicyError"
    case unknown = "unknown"

    init() {
        self = .unknown
    }

    init(_ type: String) {
        switch type {
        case "portalNameReadyToRegister": self = .successReadyToRegister
        case "tooShortError": self = .failureTooShortError
        case "portalNameExist": self = .failurePortalNameExist
        case "portalNameIncorrect": self = .failurePortalNameIncorrect
        case "passPolicyError": self = .failurePassPolicyError
        default: self = .unknown
        }
    }

    var description: String {
        switch self {
        case .failureTooShortError: return NSLocalizedString("The portal name must be between 6 and 50 characters long", comment: "")
        case .failurePortalNameExist: return  NSLocalizedString("We are sorry, this portal name is already taken", comment: "")
        case .failurePortalNameIncorrect: return  NSLocalizedString("Incorrect portal address", comment: "")
        case .failurePassPolicyError: return  NSLocalizedString("The password is incorrect. It must contain 8 characters", comment: "")
        case .unknown: return  NSLocalizedString("Failed to check the name of the portal", comment: "")
        default: return ""
        }
    }
}
