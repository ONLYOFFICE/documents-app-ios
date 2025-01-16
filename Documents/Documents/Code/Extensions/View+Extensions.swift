//
//  View+Extensions.swift
//  Documents
//
//  Created by Pavel Chernyshev on 20.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//
import Combine
import Foundation
import SwiftUI

// MARK: - Navigation

extension View {
    func onNavigation(_ action: @escaping () -> Void) -> some View {
        let isActive = Binding(
            get: { false },
            set: { newValue in
                if newValue {
                    action()
                }
            }
        )
        return NavigationLink(
            destination: EmptyView(),
            isActive: isActive
        ) {
            self
        }
    }

    func navigation<Item, Destination: View>(
        item: Binding<Item?>,
        @ViewBuilder destination: (Item) -> Destination
    ) -> some View {
        let isActive = Binding(
            get: { item.wrappedValue != nil },
            set: { value in
                if !value {
                    item.wrappedValue = nil
                }
            }
        )
        return navigation(isActive: isActive) {
            item.wrappedValue.map(destination)
        }
    }

    func navigation<Destination: View>(
        isActive: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        overlay(
            NavigationLink(
                destination: isActive.wrappedValue ? destination() : nil,
                isActive: isActive,
                label: { EmptyView() }
            )
        )
    }
}

// MARK: - Alert

extension View {
    func alertForErrorMessage(_ errorMessage: Binding<String?>) -> some View {
        alert(item: errorMessage) { message in
            Alert(
                title: Text(NSLocalizedString("Error", comment: "")),
                message: Text(message),
                dismissButton: .default(Text("OK"), action: {
                    errorMessage.wrappedValue = nil
                })
            )
        }
    }
}

// MARK: - Sheet

extension View {
    func sharingSheet(isPresented: Binding<Bool>, link: URL?) -> some View {
        sheet(isPresented: isPresented) {
            if let link {
                ActivityView(activityItems: [link])
            }
        }
    }
}
