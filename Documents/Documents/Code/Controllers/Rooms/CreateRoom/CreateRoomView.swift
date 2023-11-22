//
//  CreateRoomView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 22.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

struct CreateRoomView: View {
    @State private var roomName: String = ""
    @State private var tags: String = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: Text("Room Type Selection")) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill.badge.plus")
                                .foregroundColor(.green)
                            Text("Public room")
                            Spacer()
                            Text("Invite users via shared links to view documents without registration. You can also embed this room into any web interface.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section {
                    TextField("Room name", text: $roomName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Add tags", text: $tags)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Create room", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Back") {
                },
                trailing: Button("Create") {
                }
            )
        }
    }
}

struct CreateRoomView_Previews: PreviewProvider {
    static var previews: some View {
        CreateRoomView()
    }
}
