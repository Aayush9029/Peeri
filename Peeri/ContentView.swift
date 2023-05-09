//
//  ContentView.swift
//  Peeri
//
//  Created by Aayush Pokharel on 2023-05-09.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            HStack {
                VStack {
                    HStack {
                        Text("Peeri")
                            .bold()
                        Spacer()
                    }
                    .padding(.bottom)
                    SideBar()
                    Spacer()
                }
                .frame(width: 256)
                .padding(.horizontal, 8)
                .padding(.vertical)

                .background(.gray.opacity(0.012))
                .cornerRadius(16)
                VStack {
                    SeedsView()
                    Divider()
                        .padding(.vertical)
                    TransferView()
                        .frame(height: 320)
                        .padding()
                }
            }
        }
        .padding(8)
        .padding(.top)

        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
