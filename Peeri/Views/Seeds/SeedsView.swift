//
//  SeedsView.swift
//  Peeri
//
//  Created by Aayush Pokharel on 2023-05-09.
//

import SwiftUI

enum SeedState {
    case waiting, downloading, seeding, paused
}

struct SeedStruct: Identifiable {
    var id: String { name }
    let state: SeedState
    let name: String
    let progress: Double
    let size: String
    let timeLeft: String
    let seeds: Int
    let peers: Int
}

let SeedStructExamples: [SeedStruct] = [
    SeedStruct(
        state: .downloading,
        name: "January wallpaper pack",
        progress: 0.75,
        size: "1.2GB",
        timeLeft: "15min",
        seeds: 54,
        peers: 18
    ),
    SeedStruct(
        state: .seeding,
        name: "Royalty free classics",
        progress: 1.0,
        size: "64MB",
        timeLeft: "Completed",
        seeds: 21,
        peers: 8
    ),
    SeedStruct(
        state: .seeding,
        name: "Game assets pack v1.2",
        progress: 1.0,
        size: "512MB",
        timeLeft: "Completed",
        seeds: 9,
        peers: 2
    ),
    SeedStruct(
        state: .paused,
        name: "Game assets pack platinum v2.1",
        progress: 0.70,
        size: "314MB",
        timeLeft: "Paused",
        seeds: 11,
        peers: 21
    ),
    SeedStruct(
        state: .paused,
        name: "Scientific papers Jan 2022 archives all",
        progress: 0.15,
        size: "14GB",
        timeLeft: "Paused",
        seeds: 4,
        peers: 1
    )
]

struct SeedsView: View {
    @State private var selected: SeedStruct? = SeedStructExamples.first!
    var body: some View {
        VStack {
            ForEach(SeedStructExamples) { seed in
                SingleSeedRow(seed: seed, selected: $selected)
            }
        }
    }
}

struct SingleSeedRow: View {
    let seed: SeedStruct
    @Binding var selected: SeedStruct?

    var body: some View {
        VStack {
            HStack {
                HStack {
                    HStack {
                        switch seed.state {
                        case .downloading:
                            Image(systemName: "arrow.down")
                        case .paused:
                            Image(systemName: "pause")
                        case .seeding:
                            Image(systemName: "arrow.up")
                        case .waiting:
                            Image(systemName: "hourglass")
                        }
                        Text(seed.name)
                        Spacer()
                    }
                    .font(.title3)
                    .frame(width: 256)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: 200, height: 6)
                            .foregroundStyle(.quaternary)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(seedColor().gradient)
                            .frame(width: 200 * seed.progress, height: 6)
                    }
                    .frame(width: 248)
                    HStack {
                        Text(seed.size)
                        Spacer()
                    }
                    .frame(width: 72)
                    HStack {
                        Text(seed.timeLeft)
                        Spacer()
                    }
                    .frame(width: 128)
                    HStack {
                        Text("\(seed.seeds)")
                        Spacer()
                    }
                    .frame(width: 48)
                    HStack {
                        Text("\(seed.peers)")
                        Spacer()
                    }
                    .frame(width: 48)
                }
                .font(.title3)
                .lineLimit(1)
                .padding(12)
                .opacity(seed.state == .paused ? 0.75 : 1)
                .background(.gray.opacity((selected?.id ?? "") == seed.id ? 0.125 : 0))
                .cornerRadius(12)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            selected = seed
        }
    }

    func seedColor() -> Color {
        switch seed.state {
        case .downloading:
            return Color.teal
        case .paused:
            return Color.gray
        case .seeding:
            return Color.green
        case .waiting:
            return Color.orange
        }
    }
}

struct SeedsView_Previews: PreviewProvider {
    static var previews: some View {
        SeedsView()
            .padding()
            .background(.black)
            .cornerRadius(18)
            .padding()
    }
}
