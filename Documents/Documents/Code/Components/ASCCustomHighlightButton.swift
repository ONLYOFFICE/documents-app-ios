//
//  ASCCustomHighlightButton.swift
//  Documents
//
//  Created by Alexander Yuzhin on 27/06/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCCustomHighlightButton: UIButton {
    // MARK: - Properties

    @IBInspectable var selectedCustomColor: UIColor = UIColor.white
    @IBInspectable var defaultBackgroundColor: UIColor = UIColor.white
    @IBInspectable var animateHighlight: Bool = false
    @IBInspectable var hapticFeedback: Bool = false

    // MARK: - Lifecycle Methods

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open var isHighlighted: Bool {
        didSet {
            applyStyles()

            if isHighlighted != oldValue, isHighlighted, hapticFeedback {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            }
        }
    }

    func applyStyles() {
        if animateHighlight {
            UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.backgroundColor = self.isHighlighted
                    ? self.selectedCustomColor
                    : self.defaultBackgroundColor
            })
        } else {
            backgroundColor = isHighlighted
                ? selectedCustomColor
                : defaultBackgroundColor
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        if isHighlighted {
            if animateHighlight {
                layer.removeAllAnimations()
            }
        }
    }
}
