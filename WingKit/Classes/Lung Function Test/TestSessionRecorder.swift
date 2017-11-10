//
//  TestSessionRecorder.swift
//  WingKit
//
//  Created by Matt Wahlig on 10/4/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation
import AVFoundation

/**
 The delegate of a TestSessionRecorder object must adopt the `TestRecorderDelegate` protocol. Methods of the protocol
 allow the delegate to observe recorder state changes and signal strength changes.
 */
public protocol TestRecorderDelegate: class {

    /**
     Indicates the recorder state has changed.

     - parameter state: The updated state of the recorder.
     */
    func recorderStateChanged(_ state: TestRecorderState)

    /**
     Indicates the sensor's strength has changed.

     - parameter strength: The strength of the signal sensor (normalized betwen 0.0 and 1.0)
     */
    func signalStrengthChanged(_ strength: Double)
}

/// The various states of the `TestSessionRecorder` class during a recording session.
public enum TestRecorderState {

    /// Indicates the recrders have been configured and are ready to start recording.
    case ready

    /// Indicates that the recording is currently in progress.
    case recording

    /// Indicates that the recording has concluded.
    case finished
}

/// The `TestRecorderError` enum describes domain specific errors for the `TestSessionRecorder` class.
public enum TestRecorderError: Error {

    /// Indicates the recorder failed to configure the underlying audio session used for recording.
    case configurationFailed

    /// The user-presentable message for the error.
    public var localizedDescription: String {
        switch self {
        case .configurationFailed: return "An error occurred while configuring the audio recorder."
        }
    }
}

/**
 The `TestSessionRecorder` class is used to detect and record when a user blows into the Wing sensor.
 */
public class TestSessionRecorder {

    // MARK: - Properties

    /// The object that acts as the delegate for the recorder.
    public weak var delegate: TestRecorderDelegate?


    /// The duration of the recording session.
    public let testDuration: TimeInterval = 6.0


    /// The threshold that the sensor recording strength must surpass to be considered a valid test.
    public let signalStrengthThreshold: Double = 0.6

    /**
     Indicates whether or not the recorded blow has passed the required signal strength threshold to be considered
     a valid, processable blow.
     */
    public fileprivate(set) var signalStrengthThresholdPassed = false

    /// The current state of the recorder.
    public fileprivate(set) var state: TestRecorderState = .ready {
        didSet {
            delegate?.recorderStateChanged(state)
        }
    }

    fileprivate var testTimer: Timer?
    fileprivate var signalStrengthUpdateTimer: Timer?

    fileprivate var baselineBlow: Double? {
        didSet {
            if let blow = baselineBlow {
                baselineBlow = min(1.0, max(0, blow))
            }
        }
    }
    fileprivate var baselineBlowBackground = 0.5
    fileprivate let defaultBaselineBlow = 0.5

    /// The filepath where the recording is saved to.
    public var recordingFilepath: String? {
        if let soundFilePath = soundFilePath,
            let soundFileTrimmedPath = soundFileTrimmedPath,
            TrimmingWrapper.trim(withInputFileName: soundFilePath, outputFileName: soundFilePath) == 0 {

            return soundFileTrimmedPath
        }

        return soundFilePath
    }

    fileprivate var soundFilePath: String?
    fileprivate var soundFileTrimmedPath: String?

    fileprivate var audioRecorder: AVAudioRecorder?
    fileprivate var blowRecorder: AVAudioRecorder?

    // MARK: - Initialization

    /// Initializes an instance of the `TestSessionRecorder` class.
    public init() {}

    deinit {
        testTimer?.invalidate()
        signalStrengthUpdateTimer?.invalidate()
        stopRecorders()
    }

    // MARK: - Configuration

    /**
     Configures the blow detection and audio recorders. Starts the blow detection recorder.

     - throws: TestSessionRecorder.Error.configurationFailed if either the blow detection or audio recorders configuration fails.
     */
    public func configure() throws {
        do {
            try configureBlowRecorder()
            try configureAudioRecorder()
        } catch {
            throw TestRecorderError.configurationFailed
        }

        startBlowRecorder()
    }

    fileprivate func configureBlowRecorder() throws {
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try audioSession.setActive(true)
        let cachesDirectoryPath = NSSearchPathForDirectoriesInDomains(
            .cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let cacheFilePath =  cachesDirectoryPath + "/recordTest.caf"
        let blowUrl = URL(fileURLWithPath: cacheFilePath)
        let blowSettings: [String : AnyObject] = [
            AVFormatIDKey: Int(kAudioFormatAppleIMA4) as AnyObject,
            AVSampleRateKey: 44100.0 as AnyObject,
            AVNumberOfChannelsKey: 1 as AnyObject,
            AVEncoderBitRateKey: 12800 as AnyObject,
            AVLinearPCMBitDepthKey: 16 as AnyObject,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue as AnyObject
        ]

        blowRecorder = try AVAudioRecorder(url:blowUrl, settings: blowSettings)
        blowRecorder?.prepareToRecord()
        blowRecorder?.isMeteringEnabled = true
    }

    fileprivate func configureAudioRecorder() throws {
        let documents = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        soundFilePath = documents + "/wingsampleTest.wav"
        soundFileTrimmedPath = documents + "/wingsampleTest-trimmed.wav"
        let wavUrl = URL(fileURLWithPath: soundFilePath!)
        let recordSettings: [String: AnyObject] = [
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue as AnyObject,
            AVEncoderBitRateKey: 16 as AnyObject,
            AVNumberOfChannelsKey: 1 as AnyObject,
            AVSampleRateKey: 44100.0 as AnyObject,
            AVFormatIDKey: Int(kAudioFormatLinearPCM) as AnyObject,
            AVLinearPCMIsFloatKey: false as AnyObject,
            AVLinearPCMIsBigEndianKey: false as AnyObject
        ]

        audioRecorder = try AVAudioRecorder(url: wavUrl, settings: recordSettings)
        audioRecorder?.prepareToRecord()
    }

    // MARK: - Start/Stop Recorder

    /**
     Starts the recording for a lung function test.
     */
    public func start() {

        guard state == .ready else { return }

        startAudioRecorder()
        startTestTimer()

        baselineBlow = baselineBlowBackground

        state = .recording
    }

    /// Ends the recording session.
    public func stop() {
        stopTimers()
        stopRecorders()
    }

    fileprivate func startAudioRecorder() {
        audioRecorder?.record()
    }

    fileprivate func startBlowRecorder() {
        blowRecorder?.record()

        signalStrengthUpdateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSignalStrength),
                                               userInfo: nil, repeats: true)
    }

    fileprivate func stopRecorders() {
        stopAudioRecorder()
        stopBlowRecorder()
    }

    fileprivate func stopAudioRecorder() {
        audioRecorder?.stop()
        audioRecorder = nil
    }

    fileprivate func stopBlowRecorder() {
        blowRecorder?.stop()
        blowRecorder = nil

        signalStrengthUpdateTimer?.invalidate()
    }

    fileprivate func startTestTimer() {
        testTimer?.invalidate()
        testTimer = Timer.scheduledTimer(
            timeInterval: testDuration,
            target: self, selector: #selector(testTimerFinished),
            userInfo: nil, repeats: false)
    }

    fileprivate func stopTimers() {
        signalStrengthUpdateTimer?.invalidate()
        testTimer?.invalidate()
    }

    // MARK: - Timer Actions

    @objc fileprivate func testTimerFinished() {
        stopRecording()

        state = .finished
    }

    @objc fileprivate func updateSignalStrength() {
        guard let recorder = blowRecorder else { return }

        recorder.updateMeters()

        let blowLevel = (Double(recorder.averagePower(forChannel: 0)) + 160.0) / 160.0

        switch state {
        case .ready:

            baselineBlowBackground = defaultBaselineBlow * blowLevel
                + (1 - defaultBaselineBlow) * baselineBlowBackground

        case .recording:

            let signalStrength = transformStrength(blowLevel)

            if signalStrength > signalStrengthThreshold
                && !signalStrengthThresholdPassed {

                signalStrengthThresholdPassed = true
                startTestTimer()
            }

            delegate?.signalStrengthChanged(signalStrength)

        default: return
        }
    }

    /**
     Helper function that takes in strength and applies a mathematical transform
     to return an adjusted, normalized strength (between 0.0 and 1.0).

     - parameter strength: The signal strength to transform.
     - returns: The transformed signal strength.
     */
    fileprivate func transformStrength(_ strength: Double) -> Double {
        var strength = min(strength, 1.0)
        let baselineBlowOrDefault = (baselineBlow ?? defaultBaselineBlow) * 1.10
        strength -= baselineBlowOrDefault
        guard strength > 0.0 else { return 0.0 }
        strength *= (1.0 / (1.0 - baselineBlowOrDefault))
        strength = pow(strength + 0.2, 4) / pow(1.2, 4)
        return strength
    }
}
