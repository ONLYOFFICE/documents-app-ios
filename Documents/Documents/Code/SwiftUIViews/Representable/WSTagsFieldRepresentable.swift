//
//  WSTagsFieldRepresentable.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 08.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import WSTagsField
import SwiftUI

struct WSTagsFieldRepresentable: UIViewRepresentable {
    
    @Binding var text: String?
    @Binding var applyTag: Bool
    @State var settingsApplyer: (WSTagsField) -> Void
    @State var tagChecker: (String) -> Bool
    
    let tagsField = WSTagsField()
    
    func makeUIView(context: Context) -> WSTagsField {
        setupTagsField(tagsField)
        return tagsField
    }
    
    func updateUIView(_ uiView: WSTagsField, context: Context) {
        uiView.text = text ?? ""
        if applyTag, let text = text, tagChecker(text) {
            uiView.removeTag(text)
            uiView.addTag(text)
            
        }
        applyTag = false
    }
    
    private func setupTagsField(_ tagsField: WSTagsField) {
        tagsField.onDidChangeText = { _, value in
            self.text = value
        }
        settingsApplyer(tagsField)
    }
}
