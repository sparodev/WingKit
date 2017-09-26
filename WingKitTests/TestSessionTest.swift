//
//  TestSessionTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/22/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

class TestSessionTest: WingKitTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testIsDecodableFromJSON() {

        let expectedId = UUID().uuidString
        let expectedStartedAt = Date()
        let expectedEndedAt = Date().addingTimeInterval(30)
        let expectedLungFunctionZone = LungFunctionZone.yellowZone
        let expectedRespiratoryState = RespiratoryState.greenZone
        let expectedLatitude = 3.0
        let expectedLongitude = 4.0
        let expectedAltitude = 5.0
        let expectedFloor = 6.0

        let expectedBestTestJSON = Test.sampleJSON()

        let json: JSON = [
            TestSession.Keys.id: expectedId,
            TestSession.Keys.startedAt: expectedStartedAt.iso8601,
            TestSession.Keys.endedAt: expectedEndedAt.iso8601,
            TestSession.Keys.lungFunctionZone: expectedLungFunctionZone.string,
            TestSession.Keys.respiratoryState: expectedRespiratoryState.string,
            TestSession.Keys.metadata: [
                TestSession.Keys.latitude: expectedLatitude,
                TestSession.Keys.longitude: expectedLongitude,
                TestSession.Keys.altitude: expectedAltitude,
                TestSession.Keys.floor: expectedFloor
            ],
            TestSession.Keys.bestTest: expectedBestTestJSON,
            TestSession.Keys.tests: [
                expectedBestTestJSON,
                Test.sampleJSON()
            ]
        ]

        let decoder = WingKit.JSONDecoder()
        var testSession: TestSession?

        do {
            testSession = try decoder.decode(TestSession.self, from: json)
        } catch {
            XCTFail()
            return
        }

        guard let testObject = testSession else {
            XCTFail()
            return
        }

        XCTAssertEqual(testObject.id, expectedId)
        XCTAssertEqual(testObject.startedAt.timeIntervalSinceReferenceDate, expectedStartedAt.timeIntervalSinceReferenceDate, accuracy: 0.02)
        XCTAssertEqual(testObject.endedAt!.timeIntervalSinceReferenceDate, expectedEndedAt.timeIntervalSinceReferenceDate, accuracy: 0.02)
        XCTAssertEqual(testObject.lungFunctionZone, expectedLungFunctionZone)
        XCTAssertEqual(testObject.respiratoryState, expectedRespiratoryState)
        XCTAssertEqual(testObject.latitude, expectedLatitude)
        XCTAssertEqual(testObject.longitude, expectedLongitude)
        XCTAssertEqual(testObject.altitude, expectedAltitude)
        XCTAssertEqual(testObject.floor, expectedFloor)
        XCTAssertNotNil(testObject.bestTest)
        XCTAssertEqual(testObject.tests.count, 2)
    }

    func testBestTestChoiceStringValues() {
        XCTAssertEqual(BestTestChoice.reproducible.string, "reproducible")
        XCTAssertEqual(BestTestChoice.highestReference.string, "highest reference")
    }

    func testBestTestChoiceStringToEnum() {
        XCTAssertEqual(BestTestChoice.stringToEnum("reproducible"), BestTestChoice.reproducible)
        XCTAssertEqual(BestTestChoice.stringToEnum("highest reference"), BestTestChoice.highestReference)
        XCTAssertEqual(BestTestChoice.stringToEnum("stark"), nil)
    }

    func testLungFunctionZoneStringValues() {
        XCTAssertEqual(LungFunctionZone.greenZone.string, "green zone")
        XCTAssertEqual(LungFunctionZone.yellowZone.string, "yellow zone")
        XCTAssertEqual(LungFunctionZone.redZone.string, "red zone")
    }

    func testLungFunctionZoneStringToEnum() {
        XCTAssertEqual(LungFunctionZone.stringToEnum("green zone"), LungFunctionZone.greenZone)
        XCTAssertEqual(LungFunctionZone.stringToEnum("yellow zone"), LungFunctionZone.yellowZone)
        XCTAssertEqual(LungFunctionZone.stringToEnum("red zone"), LungFunctionZone.redZone)
        XCTAssertEqual(LungFunctionZone.stringToEnum("stark"), nil)
    }

    func testRespiratoryStateStringValues() {
        XCTAssertEqual(RespiratoryState.greenZone.string, "green zone")
        XCTAssertEqual(RespiratoryState.yellowZone.string, "yellow zone")
        XCTAssertEqual(RespiratoryState.redZone.string, "red zone")
        XCTAssertEqual(RespiratoryState.criticalZone.string, "critical zone")
    }

    func testRespiratoryStateStringToEnum() {
        XCTAssertEqual(RespiratoryState.stringToEnum("green zone"), RespiratoryState.greenZone)
        XCTAssertEqual(RespiratoryState.stringToEnum("yellow zone"), RespiratoryState.yellowZone)
        XCTAssertEqual(RespiratoryState.stringToEnum("red zone"), RespiratoryState.redZone)
        XCTAssertEqual(RespiratoryState.stringToEnum("critical zone"), RespiratoryState.criticalZone)
        XCTAssertEqual(RespiratoryState.stringToEnum("stark"), nil)
    }

    func testLocalTestFailureReasonTitleValues() {

        XCTAssertEqual(LocalTestFailureReason.sensorDisconnected.title, "Sensor Error")
        XCTAssertEqual(LocalTestFailureReason.internetDisconnected.title, "Internet Error")
        XCTAssertEqual(LocalTestFailureReason.animationThresholdNotMet.title, "Processing Error")
    }

    func testLocalTestFailureReasonSubtitleValues() {

        XCTAssertEqual(LocalTestFailureReason.sensorDisconnected.subtitle, "Where's the sensor?")
        XCTAssertEqual(LocalTestFailureReason.internetDisconnected.subtitle, "No Internet Connection")
        XCTAssertEqual(LocalTestFailureReason.animationThresholdNotMet.subtitle, "Something went wrong!")
    }

    func testLocalTestFailureReasonMessageValues() {

        XCTAssertEqual(
            LocalTestFailureReason.sensorDisconnected.message,
            "Be sure Wing is plugged in and be careful not to pull on the cord "
                + "when blowing into Wing!"
        )

        XCTAssertEqual(
            LocalTestFailureReason.internetDisconnected.message,
            "You must be connected to the internet in order to take a test. "
                + "Please fix your connection and try again."
        )

        XCTAssertEqual(
            LocalTestFailureReason.animationThresholdNotMet.message,
            "Let's try doing that test again!"
        )
    }

    func testTestSessionStateCodeValues() {

        XCTAssertEqual(TestSessionState.noTest.code, 0)
        XCTAssertEqual(TestSessionState.goodTestFirst.code, 1)
        XCTAssertEqual(TestSessionState.reproducibleTestFinal.code, 2)
        XCTAssertEqual(TestSessionState.notProcessedTestFirst.code, 100)
        XCTAssertEqual(TestSessionState.notReproducibleTestFirst.code, 101)
        XCTAssertEqual(TestSessionState.notReproducibleTestFinal.code, 102)
        XCTAssertEqual(TestSessionState.notProcessedTestFinal.code, 103)
        XCTAssertEqual(TestSessionState.testSessionInterrupted(reason: .internetDisconnected).code, 200)
        XCTAssertEqual(TestSessionState.testSessionInterrupted(reason: .sensorDisconnected).code, 201)
        XCTAssertEqual(TestSessionState.testSessionInterrupted(reason: .animationThresholdNotMet).code, 202)
    }

    func testTestSessionStateStateForCode() {

        XCTAssertEqual(TestSessionState.state(forCode: 0)!, TestSessionState.noTest)
        XCTAssertEqual(TestSessionState.state(forCode: 1)!, TestSessionState.goodTestFirst)
        XCTAssertEqual(TestSessionState.state(forCode: 2)!, TestSessionState.reproducibleTestFinal)
        XCTAssertEqual(TestSessionState.state(forCode: 100)!, TestSessionState.notProcessedTestFirst)
        XCTAssertEqual(TestSessionState.state(forCode: 101)!, TestSessionState.notReproducibleTestFirst)
        XCTAssertEqual(TestSessionState.state(forCode: 102)!, TestSessionState.notReproducibleTestFinal)
        XCTAssertEqual(TestSessionState.state(forCode: 103)!, TestSessionState.notProcessedTestFinal)
        XCTAssertEqual(TestSessionState.state(forCode: 200)!,
                       TestSessionState.testSessionInterrupted(reason: .internetDisconnected))
        XCTAssertEqual(TestSessionState.state(forCode: 201)!,
                       TestSessionState.testSessionInterrupted(reason: .sensorDisconnected))
        XCTAssertEqual(TestSessionState.state(forCode: 202)!,
                       TestSessionState.testSessionInterrupted(reason: .animationThresholdNotMet))
        XCTAssertNil(TestSessionState.state(forCode: 12341234))
    }
}
