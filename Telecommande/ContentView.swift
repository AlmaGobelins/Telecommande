import SwiftUI

struct ContentView: View {
    @ObservedObject var wsClient = WebSocketClient.shared
    @State private var ip: String = "192.168.1.100:8080"
    @State private var route: String = "telecommande"
    var body: some View {
        VStack {
            
            HStack {
                TextField("IP:", text: $ip)
                Spacer()
                TextField("Route:", text: $route)
            }
            Text("État des sessions :")
                .font(.headline)
                .padding()
            
            // Liste des périphériques avec leur état
            List(wsClient.devicesStatus.keys.sorted(), id: \.self) { device in
                HStack {
                    Text(device.capitalized)
                    Spacer()
                    Text(wsClient.devicesStatus[device]! ? "Connecté" : "Déconnecté")
                        .foregroundColor(wsClient.devicesStatus[device]! ? .green : .red)
                    Spacer()
                    Button("Trigger action") {
                        //custom action for each route/device
                    }
                }
            }
            .frame(maxHeight: 300) // Limiter la taille de la liste
            
            Spacer()
            
            Button("Connect") {
                // Connexion au WebSocket sur le serveur
                let _ = wsClient.connectTo(route: route)
                wsClient.sendMessage("Telecommande up", toRoute: route)
            }
            
            Spacer()
        }
        .onChange(of: ip) {
            wsClient.ipAdress = ip
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
