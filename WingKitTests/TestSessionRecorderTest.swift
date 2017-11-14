//
//  TestSessionRecorderTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 11/13/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import XCTest
@testable import WingKit

class TestSessionRecorderTest: XCTestCase, TestRecorderDelegate {

    var testObject: TestSessionRecorder!
    var recordingStartedExpectation: XCTestExpectation?
    var recordingFinishedExpectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()

        testObject = TestSessionRecorder()
    }
    
    override func tearDown() {

        super.tearDown()
    }

    func testStartRecordingBeginsRecordingForDuration() {

        testObject.delegate = self
        try? testObject.configure()

        recordingStartedExpectation = expectation(description: "wait for recording to start")
        recordingFinishedExpectation = expectation(description: "wait for recording to finish")

        testObject.startRecording()

        XCTAssertEqual(testObject.state, .recording)

        waitForExpectations(timeout: testObject.testDuration + 0.1, handler: nil)

        XCTAssertEqual(testObject.state, .finished)
    }

    func recorderStateChanged(_ state: TestRecorderState) {

        switch state {
        case .recording: recordingStartedExpectation?.fulfill()
        case .finished: recordingFinishedExpectation?.fulfill()
        default: break
        }
    }

    func signalStrengthChanged(_ strength: Double) {

    }
}
