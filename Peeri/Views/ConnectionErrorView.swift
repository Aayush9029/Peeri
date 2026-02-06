import SwiftUI

struct ConnectionErrorView: View {
    let errorMessage: String

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "exclamationmark.icloud.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)
                .padding()

            Text("Connection Error")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 4)

            Text(errorMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Text("The app will automatically try to reconnect...")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    ConnectionErrorView(errorMessage: "Could not connect to aria2 daemon on localhost:6800")
        .frame(width: 500, height: 400)
}
