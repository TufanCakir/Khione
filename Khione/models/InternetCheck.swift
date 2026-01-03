//
//  InternetMonitor.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

internal import Combine
import Network
import SwiftUI

class InternetMonitor: ObservableObject {
    @Published var isConnected: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "InternetMonitor")

    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
