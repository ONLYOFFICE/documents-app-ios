//
//  ASCCategorySegmentControl.swift
//  Documents
//
//  Created by Alexander Yuzhin on 20.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

final class ASCCategorySegmentControl: UIScrollView {
    // MARK: - Properties

    var items: [ASCSegmentCategory] = [] {
        didSet {
            updateData()
        }
    }

    var selectIndex: Int? {
        didSet {
            select(index: selectIndex)
        }
    }

    var paddings: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    var spaces: CGFloat = 20
    var activeColor = Asset.Colors.brend.color
    var defaultColor = UIColor.secondaryLabel

    var onChange: ((_ category: ASCSegmentCategory) -> Void)?

    private lazy var stackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .horizontal
        $0.spacing = 20
        $0.alignment = .fill
        return $0
    }(UIStackView())

    private lazy var underlineView: UIView = {
        $0.backgroundColor = activeColor
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 3
        $0.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        return $0
    }(UIView(frame: CGRect(x: 0, y: 100, width: 0, height: 0)))

    private lazy var shadowLineLayer: CALayer = {
        $0.backgroundColor = UIColor.opaqueSeparator.cgColor
        return $0
    }(CALayer())

    // MARK: - Lifecycle Methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowLineLayer.frame = CGRect(
            origin: CGPoint(x: -1000, y: frame.height - 1),
            size: CGSize(width: 2000, height: 1.0 / UIScreen.main.scale)
        )

        moveUnderline()
    }

    private func configureView() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false

        addSubview(stackView)
        layer.addSublayer(shadowLineLayer)
        addSubview(underlineView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: paddings.left),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -paddings.right),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: heightAnchor),
        ])

        updateData()
        select(index: selectIndex)
    }

    private func updateData() {
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }

        for (index, item) in items.enumerated() {
            let button = makeTab(with: item)
            button.tag = index
            button.addTarget(self, action: #selector(onTabTapped), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            guard let self else { return }
            self.select(index: self.selectIndex, animated: false)
        }
    }

    private func makeTab(with category: ASCSegmentCategory) -> UIButton {
        {
            $0.setTitle(category.title, for: .normal)
            $0.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
            $0.setTitleColor(defaultColor, for: .normal)
            $0.setTitleColor(activeColor, for: .highlighted)
            $0.setTitleColor(activeColor, for: .selected)
            return $0
        }(UIButton(type: .custom))
    }

    private func moveUnderline() {
        guard
            let selectedButton = stackView.arrangedSubviews.first(where: { $0.tag == selectIndex }) as? UIButton
        else { return }

        underlineView.frame = CGRect(
            origin: CGPoint(x: selectedButton.frame.minX + stackView.spacing - 4, y: selectedButton.frame.maxY - 4),
            size: CGSize(width: selectedButton.frame.width, height: 4)
        )
    }

    private func select(index: Int?, animated: Bool = true) {
        let buttons = stackView.arrangedSubviews.map { $0 as? UIButton }
        for button in buttons {
            button?.isSelected = false
        }

        guard
            let index,
            let selectedButton = stackView.arrangedSubviews.first(where: { $0.tag == index }) as? UIButton
        else {
            underlineView.isHidden = true
            return
        }

        underlineView.isHidden = false

        selectedButton.isSelected = true

        if animated {
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.moveUnderline()
            }
        } else {
            UIView.performWithoutAnimation { [weak self] in
                self?.moveUnderline()
            }
        }

        var rect = selectedButton.frame
        rect.size.width += (paddings.left + spaces)
        scrollRectToVisible(rect, animated: animated)
    }

    @objc private func onTabTapped(_ sender: UIButton) {
        guard sender.tag != selectIndex else { return }
        selectIndex = sender.tag
        onChange?(items[sender.tag])
    }
}

extension ASCCategorySegmentControl: NavigationBarExtendPanelContentViewProtocol {
    var preferredHeight: CGFloat {
        44
    }
}

@available(iOS 17, *)
#Preview {
    let view = ASCCategorySegmentControl()
    view.items = [
        ASCSegmentCategory(title: "One", folder: ASCFolder()),
        ASCSegmentCategory(title: "Two not been implemented", folder: ASCFolder()),
        ASCSegmentCategory(title: "Three not been implemented", folder: ASCFolder()),
    ]
    view.selectIndex = 1
    return view
}
