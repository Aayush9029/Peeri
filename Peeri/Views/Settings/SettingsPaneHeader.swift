import SwiftUI

struct SettingsPaneHeader: View {
    let tab: SettingsTab

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            SettingsTabIcon(tab: tab, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title)
                    .font(.title3.weight(.semibold))

                Text(tab.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(.bar)
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(SettingsTab.allCases, id: \.self) { tab in
            SettingsPaneHeader(tab: tab)
        }
    }
}
