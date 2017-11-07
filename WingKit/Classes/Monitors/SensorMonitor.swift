//
//  SensorMonitor.swift
//  AWSCognito
//
//  Created by Matt Wahlig on 10/4/17.
//

import Foundation
import AVFoundation

/**
 The delegate of a `SensorMonitor` object must adopt the `SensorMonitorDelegate` protocol. Methods of the protocol
 allow the delegate to observe sensor plugged in state changes.
 */
public protocol SensorMonitorDelegate: class {

    /// Tells the delegate when the state of the sensor has changed.
    func sensorStateDidChange(_ monitor: SensorMonitor)
}

/**
 The `SensorMonitor` class is used to monitor the connection state of the sensor. Notifies to it's delegate whenever the sensor is connected/disconnected.
 */
public class SensorMonitor: NSObject {

    // MARK: - Properties

    fileprivate var audioSession: AVAudioSession!

    /// The object that acts as the delegate of the monitor.
    public weak var delegate: SensorMonitorDelegate?

    /// Indicates whether the monitor is active or not.
    fileprivate var isActive = false

    /// Indicates whether the sensor is plugged in or not.
    public fileprivate(set) var isPluggedIn = true

    // MARK: - Initialization

    /// Initializes an instance of the `SensorMonitor` class.
    public override init() {
        super.init()

        self.audioSession = AVAudioSession.sharedInstance()

        refreshState()
    }

    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Start/Stop Monitor

    /// Starts monitoring the connection state of the Wing sensor.
    public func start() {
        guard !isActive else { return }

        isActive = true
        refreshState()
        NotificationCenter.default.addObserver(self, selector: #selector(routeChanged(_:)),
                                               name: NSNotification.Name.AVAudioSessionRouteChange,
                                               object: audioSession)
    }

    /// Stops monitoring the connection state of the Wing sensor.
    public func stop() {
        isActive = false
        NotificationCenter.default.removeObserver(self)
    }

    @objc fileprivate func routeChanged(_ notification: Notification) {
        let updatedIsPluggedIn = verifySensorIsPluggedIn(forSession: audioSession)

        if isPluggedIn != updatedIsPluggedIn {
            refreshState()

            DispatchQueue.main.async {
                self.delegate?.sensorStateDidChange(self)
            }
        }

    }

    fileprivate func refreshState() {
        isPluggedIn = verifySensorIsPluggedIn(forSession: audioSession)
    }

    fileprivate func verifySensorIsPluggedIn(forSession session: AVAudioSession) -> Bool {
        return session.currentRoute.inputs.filter({ $0.portType == AVAudioSessionPortHeadsetMic }).count > 0
    }
}

