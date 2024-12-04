//
//  WebsocketClient.swift
//  WebSocketClient
//
//  Created by digital on 22/10/2024.
//
// IP Fixe : 192.168.1.99

import SwiftUI
import NWWebSocket
import Network

class WebSocketClient: ObservableObject {
    struct Message: Identifiable, Equatable {
        let id = UUID().uuidString
        let content: String
    }
    
    static let shared: WebSocketClient = WebSocketClient()
    
    var routes = [String: NWWebSocket]()
    var ipAdress: String = "192.168.0.132:8080"
    
    @Published var devicesStatus: [String: Bool] = [:]  // Ajout de la propriété pour l'état des périphériques
    
    func connectTo(route: String) -> Bool {
        let socketURL = URL(string: "ws://\(ipAdress)/\(route)")
        if let url = socketURL {
            let socket = NWWebSocket(url: url, connectAutomatically: true)
            
            socket.delegate = self
            socket.connect()
            routes[route] = socket
            print("Connected to WSServer @ \(url) -- Routes: \(routes)")
            return true
        }
        
        return false
    }
    
    func sendMessage(_ string: String, toRoute route: String) -> Void {
        self.routes[route]?.send(string: string)
    }
    
    func disconnect(route: String) -> Void {
        routes[route]?.disconnect()
    }
    
    func disconnectFromAllRoutes() -> Void {
        for route in routes {
            route.value.disconnect()
        }
        
        print("Disconnected from all routes.")
    }
    
    func updateDevicesStatus(from message: String) {
        var status: [String: Bool] = [:]
        
        // Séparer le message en lignes
        let lines = message.split(separator: "\n")
        print("Lines: \(lines)")  // Affiche les lignes séparées
        
        for line in lines {
            let components = line.split(separator: ":")
            print("Components: \(components)")  // Affiche les composants de chaque ligne
            
            if components.count == 2 {
                // Nettoyer les espaces avant et après les valeurs
                let device = components.first?.trimmingCharacters(in: .whitespaces)
                let isConnectedString = components.last?.trimmingCharacters(in: .whitespaces)
                
                if let device = device, let isConnectedString = isConnectedString {
                    // Convertir "Connecté" en true et "Déconnecté" en false
                    let isConnected: Bool
                    if isConnectedString == "Connecté" {
                        isConnected = true
                    } else if isConnectedString == "Déconnecté" {
                        isConnected = false
                    } else {
                        continue  // Ignore les valeurs inconnues
                    }
                    
                    status[device] = isConnected
                }
            }
        }
        
        print("Parsed Status: \(status)")  // Affiche le statut après le parsing
        
        // Mettre à jour la propriété sur le thread principal
        DispatchQueue.main.async {
            self.devicesStatus = status
        }
    }
    
    
}

extension WebSocketClient: WebSocketConnectionDelegate {
    
    func webSocketDidConnect(connection: WebSocketConnection) {
        // Respond to a WebSocket connection event
        print("WebSocket connected")
    }
    
    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        // Respond to a WebSocket disconnection event
        print("WebSocket disconnected")
    }
    
    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        // Respond to a WebSocket connection viability change event
        print("WebSocket viability: \(isViable)")
    }
    
    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        // Respond to when a WebSocket connection migrates to a better network path
        // (e.g. A device moves from a cellular connection to a Wi-Fi connection)
    }
    
    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        // Respond to a WebSocket error event
        print("WebSocket error: \(error)")
    }
    
    func webSocketDidReceivePong(connection: WebSocketConnection) {
        // Respond to a WebSocket connection receiving a Pong from the peer
        print("WebSocket received Pong")
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        // Traitement des messages reçus pour mettre à jour l'état
        print("WebSocket received message: \(string)")
        
        updateDevicesStatus(from: string)
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        // Respond to a WebSocket connection receiving a binary `Data` message
        print("WebSocket received Data message \(data)")
    }
}
