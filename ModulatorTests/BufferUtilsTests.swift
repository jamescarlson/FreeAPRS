//
//  BufferUtilsTests.swift
//  Modulator
//
//  Created by James on 10/17/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import XCTest

@testable import FreeAPRS

class BufferUtilsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBoolArrayToUInt8Array() {
        let inputShort = [true, true, true, true, false, false, false, false]
        var inputLonger = [Bool](inputShort)
        inputLonger.append(true)
        inputLonger.append(false)
        inputLonger.append(true)
        
        let expectedShort = [UInt8]([240])
        let expectedLonger = [UInt8]([240, 160])
        
        let outputShort = boolsToBytesBigEndian(input: inputShort)
        let outputLonger = boolsToBytesBigEndian(input: inputLonger)
        
        XCTAssert(expectedShort == outputShort)
        XCTAssert(expectedLonger == outputLonger)
    }
    
    
}
