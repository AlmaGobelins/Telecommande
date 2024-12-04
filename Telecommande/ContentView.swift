//
//  ContentView.swift
//  Telecommande
//
//  Created by Killian El Attar on 03/12/2024.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var wsClient = WebSocketClient.shared
    
    var body: some View {
        VStack {
            Text("Liste des devices :")
            Text(wsClient.receivedMessage)
        }.onAppear{
            wsClient.connectTo(route: "telecommande")
            wsClient.sendMessage("Telecommande", toRoute: "telecommande")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
