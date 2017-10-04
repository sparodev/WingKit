//
//  AmbientNoiseMonitor.swift
//  AWSCognito
//
//  Created by Matt Wahlig on 10/4/17.
//

import Foundation
import AVFoundation

public protocol AmbientNoiseMonitorDelegate: class {
    func ambientNoiseMonitorDidChangeState(_ monitor: AmbientNoiseMonitor)
}

public class AmbientNoiseMonitor {

    public enum Error: Swift.Error {
        case microphonePermissionDenied
        case recorderConfigurationError
    }

    public weak var delegate: AmbientNoiseMonitorDelegate?

    fileprivate(set) var isActive = false

    fileprivate var recorder: AVAudioRecorder?
    fileprivate var audioSession = AVAudioSession.sharedInstance()

    public fileprivate(set) var isBelowThreshold: Bool = true

    public var noiseThreshold: Float = -10.0
    public var noiseCheckInterval: TimeInterval = 0.25

    fileprivate var noiseCheckTimer: Timer?

    public init() {}

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

    public func stop() {

        isActive = false

        stopRecorder()
        stopTimer()
    }

    fileprivate func configureAudioSession(completion: @escaping (Error?) -> Void) {

        if recorder == nil {
            audioSession.requestRecordPermission({ (granted) in

                guard granted else {
                    completion(Error.microphonePermissionDenied)
                    return
                }

                do {
                    try self.audioSession.setCategory(
                        AVAudioSessionCategoryPlayAndRecord,
                        with: .defaultToSpeaker)
                    try self.audioSession.setActive(true)
                } catch {
                    completion(Error.recorderConfigurationError)
                }

                let manager = FileManager()
                guard let cachesDirectoryURL = manager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                    completion(Error.recorderConfigurationError)
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
                    completion(Error.recorderConfigurationError)
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
    @objc func checkAmbientNoise() {
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
