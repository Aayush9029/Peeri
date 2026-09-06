import Models
import Shared
import SwiftUI

struct DownloadFilterSidebar: View {
    @Binding var selection: DownloadFilter?
    let downloads: IdentifiedArrayOf<DownloadFile>

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        List(selection: $selection) {
            Section("Transfers") {
                ForEach(DownloadFilter.allCases) { filter in
                    Label(filter.rawValue, systemImage: filter.icon)
                        .badge(filter.count(in: downloads))
                        .tag(filter)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background {
            sidebarBackground
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var sidebarBackground: some View {
        if reduceTransparency || contrast == .increased {
            Color(nsColor: .windowBackgroundColor)
        } else {
            SidebarVisualEffect()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
