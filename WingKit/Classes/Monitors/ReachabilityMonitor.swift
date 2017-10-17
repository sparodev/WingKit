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

/**
 The delegate of a ReachabilityMonitor object must adopt the `ReachabilityMonitorDelegate` protocol. Methods of the
 protocol allow the delegate to observe network reachability state changes..
 */
public protocol ReachabilityMonitorDelegate: class {

    /// Tells the delegate when the network reachability state has changed.
    func reachabilityMonitorDidChangeReachability(_ manager: ReachabilityMonitor)
}

public class ReachabilityMonitor {

    /// The object that acts as the delegate for the monitor.
    public weak var delegate: ReachabilityMonitorDelegate?

    fileprivate(set) var isActive = false

    /// Indicates whether or not the device is connected to the internet.
    public var isConnectedToInternet: Bool {
        return reachability?.isReachable ?? false
    }

    fileprivate let reachability = Reachability()

    // MARK: - Init

    public init() {
        configure()
    }

    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Start/Stop

    /// Starts monitoring the device's internet reachability.
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

    /// Stops monitoring the device's internet reachability.
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

