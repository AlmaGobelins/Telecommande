import SwiftUI

struct ContentView: View {
    @ObservedObject var wsClient = WebSocketClient.shared
    
    var body: some View {
        VStack {
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
                }
            }
            .frame(maxHeight: 300) // Limiter la taille de la liste
            
            Spacer()
        }
        .onAppear {
            // Connexion au WebSocket sur le serveur
            let _ = wsClient.connectTo(route: "telecommande")
            wsClient.sendMessage("Telecommande up", toRoute: "telecommande")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
