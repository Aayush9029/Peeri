//
//  SideBar.swift
//  Peeri
//
//  Created by Aayush Pokharel on 2023-05-09.
//

import Models
import SwiftUI

enum DownloadFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case downloading = "Downloading"
    case paused = "Paused"
    case completed = "Completed"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "diamond"
        case .downloading: return "arrow.down"
        case .paused: return "pause"
        case .completed: return "checkmark"
        }
    }
    
    func filter(_ downloads: [DownloadFile]) -> [DownloadFile] {
        switch self {
        case .all:
            return downloads
        case .downloading:
            return downloads.filter { $0.status == .downloading }
        case .paused:
            return downloads.filter { $0.status == .paused }
        case .completed:
            return downloads.filter { $0.status == .completed }
        }
    }
}

struct SideBar: View {
    @Binding var selectedFilter: DownloadFilter
    let activeCount: Int
    let pausedCount: Int
    let completedCount: Int
    let connectionState: ConnectionState
    
    init(selectedFilter: Binding<DownloadFilter>, activeCount: Int = 0, pausedCount: Int = 0, completedCount: Int = 0, connectionState: ConnectionState = .disconnected) {
        self._selectedFilter = selectedFilter
        self.activeCount = activeCount
        self.pausedCount = pausedCount
        self.completedCount = completedCount
        self.connectionState = connectionState
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Downloads")
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            ForEach(DownloadFilter.allCases) { filter in
                SideBarRow(
                    filter.rawValue,
                    icon: filter.icon,
                    count: getCount(for: filter),
                    selected: selectedFilter == filter
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedFilter = filter
                }
            }
            
            Spacer()
            
            // Connection status indicator
            ConnectionStatusView(state: connectionState)
                .padding(.top, 8)
        }
    }
    
    private func getCount(for filter: DownloadFilter) -> Int {
        switch filter {
        case .all:
            return activeCount + pausedCount + completedCount
        case .downloading:
            return activeCount
        case .paused:
            return pausedCount
        case .completed:
            return completedCount
        }
    }
}

struct ConnectionStatusView: View {
    let state: ConnectionState
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(stateColor)
            
            Text(stateText)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(8)
        .background(.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var stateColor: Color {
        switch state {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .red
        case .failed:
            return .red
        @unknown default:
            return .gray
        }
    }
    
    private var stateText: String {
        switch state {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .failed(let error):
            return "Error: \(error.localizedDescription)"
        @unknown default:
            return "Unknown State"
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
        SideBar(selectedFilter: .constant(.all))
            .padding()
            .background(.black)
            .cornerRadius(18)
            .padding()
    }
}
