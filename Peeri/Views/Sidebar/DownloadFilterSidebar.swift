import Models
import Shared
import SwiftUI

struct DownloadFilterSidebar: View {
    @Binding var selection: DownloadFilter?
    let downloads: IdentifiedArrayOf<DownloadFile>

    var body: some View {
        List(selection: $selection) {
            Section("Overview") {
                ForEach(DownloadFilter.allCases) { filter in
                    Label(filter.rawValue, systemImage: filter.icon)
                        .badge(filter.count(in: downloads))
                        .tag(filter)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

#if DEBUG
#Preview {
    DownloadFilterSidebar(
        selection: .constant(.all),
        downloads: IdentifiedArray(uniqueElements: [DownloadFile].sampleList)
    )
    .frame(width: 240, height: 420)
}
#endif
