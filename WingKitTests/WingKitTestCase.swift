//
//  WingKitTestCase.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/25/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

class WingKitTestCase: XCTestCase {

    var mockNetwork = NetworkMock()
    
    override func setUp() {
        super.setUp()

        Network.shared = mockNetwork
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}
