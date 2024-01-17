//
//  PasscodeLockStyles.swift
//

#if os(iOS)

import UIKit

public enum PasscodeLockStyles {
    public static var overrideUserInterfaceStyle: UIUserInterfaceStyle = .unspecified

    public static var backgroundColor: UIColor = .systemBackground
    public static var textColor: UIColor = .link

    public enum SignPlaceholderViewStyles {
        public static var inactiveColor: UIColor = .systemBackground
        public static var activeColor: UIColor = .link
        public static var errorColor: UIColor = .red
    }

    public enum SignButtonStyles {
        public static var textColor: UIColor = .link
        public static var borderColor: UIColor = .link
        public static var highlightBackgroundColor: UIColor = .link
    }
}

#endif
