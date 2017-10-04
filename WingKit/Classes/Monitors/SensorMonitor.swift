//
//  SensorMonitor.swift
//  AWSCognito
//
//  Created by Matt Wahlig on 10/4/17.
//

import Foundation
import AVFoundation

public protocol SensorMonitorDelegate: class {
    func sensorStateDidChange(_ monitor: SensorMonitor)
}

/**
 Monitors the plugged in state of the sensor. Notifies to it's delegate whenever the state of the sensor changes.
 */
public class SensorMonitor: NSObject {

    fileprivate(set) var audioSession: AVAudioSession!
    public weak var delegate: SensorMonitorDelegate?

    fileprivate var isActive = false
    public fileprivate(set) var isPluggedIn = true

    init(audioSession: AVAudioSession) {
        super.init()

        self.audioSession = audioSession

        refreshState()
    }

    public convenience override init() {
        self.init(audioSession: AVAudioSession.sharedInstance())
    }

    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }

    public func start() {
        guard !isActive else { return }

        isActive = true
        refreshState()
        NotificationCenter.default.addObserver(self, selector: #selector(routeChanged(_:)),
                                               name: NSNotification.Name.AVAudioSessionRouteChange,
                                               object: audioSession)
    }

    public func stop() {
        isActive = false
        NotificationCenter.default.removeObserver(self)
    }

    @objc func routeChanged(_ notification: Notification) {
        refreshState()

        DispatchQueue.main.async {
            self.delegate?.sensorStateDidChange(self)
        }
    }

    fileprivate func refreshState() {
        isPluggedIn = verifySensorIsPluggedIn(forSession: audioSession)
    }

    fileprivate func verifySensorIsPluggedIn(forSession session: AVAudioSession) -> Bool {
        return session.currentRoute.inputs.filter({ $0.portType == AVAudioSessionPortHeadsetMic }).count > 0
    }
}

