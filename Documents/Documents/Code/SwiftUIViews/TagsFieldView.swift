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
            .padding(.top, 3)
            .padding(.bottom, tags.count > 0 ? 0 : 8)
            .padding(.horizontal, 16)
            .background(Color.secondarySystemGroupedBackground)
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
            .foregroundColor(.clear)

        HStack {
            Text(addTagStr + ": \"\(text ?? "")\"")
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Spacer()
        }
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            applyTag = true
        }
    }

    private func onUpdate(_ tagsField: WSTagsField) {}

    private func settingApplyer(_ tagsField: WSTagsField) {
        let existingTagsArray: [String] = Array(tags)

        tagsField.addTags(existingTagsArray)
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

        tagsField.backgroundColor = .secondarySystemGroupedBackground
        tagsField.textField.returnKeyType = .continue
        tagsField.placeholder = addTagStr
        tagsField.cornerRadius = 6
        tagsField.spaceBetweenLines = 16
        tagsField.spaceBetweenTags = 8
        tagsField.layoutMargins = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        tagsField.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
        tagsField.placeholderAlwaysVisible = true
        tagsField.tintColor = .systemGray6
        tagsField.textField.tintColor = .label
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
        let regex = "^[\\w0-9_ ]+$"
        return range(of: regex, options: .regularExpression) != nil
    }
}

#Preview {
    TagsFieldView(tags: .constant([]))
}
