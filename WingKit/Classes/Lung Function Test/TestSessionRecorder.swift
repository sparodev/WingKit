//
//  TestSessionRecorder.swift
//  WingKit
//
//  Created by Matt Wahlig on 10/4/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation
import AVFoundation

class TestSessionRecorder {

    /**
     The duration of the recording session before it times out.
     */
    static let testTimeoutDuration = 6.0

    /**
     The duration to record once a signal is detected that passes test threshold.
     */
    static let blowDuration = 6.0

    var soundFilePath: String?
    var soundFileTrimmedPath: String?
    var audioRecorder: AVAudioRecorder?
    var blowRecorder: AVAudioRecorder?

    public func configureRecorders() throws {
        try configureBlowRecorder()
        try configureAudioRecorder()
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

    func recordingFilepath() -> String? {
        if let soundFilePath = soundFilePath,
            let soundFileTrimmedPath = soundFileTrimmedPath,
            TrimmingWrapper.trim(withInputFileName: soundFilePath, outputFileName: soundFilePath) == 0 {

            return soundFileTrimmedPath
        }

        return soundFilePath
    }

    func startAudioRecorder() {
        audioRecorder?.record()
    }

    func stopAudioRecorder() {
        audioRecorder?.stop()
        audioRecorder = nil
    }

    func startBlowRecorder() {
        blowRecorder?.record()
    }

    func stopBlowRecorder() {
        blowRecorder?.stop()
        blowRecorder = nil
    }

    func updateBlowLevel() -> Double? {
        guard let recorder = blowRecorder else {
            return nil
        }

        recorder.updateMeters()
        return (Double(recorder.averagePower(forChannel: 0)) + 160.0) / 160.0
    }
}
