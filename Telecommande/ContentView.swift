import SwiftUI

struct ContentView: View {
    @StateObject var wsClient = WebSocketClient.shared
    private let route = "telecommande"
    
    struct DeviceStatus: Identifiable, Equatable {
        let id: String
        let name: String
        let isConnected: Bool
        
        static func == (lhs: DeviceStatus, rhs: DeviceStatus) -> Bool {
            return lhs.id == rhs.id && lhs.name == rhs.name && lhs.isConnected == rhs.isConnected
        }
    }
    
    @State private var currentStatuses: [DeviceStatus] = []
    
    private var newDeviceStatuses: [DeviceStatus] {
        wsClient.devicesStatus.map { device in
            DeviceStatus(
                id: device.key,
                name: device.key.capitalized,
                isConnected: device.value
            )
        }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        List(currentStatuses) { device in
            HStack {
                Text(device.name)
                Spacer()
                Circle()
                    .fill(device.isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(device.isConnected ? "Connecté" : "Déconnecté")
            }
        }
        .onAppear {
            let _ = wsClient.connectTo(route: route)
        }
        .onChange(of: wsClient.devicesStatus) { _ in
            currentStatuses = newDeviceStatuses
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
