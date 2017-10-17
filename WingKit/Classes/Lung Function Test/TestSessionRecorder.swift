//
//  TestSessionRecorder.swift
//  WingKit
//
//  Created by Matt Wahlig on 10/4/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation
import AVFoundation

public enum TestRecorderState {
    case ready
    case recording
    case finished
}

public protocol TestRecorderDelegate: class {
    func recorderStateChanged(_ state: TestRecorderState)
    func signalStrengthChanged(_ strength: Double)
}

public class TestSessionRecorder {

    let testDuration: TimeInterval = 6.0

    /**
     The threshold that the sensor recording strength must surpass to be considered a valid test.
     */
    let signalStrengthThreshold: Double = 0.6

    /**
     The duration of the recording session.
     */
    static let recordingDuration = 6.0

    public weak var delegate: TestRecorderDelegate?

    public fileprivate(set) var state: TestRecorderState = .ready {
        didSet {
            delegate?.recorderStateChanged(state)
        }
    }

    public fileprivate(set) var signalStrengthThresholdPassed = false

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

    public var skipRecording = true

    fileprivate var debugWavUrl: String? {

        let podBundle = Bundle(for: TestSessionRecorder.self)
        guard let debuggingBundleURL = podBundle.url(forResource: "WingKitDebugging", withExtension: "bundle") else {
            return nil
        }

        return Bundle(url: debuggingBundleURL)?.path(forResource: "debuggingWav", ofType: "wav")
    }

    public var recordingFilepath: String? {
        if skipRecording {
            return debugWavUrl
        }

        if let soundFilePath = soundFilePath,
            let soundFileTrimmedPath = soundFileTrimmedPath,
            TrimmingWrapper.trim(withInputFileName: soundFilePath, outputFileName: soundFilePath) == 0 {

            return soundFileTrimmedPath
        }

        return soundFilePath
    }

    fileprivate var soundFilePath: String?
    fileprivate var soundFileTrimmedPath: String?

    var audioRecorder: AVAudioRecorder?
    var blowRecorder: AVAudioRecorder?

    public init() {}

    deinit {
        testTimer?.invalidate()
        signalStrengthUpdateTimer?.invalidate()
        stopRecorders()
    }

    public func configure() throws {
        try configureBlowRecorder()
        try configureAudioRecorder()

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

    /**
     Starts the recording for a lung function test.
     */
    public func startRecording() {

        guard state == .ready else { return }

        startAudioRecorder()
        startTestTimer()

        baselineBlow = baselineBlowBackground

        state = .recording
    }

    public func stopRecording() {
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

    @objc func testTimerFinished() {
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

//            let signalStrength = transformStrength(blowLevel)
            let signalStrength = Double(arc4random()) / Double(UInt32.max)
            currentSignal += signalStrength > 0.3 ? 0.1 : -0.1
            currentSignal = min(1.0, max(0, currentSignal))

            if currentSignal > signalStrengthThreshold
                && !signalStrengthThresholdPassed {

                signalStrengthThresholdPassed = true
                startTestTimer()
            }

            delegate?.signalStrengthChanged(currentSignal)

        default: return
        }

//        let signalStrength = Double(arc4random()) / Double(UInt32.max)
//        currentSignal += signalStrength > 0.3 ? 0.1 : -0.1
//        currentSignal = min(1.0, max(0, currentSignal))
//
//        delegate?.signalStrengthChanged(currentSignal)
    }

    var currentSignal: Double = 0.5

    /**
     Helper function that takes in strength and applies a mathematical transform
     to return an adjusted strength

     - parameter strength:
     - returns: transformed strength
     */
    func transformStrength(_ strength: Double) -> Double {
        var strength = min(strength, 1.0)
        let baselineBlowOrDefault = (baselineBlow ?? defaultBaselineBlow) * 1.10
        strength -= baselineBlowOrDefault
        guard strength > 0.0 else { return 0.0 }
        strength *= (1.0 / (1.0 - baselineBlowOrDefault))
        strength = pow(strength + 0.2, 4) / pow(1.2, 4)
        return strength
    }
}
