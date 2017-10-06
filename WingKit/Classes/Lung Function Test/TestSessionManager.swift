//
//  TestSessionManager.swift
//  WingKit
//
//  Created by Matt Wahlig on 10/4/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

public protocol TestSessionManagerDelegate: class {

}

public class TestSessionManager {

    enum Error: Swift.Error {
        case testSessionNotFound
        case uploadTargetCreationFailed
        case invalidUploadTarget
        case invalidRecording
    }

    var testSession: TestSession

    fileprivate var activeUploadTarget: UploadTarget?
    fileprivate var usedUploadTargetIds = [String]()

    public init(testSession: TestSession) {
        self.testSession = testSession
    }

    func startTest() {

    }

    func refreshTestSession(completion: @escaping (Swift.Error?) -> Void) {

        guard let _ = activeUploadTarget else {
            completion(Error.invalidUploadTarget)
            return
        }

        Client.retrieveTestSession(withId: testSession.id) { (testSession, error) in

            guard let testSession = testSession else {
                if let error = error {
                    completion(error)
                } else {
                    completion(Error.testSessionNotFound)
                }

                return
            }

            self.testSession = testSession

            completion(nil)
        }
    }

    func uploadRecording(atFilepath filepath: String, completion: @escaping (Swift.Error?) -> Void) {
        getUploadTarget { (uploadTarget, error) in
            guard let uploadTarget = uploadTarget else {
                completion(error)
                return
            }

            self.activeUploadTarget = uploadTarget
            self.usedUploadTargetIds.append(uploadTarget.id)

            Client.uploadFile(atFilepath: filepath, to: uploadTarget, completion: completion)
        }
    }

    func getUploadTarget(completion: @escaping (UploadTarget?, Swift.Error?) -> Void) {
        if let uploadTarget = testSession.uploadTargets.filter({ !usedUploadTargetIds.contains($0.id) }).first {
            completion(uploadTarget, nil)
            return
        }

        Client.createUploadTarget(forTestSessionId: testSession.id) { (uploadTarget, error) in
            guard let uploadTarget = uploadTarget else {
                if let error = error {
                    completion(nil, error)
                } else {
                    completion(nil, Error.uploadTargetCreationFailed)
                }
                return
            }

            self.testSession.uploadTargets.append(uploadTarget)

            completion(uploadTarget, nil)
        }
    }
}
