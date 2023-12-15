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

// MARK: - OnChange

@available(iOS, introduced: 13.0, deprecated: 14.0, message: "Use the native .onChange modifier in iOS 14 and later.")
extension View {
    func onChange<V: Equatable>(
        of value: V,
        perform action: @escaping (V) -> Void
    ) -> some View {
        modifier(OnChangeModifier(value: value, action: action))
    }
}

@available(iOS, introduced: 13.0, deprecated: 14.0, message: "Use the native .onChange modifier in iOS 14 and later.")
private struct OnChangeModifier<V: Equatable>: ViewModifier {
    let value: V
    let action: (V) -> Void

    func body(content: Content) -> some View {
        content.background(
            OnChangeView(value: value, action: action)
        )
    }
}

private struct OnChangeView<V: Equatable>: View {
    let value: V
    let action: (V) -> Void

    @State private var previousValue: V

    init(value: V, action: @escaping (V) -> Void) {
        self.value = value
        self.action = action
        _previousValue = State(initialValue: value)
    }

    var body: some View {
        Color.clear.onAppear {
            self.previousValue = self.value
        }
        .onReceive(Just(value)) { newValue in
            if newValue != self.previousValue {
                self.action(newValue)
                self.previousValue = newValue
            }
        }
    }
}
