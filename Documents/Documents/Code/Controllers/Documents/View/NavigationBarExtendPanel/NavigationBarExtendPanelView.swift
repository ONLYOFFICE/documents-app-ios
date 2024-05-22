//
//  NavigationBarExtendPanelView.swift
//  Documents
//
//  Created by Alexander Yuzhin on 20.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

final class NavigationBarExtendPanelView: UIView {
    // MARK: - Properties

    private(set) var contentView: NavigationBarExtendPanelContentViewProtocol?

    private let standardVisualEffect = UIBlurEffect(style: .systemThinMaterial)

    private let visualEffectView: UIVisualEffectView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIVisualEffectView())

    private let shadowView: UIView = {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = navigationBarAppearance.shadowColor
        return $0
    }(UIView())

    // MARK: - Lifecycle Methods

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(contentView: NavigationBarExtendPanelContentViewProtocol) {
        super.init(frame: .zero)
        self.contentView = contentView
        configure()
    }

    private func configure() {
        guard let contentView else { return }

        addSubview(visualEffectView)
        addSubview(contentView)
        addSubview(shadowView)
        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 0.0),
            contentView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 0.0),
            contentView.heightAnchor.constraint(equalToConstant: contentView.preferredHeight),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0.0),

            shadowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: trailingAnchor),
            shadowView.bottomAnchor.constraint(equalTo: bottomAnchor),
            shadowView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
        ])
    }

    func scrollEdgeAppearance() {
        shadowView.alpha = 0.0
        visualEffectView.effect = nil
    }

    func standardAppearance() {
        shadowView.alpha = 1.0
        visualEffectView.effect = standardVisualEffect
    }
}

@available(iOS 17, *)
#Preview {
    NavigationBarExtendPanelView()
}
