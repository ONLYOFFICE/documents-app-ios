//
//  TagsFieldView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 08.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import WSTagsField

struct TagsFieldView: View {
    @Binding var tags: Set<String>
    @State var text: String?
    @State var applyTag: Bool = false
    @State var addTagStr = NSLocalizedString("Add tag", comment: "placeholder")

    var body: some View {
        VStack(spacing: 0) {
            WSTagsFieldRepresentable(
                text: $text,
                applyTag: $applyTag,
                settingsApplyer: settingApplyer,
                tagChecker: { !$0.isEmpty && $0.isValidTagString }
            )
            .padding(.top, 8)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(8)

            if text?.isEmpty == false {
                applyingView
            }
        }
    }

    @ViewBuilder
    private var applyingView: some View {
        Rectangle()
            .frame(height: 4)
            .foregroundColor(Color(UIColor.clear))

        HStack {
            Text(addTagStr + ": \"\(text ?? "")\"")
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Spacer()
        }
        .background(Color.white)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            applyTag = true
        }
    }

    private func onUpdate(_ tagsField: WSTagsField) {}

    private func settingApplyer(_ tagsField: WSTagsField) {
        tagsField.onShouldAcceptTag = { field in
            field.text?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isValidTagString ?? false
        }
        tagsField.onDidAddTag = { textField, tag in
            if !tags.contains(tag.text) {
                DispatchQueue.main.async {
                    tags.formUnion([tag.text])
                }
            }
        }
        tagsField.onDidRemoveTag = { _, tag in
            DispatchQueue.main.async {
                tags.remove(tag.text)
            }
        }
        tagsField.layer.cornerRadius = 10
        tagsField.backgroundColor = .secondarySystemGroupedBackground
        tagsField.textField.returnKeyType = .go
        tagsField.placeholder = addTagStr
        tagsField.cornerRadius = 6.0
        tagsField.spaceBetweenLines = 16
        tagsField.spaceBetweenTags = 6
        tagsField.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        tagsField.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        tagsField.placeholderAlwaysVisible = true
        tagsField.tintColor = .systemGray6
        tagsField.textField.tintColor = .black
        tagsField.textColor = .link
        tagsField.selectedColor = Asset.Colors.brend.color
        tagsField.selectedTextColor = .white
        tagsField.enableScrolling = true
        tagsField.isScrollEnabled = true
        tagsField.showsVerticalScrollIndicator = true
    }
}

private extension String {
    var isValidTagString: Bool {
        let regex = "^[A-Za-z0-9_ ]+$"
        return range(of: regex, options: .regularExpression) != nil
    }
}
