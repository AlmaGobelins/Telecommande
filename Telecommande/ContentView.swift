//
//  ContentView.swift
//  Telecommande
//
//  Created by Killian El Attar on 03/12/2024.
//

import SwiftUI

struct SessionInfo: Identifiable {
    var id: String
    let name: String
    var isConnected: Bool
}

struct ContentView: View {
    @ObservedObject var wsClient = WebSocketClient.shared
    @State private var sessionInfos: [SessionInfo] = [] // Liste des sessions avec leur état
    let telRoute: String = "telecommande"
    
    var body: some View {
        VStack {
            Text("État des sessions :")
                .font(.headline)
            
            List(sessionInfos) { session in
                HStack {
                    Text(session.name)
                        .fontWeight(.bold)
                    Spacer()
                    Text(session.isConnected ? "Connecté" : "Déconnecté")
                        .foregroundColor(session.isConnected ? .green : .red)
                }
            }
            .frame(maxHeight: 300) // Limite la hauteur de la liste
            
            Spacer()
        }
        .onAppear {
            let _ = wsClient.connectTo(route: telRoute)
            wsClient.sendMessage("Telecommande", toRoute: telRoute)
        }
        .onReceive(wsClient.$receivedMessage) { message in
            handleReceivedMessage(message)
        }
        .padding()
    }
    
    /// Traite le message reçu et met à jour l'état des sessions
    private func handleReceivedMessage(_ message: String) {
        // Tente de désérialiser le message en dictionnaire JSON
        if let data = message.data(using: .utf8),
           let decodedSessions = try? JSONDecoder().decode([String: String].self, from: data) {
            updateSessionInfos(with: decodedSessions)
        } else {
            print("Message entrant : \(message)")
        }
        
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            wsClient.sendMessage("pong", toRoute: telRoute)
        }
    }
    
    /// Met à jour les informations des sessions avec l'état reçu
    private func updateSessionInfos(with sessions: [String: String]) {
        // Crée un tableau temporaire pour stocker les nouvelles sessions
        var updatedSessionInfos: [SessionInfo] = []
        
        // Parcourt les sessions reçues du serveur
        for (name, id) in sessions {
            if let existingSessionIndex = sessionInfos.firstIndex(where: { $0.name == name }) {
                // Si une session avec le même nom existe déjà, met à jour son état
                var existingSession = sessionInfos[existingSessionIndex]
                existingSession.id = id // Met à jour l'ID au cas où il a changé
                existingSession.isConnected = true
                updatedSessionInfos.append(existingSession)
            } else {
                // Ajoute une nouvelle session comme connectée
                updatedSessionInfos.append(
                    SessionInfo(id: id, name: name, isConnected: true)
                )
            }
        }
        
        // Déconnecte les sessions manquantes
        for existingSession in sessionInfos {
            if !sessions.keys.contains(existingSession.name) {
                // Marque les sessions manquantes comme déconnectées
                updatedSessionInfos.append(
                    SessionInfo(id: existingSession.id, name: existingSession.name, isConnected: false)
                )
            }
        }
        
        // Mets à jour l'état local
        sessionInfos = updatedSessionInfos
    }

}



#Preview {
    ContentView()
}
