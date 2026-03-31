//
//  NetworkMonitor.swift
//  NearBy
//
//  Created by Rafat on 2026-03-31.
//


import Foundation
import Network
import Combine

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "NetworkMonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.isConnected = connected
            }
        }
        monitor.start(queue: queue)
    }
}

extension Notification.Name {
    static let refreshDashboard = Notification.Name("refreshDashboard")
}
