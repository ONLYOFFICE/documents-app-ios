//
//  EditorViewControllerProtocol.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.06.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import DocumentEditor
import PresentationEditor
import SpreadsheetEditor

protocol EditorViewControllerProtocol {}

extension DocumentEditorViewController: EditorViewControllerProtocol {}
extension PresentationEditorViewController: EditorViewControllerProtocol {}
extension SpreadsheetEditorViewController: EditorViewControllerProtocol {}
