//
//  Test.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

/// The `TestStatus` enum describes the various states an individual lung function test can be in.
public enum TestStatus: Int {

    /// Indicates the has been initialized and started.
    case started = 0

    /// Indicates the test has finished uploading and processing and without any errors.
    case complete = 1

    /// Indicates the test has finished uploading the recording.
    case uploaded = 2

    /// Indicates the test is currently processing.
    case processing = 3

    /// Indicates that an error occurred while processing the test.
    case error = 4

    var string: String {
        switch self {
        case .started: return "Started"
        case .complete: return "Complete"
        case .uploaded: return "Uploaded"
        case .processing: return "Processing"
        case .error: return "Error"
        }
    }

    static func stringToEnum(_ string: String) -> TestStatus? {
        switch string {
        case "Started": return started
        case "Complete": return complete
        case "Uploaded": return uploaded
        case "Processing": return processing
        case "Error": return error
        default: return nil
        }
    }
}

public struct Test: Decodable {

    struct Keys {
        static let id = "id"
        static let takenAt = "takenAt"
        static let status = "status"
        static let breathDuration = "breathDuration"
        static let exhaleCurve = "exhaleCurve"
        static let totalVolume = "totalVolume"
        static let pef = "pef"
        static let fev1 = "fev1"
        static let upload = "upload"
    }

    /// The identifier for the test.
    public var id: String

    /// The status of processing for the test.
    public var status: TestStatus = .started

    /// The date/time for when the test was taken at.
    public var takenAt: Date?

    /// The length of time that the patient breathed into the device.
    public var breathDuration: Double = 0

    /// The values for the exhale curve graph.
    public var exhaleCurve: [[Double]] = []

    /// The total volume exhaled (in liters).
    public var totalVolume: Double = 0

    /// The PEF value for the test.
    public var pef: Double = 0

    /// The FEV1 value for the test.
    public var fev1: Double = 0

    /// The id of the associated upload target.
    public var uploadTargetId: String?

    init?(from decoder: JSONDecoder) {

        guard let json = decoder.json,
            let id = json[Keys.id] as? String else {
                return nil
        }

        self.id = id
        takenAt = (json[Keys.takenAt] as? String)?.dateFromISO8601

        if let statusString = json[Keys.status] as? String,
            let status = TestStatus.stringToEnum(statusString) {
            self.status = status
        }

        if let breathDuration = json[Keys.breathDuration] as? Double {
            self.breathDuration = breathDuration
        }

        if let exhaleCurve = json[Keys.exhaleCurve] as? [[Double]] {
            self.exhaleCurve = exhaleCurve
        }

        if let totalVolume = json[Keys.totalVolume] as? Double {
            self.totalVolume = totalVolume
        }

        if let pef = json[Keys.pef] as? Double {
            self.pef = pef
        }

        if let fev1 = json[Keys.fev1] as? Double {
            self.fev1 = fev1
        }

        if let uploadTargetId = json[Keys.upload] as? String {
            self.uploadTargetId = uploadTargetId
        }
    }
}
