//
// SwiftAlertController.swift
// Copyright (c) 2016, zahlz
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import UIKit

extension UIAlertController {

    /**
     Create an alert style `UIAlertController`

     - parameter name: Title for the `UIAlertController`
     - parameter message: Message to display (default: `nil`)
     - parameter acceptMessage: Message in the accept button (default: "OK")
     - parameter handler: Handler for the button click (default: `nil`)

     - returns: An `UIAlertController`

     */
    class func alert(
        _ name: String,
        message: String? = nil,
        acceptMessage: String = "OK",
        handler: ((UIAlertAction) -> Void)? = nil
        ) -> UIAlertController {

        return UIAlertController.alert(name, message: message, actions: [UIAlertAction(title: acceptMessage, style: .cancel, handler: handler)])

    }

    /**
     Create an alert style `UIAlertController`

     - parameter name: Title for the `UIAlertController`
     - parameter message: Message to display (default: `nil`)
     - parameter actions: Array with the `UIAlertAction`s

     - returns: An `UIAlertController`

     */
    class func alert(
        _ name: String,
        message: String? = nil,
        actions: [UIAlertAction],
        tintColor: UIColor? = nil
        ) -> UIAlertController {

        let alertController =  UIAlertController(title: name, message: message, preferredStyle: .alert)
        alertController.view.tintColor = tintColor ?? ASCConstants.Colors.brend

        actions.forEach(alertController.addAction)

        return alertController

    }

    /**
     Create an alert style `UIAlertController`

     - parameter name: Title for the `UIAlertController`
     - parameter message: Message to display (default: `nil`)
     - parameter actionHandler: Closure which returns the `UIAlertAction`s

     - returns: An `UIAlertController`

     */
    class func alert(
        _ name: String,
        message: String? = nil,
        actionHandler: (() -> [UIAlertAction])
        ) -> UIAlertController {

        return UIAlertController.alert(name, message: message, actions: actionHandler())

    }

    /**
     Create an actionSheet style `UIAlertController`

     - parameter name: Title for the `UIAlertController`
     - parameter message: Message to display (default: `nil`)
     - parameter actions: Array with the `UIAlertAction`s (default: `nil`)

     - returns `UIAlertController`
     */
    class func sheet(
        _ name: String,
        message: String? = nil,
        actions: [UIAlertAction]? = nil
        ) -> UIAlertController {

        let alertController =  UIAlertController(title: name, message: message, preferredStyle: .actionSheet)

        actions?.forEach(alertController.addAction)

        return alertController

    }

    /**
     Create an actionSheet style `UIAlertController`

     - parameter name: Title for the `UIAlertController`
     - parameter message: Message to display (default: `nil`)
     - parameter actionHandler: Closure which returns the `UIAlertAction`s

     - returns `UIAlertController`
     */
    class func sheet(
        _ name: String,
        message: String? = nil,
        actionHandler: (() -> [UIAlertAction])
        ) -> UIAlertController {

        return UIAlertController.sheet(name, message: message, actions: actionHandler())

    }

    /**
     Adds an action to an `UIAlertController` and is chainable

     - parameter title: Title for the action
     - parameter style: Style of the action (default: `.default`)
     - parameter handler: Handler for the action (default: `nil`)

     - returns: UIAlertController with added action
     */
    func action(
        title: String,
        style: UIAlertAction.Style = .default,
        handler: ((UIAlertAction) -> Void)? = nil
        ) -> UIAlertController {

        addAction(title: title, style: style, handler: handler)

        return self

    }

    /**
     Adds an okay action to the UIAlertController

     - parameter handler: Handler for the action (default: `nil`)

     - returns UIAlertController with added action
     */
    func okable(
        handler: ((UIAlertAction) -> Void)? = nil
        ) -> UIAlertController {

        addOk(handler: handler)

        return self

    }

    /**
     Add a cancel action to the UIAlertViewController

     - parameter handler: Handler for the action (default: `nil`)

     - returns: UIAlertController with added action
     */
    func cancelable(
        handler: ((UIAlertAction) -> Void)? = nil
        ) -> UIAlertController {

        addCancel(handler: handler)

        return self

    }

    /**
     Adds an action to an UIAlertController

     - parameter title: Title for the action
     - parameter style: Style of the action (default: `.default`)
     - parameter handler: Handler for the action (default: `nil`)

     */
    func addAction(
        title: String,
        style: UIAlertAction.Style = .default,
        handler: ((UIAlertAction) -> Void)? = nil
        ) {

        let action = UIAlertAction(title: title, style: style, handler: handler)

        addAction(action)

    }

    /**
     Adds an okay action to the UIAlertController

     - parameter handler: Handler for the action (default: `nil`)

     */
    func addOk(handler: ((UIAlertAction) -> Void)? = nil) {

        addAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: handler)

    }

    /**
     Add a cancel action to the UIAlertViewController

     - parameter handler: Handler for the action (default: `nil`)

     */
    func addCancel(handler: ((UIAlertAction) -> Void)? = nil) {

        addAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel,
            handler: handler
        )
    }

}

extension UIAlertAction {

    /**
     Create and return an action with the specified title and behavior.
     Actions are enabled by default when you create them.

     - parameter title: The text to use for the button title.
     The value you specify should be localized for the user’s current language.
     This parameter must not be nil, except in a tvOS app
     where a nil title may be used with cancel. (default: `nil`)

     - parameter handler: A block to execute when the user selects the action.
     This block has no return value and takes the selected action object as its only parameter.
     (default: `nil`)

     */
    convenience init(
        title: String?,
        handler: ((UIAlertAction) -> Void)? = nil
        ) {

        self.init(title: title, style: .default, handler: handler)

    }

    /**
     Appends an UIAlertAction to this one and returns a array of UIAlertActions

     - parameter title: The text to use for the button title.
     The value you specify should be localized for the user’s current language.
     This parameter must not be nil, except in a tvOS app
     where a nil title may be used with cancel.
     - parameter style: Additional styling information to apply to the button.
     Use the style information to convey the type of action that is performed by the button.
     For a list of possible values, see the constants in UIAlertActionStyle.
     (default: `.default`)
     - parameter handler: A block to execute when the user selects the action.
     This block has no return value and takes the selected action object as its only parameter.
     (default: `nil`)

     - returns: Array with the `UIAlertAction`s
     */
    func appending(
        title: String,
        style: UIAlertAction.Style = .default,
        handler: ((UIAlertAction) -> Void)? = nil
        ) -> [UIAlertAction] {

        return [self, UIAlertAction(title: title, style: style, handler: handler)]

    }
}

extension Collection where Iterator.Element == UIAlertAction {

    /**
     Appends an UIAlertAction to this array and returns a array of UIAlertActions

     - parameter title: The text to use for the button title.
     The value you specify should be localized for the user’s current language.
     This parameter must not be nil, except in a tvOS app
     where a nil title may be used with cancel.
     - parameter style: Additional styling information to apply to the button.
     Use the style information to convey the type of action that is performed by the button.
     For a list of possible values, see the constants in UIAlertActionStyle.
     (default: `.default`)
     - parameter handler: A block to execute when the user selects the action.
     This block has no return value and takes the selected action object as its only parameter.
     (default: `nil`)
     
     - returns: Array with the `UIAlertAction`s
     */
    func appending(
        title: String,
        style: UIAlertAction.Style = .default,
        handler: ((UIAlertAction) -> Void)? = nil
        ) -> [UIAlertAction] {
        
        return self + [UIAlertAction(title: title, style: style, handler: handler)]
        
    }
    
}
