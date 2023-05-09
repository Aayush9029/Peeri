//
//  SideBar.swift
//  Peeri
//
//  Created by Aayush Pokharel on 2023-05-09.
//

import SwiftUI

struct SideBar: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Overview")
                .foregroundStyle(.secondary)

            SideBarRow(
                "Overview",
                icon: "diamond",
                count: 0
            )
            SideBarRow(
                "Downloading",
                icon: "arrow.down",
                count: 3,
                selected: true
            )
            SideBarRow(
                "Seeding",
                icon: "arrow.up",
                count: 2
            )
            SideBarRow(
                "Completed",
                icon: "checkmark",
                count: 150
            )
        }
    }
}

struct SideBarRow: View {
    let name: String
    let icon: String
    let count: Int
    let selected: Bool

    init(_ name: String, icon: String, count: Int, selected: Bool = false) {
        self.name = name
        self.icon = icon
        self.count = count
        self.selected = selected
    }

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "\(icon)")
                    .imageScale(.medium)
                    .frame(width: 18, height: 18)
                Text(name)
                Spacer()
                Text("\(count)")
                    .foregroundColor(selected ? .teal : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.gray.opacity(selected ? 0 : 0.125))
                    .cornerRadius(8)
            }
            .font(.title3)

            .padding(6)
        }
        .opacity(selected ? 1 : 0.75)
        .bold(selected)
        .background(.gray.opacity(selected ? 0.125 : 0))
        .cornerRadius(16)
    }
}

struct SideBar_Previews: PreviewProvider {
    static var previews: some View {
        SideBar()
            .padding()
            .background(.black)
            .cornerRadius(18)
            .padding()
    }
}
