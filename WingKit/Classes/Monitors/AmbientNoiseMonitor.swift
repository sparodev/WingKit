//
//  AmbientNoiseMonitor.swift
//  AWSCognito
//
//  Created by Matt Wahlig on 10/4/17.
//

import Foundation
import AVFoundation

/// The `AmbientNoiseMonitorError` enum describes domain specific errors for the `AmbientNoiseMonitor` class.
public enum AmbientNoiseMonitorError: Error {

    /// Indicates that the user has denied the application access to the microphone.
    case microphonePermissionDenied

    /// Indicates that an error occurred while configuring the recorder.
    case recorderConfigurationError
}

/**
 The delegate of the AmbientNoiseMonitor object must adopt the `AmbientNoiseMonitorDelegate` protocol.  This allows
 the delegate to observe whenever `isBelowThreshold` state changes.
 */
public protocol AmbientNoiseMonitorDelegate: class {

    /// Tells the delegate that the monitor state changed.
    func ambientNoiseMonitorDidChangeState(_ monitor: AmbientNoiseMonitor)
}

/**
 The `AmbientNoiseMonitor` class is used to monitor the ambient noise level in an environment to determine whether
 or not the conditions are sufficient for a lung function measurement.
 */
public class AmbientNoiseMonitor {

    // MARK: - Properties

    /// The object that acts as the delegate of the monitor.
    public weak var delegate: AmbientNoiseMonitorDelegate?

    /// Indicates whether the ambient noise level is below or above the allowed threshold.
    public fileprivate(set) var isBelowThreshold: Bool = true

    /// Indicates whether the monitor is active or not.
    public fileprivate(set) var isActive = false

    fileprivate var recorder: AVAudioRecorder?
    fileprivate var audioSession = AVAudioSession.sharedInstance()

    fileprivate var noiseThreshold: Float = -10.0
    fileprivate var noiseCheckInterval: TimeInterval = 0.25

    fileprivate var noiseCheckTimer: Timer?

    // MARK: - Initialization

    /// Initializes an instance of the `AmbientNoiseMonitor` class.
    public init() {}

    deinit {
        stop()
    }

    // MARK: - Start/Stop Monitor

    /**
     Starts measuring the ambient noise level.

     - throws: `AmbientNoiseMonitorError.microphonePermissionDenied` if the user denys permission to access the microphone.
     - throws: `AmbientNoiseMonitorError.recorderConfigurationError` if any errors occur while configuring the audio session.
     */
    public func start(completion: @escaping (Error?) -> Void) {

        guard !isActive else { return }

        configureAudioSession { error in

            if let error = error {
                completion(error)
                return
            }

            self.isActive = true

            self.startRecorder()
            self.startTimer()

            completion(nil)
        }
    }

    /// Stops measuring the ambient noise level.
    public func stop() {

        isActive = false

        stopRecorder()
        stopTimer()
    }

    fileprivate func configureAudioSession(completion: @escaping (Error?) -> Void) {

        if recorder == nil {
            audioSession.requestRecordPermission({ (granted) in

                guard granted else {
                    completion(AmbientNoiseMonitorError.microphonePermissionDenied)
                    return
                }

                do {
                    try self.audioSession.setCategory(
                        AVAudioSessionCategoryPlayAndRecord,
                        with: .defaultToSpeaker)
                    try self.audioSession.setActive(true)
                } catch {
                    completion(AmbientNoiseMonitorError.recorderConfigurationError)
                }

                let manager = FileManager()
                guard let cachesDirectoryURL = manager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                    completion(AmbientNoiseMonitorError.recorderConfigurationError)
                    return
                }

                let recordingFileURL = cachesDirectoryURL.appendingPathComponent("recordTest.caf")
                let recordSettings: [String : AnyObject] = [
                    AVFormatIDKey: Int(kAudioFormatAppleIMA4) as AnyObject,
                    AVSampleRateKey: 44100.0 as AnyObject,
                    AVNumberOfChannelsKey: 1 as AnyObject,
                    AVEncoderBitRateKey: 12800 as AnyObject,
                    AVLinearPCMBitDepthKey: 16 as AnyObject,
                    AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue as AnyObject
                ]

                do {
                    self.recorder = try AVAudioRecorder(url: recordingFileURL, settings: recordSettings)
                } catch {
                    completion(AmbientNoiseMonitorError.recorderConfigurationError)
                }

                completion(nil)

            })
        }
    }

    // MARK: - Recorder

    fileprivate func startRecorder() {
        self.recorder?.prepareToRecord()
        self.recorder?.isMeteringEnabled = true
        self.recorder?.record()
    }

    fileprivate func stopRecorder() {
        recorder?.stop()
    }

    // MARK: - Timer

    fileprivate func startTimer() {
        noiseCheckTimer = Timer.scheduledTimer(timeInterval: noiseCheckInterval,
                                               target: self, selector: #selector(checkAmbientNoise),
                                               userInfo: nil, repeats: true)
    }

    fileprivate func stopTimer() {
        noiseCheckTimer?.invalidate()
        noiseCheckTimer = nil
    }

    /**
     Checks whether the ambient noise is above a threshold
     */
    @objc fileprivate func checkAmbientNoise() {
        recorder?.updateMeters()

        let previousState = isBelowThreshold
        if let averagePower = recorder?.averagePower(forChannel: 0) {
            isBelowThreshold = !(averagePower > noiseThreshold)
        } else {
            isBelowThreshold = false
        }

        if previousState != isBelowThreshold {
            delegate?.ambientNoiseMonitorDidChangeState(self)
        }
    }
}
