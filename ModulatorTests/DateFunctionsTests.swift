//
//  DateFunctionsTests.swift
//  FreeAPRS
//
//  Created by James on 11/27/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import XCTest
@testable import FreeAPRS

class DateFunctionsTests: XCTestCase {
    
    func testTimestamp() {
        let now = Date(timeIntervalSinceNow: 0)
        
        let formatter = DateFormatter()
        
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "ddHHmm"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var input = formatter.string(from: now) + "z"
        
        var result = timestamp(from: input)!
        
        var difference = now.timeIntervalSince(result)
        
        XCTAssert(abs(difference) <= 60)
        
        formatter.dateFormat = "ddHHmm"
        formatter.timeZone = TimeZone.current
        
        input = formatter.string(from: now) + "/"
        
        result = timestamp(from: input)!
        
        difference = now.timeIntervalSince(result)
        
        XCTAssert(abs(difference) <= 60)
        
        formatter.dateFormat = "HHmmss"
        formatter.timeZone = TimeZone.current
        
        input = formatter.string(from: now) + "h"
        
        result = timestamp(from: input)!
        
        difference = now.timeIntervalSince(result)
        
        XCTAssert(abs(difference) <= 1)
        
        formatter.dateFormat = "MMddHHmm"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        input = formatter.string(from: now)
        
        result = timestamp(from: input)!
        
        difference = now.timeIntervalSince(result)
        
        XCTAssert(abs(difference) <= 60)
        
        XCTAssertNil(timestamp(from: "short"))
        XCTAssertNil(timestamp(from: "123456y"))
        XCTAssertNil(timestamp(from: "1122330z"))
        
        /* behavior undefined for date component values exceeding limits. */
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
