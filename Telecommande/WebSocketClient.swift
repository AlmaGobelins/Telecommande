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
    var ipAdress: String = "192.168.1.99:8080"
    
    @Published var devicesStatus: [String: Bool] = [:]
    @Published var isConnected: Bool = false
    
    private var reconnectTimer: Timer?
    private let reconnectInterval: TimeInterval = 5.0
    
    func connectTo(route: String) -> Bool {
        let socketURL = URL(string: "ws://\(ipAdress)/\(route)")
        if let url = socketURL {
            let socket = NWWebSocket(url: url, connectAutomatically: true)
            socket.delegate = self
            socket.connect()
            routes[route] = socket
            print("Attempting to connect to WSServer @ \(url)")
            return true
        }
        return false
    }
    
    func startReconnectTimer(forRoute route: String) {
        stopReconnectTimer()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: true) { [weak self] _ in
            guard let self = self, !self.isConnected else { return }
            print("Attempting to reconnect...")
            let _ = self.connectTo(route: route)
        }
    }
    
    func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    func sendMessage(_ string: String, toRoute route: String) {
        self.routes[route]?.send(string: string)
    }
    
    func disconnect(route: String) {
        routes[route]?.disconnect()
    }
    
    func disconnectFromAllRoutes() {
        stopReconnectTimer()
        for route in routes {
            route.value.disconnect()
        }
        routes.removeAll()
        print("Disconnected from all routes.")
    }
    
    func updateDevicesStatus(from message: String) {
        var newStatus: [String: Bool] = [:]
        
        let lines = message.split(separator: "\n")
        
        for line in lines {
            let components = line.split(separator: ":")
            if components.count == 2 {
                let device = components.first?.trimmingCharacters(in: .whitespaces)
                let isConnectedString = components.last?.trimmingCharacters(in: .whitespaces)
                
                if let device = device, let isConnectedString = isConnectedString {
                    let isConnected = isConnectedString == "Connecté"
                    newStatus[device] = isConnected
                }
            }
        }
        
        // Vérifier s'il y a des changements avant de mettre à jour
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !newStatus.isEmpty && !newStatus.elementsEqual(self.devicesStatus, by: { $0.key == $1.key && $0.value == $1.value }) {
                print("Updating status: \(newStatus)")
                self.devicesStatus = newStatus
            }
        }
    }
}

extension WebSocketClient: WebSocketConnectionDelegate {
    func webSocketDidConnect(connection: WebSocketConnection) {
        print("WebSocket connected")
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = true
            self?.stopReconnectTimer()
        }
    }
    
    func webSocketDidDisconnect(connection: WebSocketConnection,
                              closeCode: NWProtocolWebSocket.CloseCode,
                              reason: Data?) {
        print("WebSocket disconnected")
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.startReconnectTimer(forRoute: "telecommande")
        }
    }
    
    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        print("WebSocket viability changed: \(isViable)")
        if !isViable {
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = false
                self?.startReconnectTimer(forRoute: "telecommande")
            }
        }
    }
    
    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        // Gérer la migration de chemin si nécessaire
    }
    
    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        print("WebSocket error: \(error)")
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.startReconnectTimer(forRoute: "telecommande")
        }
    }
    
    func webSocketDidReceivePong(connection: WebSocketConnection) {
        print("WebSocket received Pong")
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        print("WebSocket received message: \(string)")
        
        if string == "ping" {
            self.sendMessage("pong", toRoute: "telecommande")
        } else {
            updateDevicesStatus(from: string)
        }
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        print("WebSocket received Data message")
    }
}
