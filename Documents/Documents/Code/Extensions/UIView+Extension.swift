//
//  UIView+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 9/10/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UIView {
    
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "position.x")
        
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.duration = 0.3
        animation.values = [ 0.0, 20.0, -20.0, 10.0, 0.0 ]
        animation.keyTimes = [ 0.0, NSNumber(value: 1.0 / 6.0), NSNumber(value: 3.0 / 6.0), NSNumber(value: 5.0 / 6.0), 1.0 ]
        animation.isAdditive = true
        
        layer.add(animation, forKey: "shake")
    }

    @IBInspectable var layerCornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var layerBorderWidth: CGFloat {
        get {
            return layer.borderWidth * UIScreen.main.scale
        }
        set {
            layer.borderWidth = newValue / UIScreen.main.scale
        }
    }

    @IBInspectable var layerBorderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }

    /// Size of view.
    var size: CGSize {
        get {
            return frame.size
        }
        set {
            width = newValue.width
            height = newValue.height
        }
    }

    /// Get view's parent view controller
    var parentViewController: UIViewController? {
        weak var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }

    /// Width of view.
    var width: CGFloat {
        get {
            return frame.size.width
        }
        set {
            frame.size.width = newValue
        }
    }

    /// Height of view.
    var height: CGFloat {
        get {
            return frame.size.height
        }
        set {
            frame.size.height = newValue
        }
    }

    /// x origin of view.
    // swiftlint:disable:next identifier_name
    var x: CGFloat {
        get {
            return frame.origin.x
        }
        set {
            frame.origin.x = newValue
        }
    }

    /// y origin of view.
    // swiftlint:disable:next identifier_name
    var y: CGFloat {
        get {
            return frame.origin.y
        }
        set {
            frame.origin.y = newValue
        }
    }

    func clone<T: UIView>() -> T {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as! T
    }

    func showSkeleton(
        _ show: Bool,
        animeted: Bool,
        inserts: UIEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: 1, right: 0),
        radius: CGFloat = 6)
    {
        if show {
            if let _ = layer.sublayers?.first?.animation(forKey: "backgroundColor") {
                return
            }

            CATransaction.begin()

            let animation = CABasicAnimation(keyPath: "backgroundColor")
            animation.fromValue = ASCConstants.Colors.lighterGrey.cgColor
            animation.toValue = animeted ? UIColor(hex: "#dddfe0").cgColor : ASCConstants.Colors.lighterGrey.cgColor
            animation.duration = 0.5
            animation.isRemovedOnCompletion = false
            animation.repeatCount = Float.infinity
            animation.autoreverses = true

            let solidLayer = CALayer()
            solidLayer.frame = bounds.inset(by: inserts)
            solidLayer.cornerRadius = radius

            solidLayer.add(animation, forKey: "backgroundColor")
            layer.insertSublayer(solidLayer, at:0)

            CATransaction.commit()
        } else {
            if let _ = layer.sublayers?.first?.animation(forKey: "backgroundColor") {
                layer.sublayers?.first?.removeAllAnimations()
                layer.sublayers?.first?.removeFromSuperlayer()
            }
        }
    }

    /// Load view from nib.
    ///
    /// - Parameters:
    ///   - name: nib name.
    ///   - bundle: bundle of nib (default is nil).
    /// - Returns: optional UIView (if applicable).
    public class func loadFromNib(named name: String, bundle: Bundle? = nil) -> UIView? {
        return UINib(nibName: name, bundle: bundle).instantiate(withOwner: nil, options: nil)[0] as? UIView
    }

    /// Anchor center X into current view's superview with a constant margin value.
    ///
    /// - Parameter constant: constant of the anchor constraint (default is 0).
    @available(iOS 9, *)
    func anchorCenterXToSuperview(constant: CGFloat = 0) {
        // https://videos.letsbuildthatapp.com/
        translatesAutoresizingMaskIntoConstraints = false
        if let anchor = superview?.centerXAnchor {
            centerXAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        }
    }

    /// Anchor center Y into current view's superview with a constant margin value.
    ///
    /// - Parameter withConstant: constant of the anchor constraint (default is 0).
    @available(iOS 9, *)
    func anchorCenterYToSuperview(constant: CGFloat = 0) {
        // https://videos.letsbuildthatapp.com/
        translatesAutoresizingMaskIntoConstraints = false
        if let anchor = superview?.centerYAnchor {
            centerYAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        }
    }

    /// Anchor center X and Y into current view's superview
    @available(iOS 9, *)
    func anchorCenterSuperview() {
        // https://videos.letsbuildthatapp.com/
        anchorCenterXToSuperview()
        anchorCenterYToSuperview()
    }
    
    /// Anchor all sides of the view into it's superview.
     @available(iOS 9, *)
     func fillToSuperview() {
         // https://videos.letsbuildthatapp.com/
         translatesAutoresizingMaskIntoConstraints = false
         if let superview = superview {
             let left = leftAnchor.constraint(equalTo: superview.leftAnchor)
             let right = rightAnchor.constraint(equalTo: superview.rightAnchor)
             let top = topAnchor.constraint(equalTo: superview.topAnchor)
             let bottom = bottomAnchor.constraint(equalTo: superview.bottomAnchor)
             NSLayoutConstraint.activate([left, right, top, bottom])
         }
     }
}
