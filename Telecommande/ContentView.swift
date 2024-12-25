import SwiftUI

struct ContentView: View {
    @ObservedObject var wsClient = WebSocketClient.shared
    @State private var ip: String = "192.168.1.22:8080"
    @State private var route: String = "test"
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
                    let isConnected = wsClient.devicesStatus[device]!.0
                    Text(isConnected ? "Connecté" : "Déconnecté")
                        .foregroundColor(isConnected ? .green : .red)
                    Spacer()
                    Button("Trigger action") {
                        //custom action for each route/device
                        triggerActionFor(wsClient.devicesStatus[device]!.1)
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

func triggerActionFor(_ callbackName: String) {
    switch callbackName {
    case "test" : print("test")
    default: print("test")
    }
}

#Preview {
    ContentView()
}
