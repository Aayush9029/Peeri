import SwiftUI

struct CommandPanelRow: View {
    let title: String
    var subtitle = ""
    let symbol: String
    var shortcut = ""
    var selected = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(selected ? .primary : .secondary)
                .frame(width: 24)
            Text(title)
                .lineLimit(1)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            if !shortcut.isEmpty {
                Text(shortcut)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.body)
        .padding(.horizontal, 10)
        .frame(height: 40)
        .background(selected ? Color.primary.opacity(0.09) : .clear, in: .rect(cornerRadius: 9))
        .contentShape(.rect(cornerRadius: 9))
    }
}

struct CommandPanelFooter<Actions: View>: View {
    @ViewBuilder var actions: Actions

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(.secondary)
            Text("Peeri")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            actions
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(.primary.opacity(0.025))
        .overlay(alignment: .top) { Divider().opacity(0.5) }
    }
}

struct CommandPanelAction: View {
    let title: String
    let key: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(.callout.weight(.medium))
                Text(key)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 18, minHeight: 18)
                    .background(.primary.opacity(0.055), in: .rect(cornerRadius: 4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.primary.opacity(0.06), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
