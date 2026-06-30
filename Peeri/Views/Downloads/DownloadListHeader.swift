import SwiftUI

struct DownloadListHeader: View {
    let showsTorrentColumns: Bool

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 28)

            Text("NAME")
                .frame(minWidth: 120, alignment: .leading)

            Spacer(minLength: 12)

            Text("PROGRESS")
                .frame(minWidth: 100, maxWidth: 180, alignment: .leading)

            Spacer(minLength: 12)

            Text("SIZE")
                .frame(width: 80, alignment: .leading)

            Spacer(minLength: 12)

            Text("TIME LEFT")
                .frame(width: 90, alignment: .leading)

            Spacer(minLength: 12)

            Text("SPEED")
                .frame(width: 90, alignment: .leading)

            if showsTorrentColumns {
                Spacer(minLength: 12)
                Text("SEEDS")
                    .frame(width: 50, alignment: .leading)
                Spacer(minLength: 12)
                Text("PEERS")
                    .frame(width: 50, alignment: .leading)
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
    }
}

#Preview {
    VStack {
        DownloadListHeader(showsTorrentColumns: false)
        DownloadListHeader(showsTorrentColumns: true)
    }
    .frame(width: 820)
    .padding()
}
