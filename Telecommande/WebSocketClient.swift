//
//  WebsocketClient.swift
//  WebSocketClient
//
//  Created by digital on 22/10/2024.
//
// IP Fixe : 192.168.1.99

import NWWebSocket
import Network
import SwiftUI

class WebSocketClient: ObservableObject {
    struct Message: Identifiable, Equatable {
        let id = UUID().uuidString
        let content: String
    }

    static let shared: WebSocketClient = WebSocketClient()

    var routes = [String: NWWebSocket]()
    var ipAdress: String = "192.168.1.22:8080"

    @Published var devicesStatus: [String: (Bool, String)] = [:]  // Ajout de la propriété pour l'état des périphériques

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

    func sendMessage(_ string: String, toRoute route: String) {
        self.routes[route]?.send(string: string)
    }

    func disconnect(route: String) {
        routes[route]?.disconnect()
    }

    func disconnectFromAllRoutes() {
        for route in routes {
            route.value.disconnect()
        }

        print("Disconnected from all routes.")
    }

    func updateDevicesStatus(from message: String) {
        var status: [String: (Bool, String)] = [:]
        
        let lines = message.split(separator: "\n")
        print("Lines: \(lines)")
        
        for line in lines {
            let components = line.split(separator: ":")
            print("Components: \(components)")
            
            if components.count == 3 {
                let device = components[0].trimmingCharacters(in: .whitespaces)
                let isConnected = Bool(components[1].trimmingCharacters(in: .whitespaces)) ?? false
                let callback = components[2].trimmingCharacters(in: .whitespaces)
                
                status[device] = (isConnected, callback)
            }
        }
        
        print("Parsed Status: \(status)")
        
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

    func webSocketDidDisconnect(
        connection: WebSocketConnection,
        closeCode: NWProtocolWebSocket.CloseCode, reason: Data?
    ) {
        // Respond to a WebSocket disconnection event
        print("WebSocket disconnected")
    }

    func webSocketViabilityDidChange(
        connection: WebSocketConnection, isViable: Bool
    ) {
        // Respond to a WebSocket connection viability change event
        print("WebSocket viability: \(isViable)")
    }

    func webSocketDidAttemptBetterPathMigration(
        result: Result<WebSocketConnection, NWError>
    ) {
        // Respond to when a WebSocket connection migrates to a better network path
        // (e.g. A device moves from a cellular connection to a Wi-Fi connection)
    }

    func webSocketDidReceiveError(
        connection: WebSocketConnection, error: NWError
    ) {
        // Respond to a WebSocket error event
        print("WebSocket error: \(error)")
    }

    func webSocketDidReceivePong(connection: WebSocketConnection) {
        // Respond to a WebSocket connection receiving a Pong from the peer
        print("WebSocket received Pong")
    }

    func webSocketDidReceiveMessage(
        connection: WebSocketConnection, string: String
    ) {
        // Traitement des messages reçus pour mettre à jour l'état
        print("WebSocket received message: \(string)")

        updateDevicesStatus(from: string)
        if string == "ping" {
            self.sendMessage("pong", toRoute: "test")
        }
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data)
    {
        // Respond to a WebSocket connection receiving a binary `Data` message
        print("WebSocket received Data message \(data)")
    }
}
