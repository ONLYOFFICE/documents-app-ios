//
//  ASCLocalization.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/09/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCLocalization {
    enum Common {
        static let cancel = NSLocalizedString("common.cancel", tableName: nil, bundle: Bundle.main, value: "Cancel", comment: "Cancel")
        static let ok = NSLocalizedString("common.ok", tableName: nil, bundle: Bundle.main, value: "OK", comment: "OK")
        static let error = NSLocalizedString("common.error", tableName: nil, bundle: Bundle.main, value: "Error", comment: "Error")
        static let me = NSLocalizedString("common.me", tableName: nil, bundle: Bundle.main, value: "Me", comment: "Myself")
    }

    enum Error {
        static let paymentRequiredTitle = NSLocalizedString("common.paymentRequiredTitle", tableName: nil, bundle: Bundle.main, value: "Payment required", comment: "Payment required title")
        static let paymentRequiredMsg = NSLocalizedString("common.paymentRequiredMsg", tableName: nil, bundle: Bundle.main, value: "The paid period is over", comment: "Payment required message")
        static let forbiddenTitle = NSLocalizedString("error.errorForbiddenTitle", tableName: nil, bundle: Bundle.main, value: "Access is Forbidden", comment: "Access is Forbidden title")
        static let forbiddenMsg = NSLocalizedString("error.errorForbiddenMsg", tableName: nil, bundle: Bundle.main, value: "Contact the portal administrator for access to the resource.", comment: "Access is Forbidden message")
        static let notFoundTitle = NSLocalizedString("error.errorNotFoundMsg", tableName: nil, bundle: Bundle.main, value: "The resource can not be found", comment: "The resource can not be found Title")
        static let unknownTitle = NSLocalizedString("error.errorServerTitle", tableName: nil, bundle: Bundle.main, value: "Server Error", comment: "Unknown Server Error")
    }
}
