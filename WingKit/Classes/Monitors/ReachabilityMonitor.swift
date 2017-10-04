//
//  ReachabilityMonitor.swift
//  AWSCognito
//
//  Created by Matt Wahlig on 10/4/17.
//

import Foundation
import ReachabilitySwift

enum ReachabilityMonitorError: Error {
    case configurationError
    case monitorUnavailable
}

public protocol ReachabilityMonitorDelegate: class {
    func reachabilityMonitorDidChangeReachability(_ manager: ReachabilityMonitor)
}

public class ReachabilityMonitor {

    public weak var delegate: ReachabilityMonitorDelegate?

    fileprivate(set) var isActive = false

    public var isConnectedToInternet: Bool {
        return reachability?.isReachable ?? false
    }

    fileprivate let reachability = Reachability()

    // MARK: - Init

    public init() {
        configure()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Start/Stop

    public func start() throws {

        guard !isActive else { return }

        guard let reachability = reachability else {
            throw ReachabilityMonitorError.configurationError
        }

        do {
            try reachability.startNotifier()

            self.isActive = true

        } catch {
            throw ReachabilityMonitorError.monitorUnavailable
        }
    }

    public func stop() {
        isActive = false

        reachability?.stopNotifier()
    }

    // MARK: - Configure

    fileprivate func configure() {
        guard let reachability = reachability else {
            return
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(reachabilityChanged(_:)),
            name: ReachabilityChangedNotification, object: reachability)
    }

    // MARK: - Reachability Changed Observer

    /**
     Triggered when the network reachability changes

     - parameter notification:
     */
    @objc func reachabilityChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.delegate?.reachabilityMonitorDidChangeReachability(self)
        }
    }
}

