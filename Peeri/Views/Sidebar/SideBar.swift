import Models
import Shared
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

    func filter(_ downloads: IdentifiedArrayOf<DownloadFile>) -> [DownloadFile] {
        switch self {
        case .all:
            return Array(downloads)
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

#Preview {
    SideBar(
        selectedFilter: .constant(.all),
        activeCount: 3,
        pausedCount: 1,
        completedCount: 5
    )
    .padding()
    .frame(width: 240)
    .background(.black)
    .cornerRadius(18)
    .padding()
}
