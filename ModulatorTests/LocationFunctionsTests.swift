//
//  LocationFunctionsTests.swift
//  FreeAPRS
//
//  Created by James on 11/28/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import XCTest
import CoreLocation

@testable import FreeAPRS

class LocationFunctionsTests: XCTestCase {
    
    func testNumSpaces() {
        let input0 = "1234.56"
        let input1 = "1234.5 "
        let input3 = "123 .  "
        let input5 = "1   .  "
        
        let output0 = numSpaces(in: input0)
        let output1 = numSpaces(in: input1)
        let output3 = numSpaces(in: input3)
        let output5 = numSpaces(in: input5)
        
        XCTAssertEqual(0, output0)
        XCTAssertEqual(1, output1)
        XCTAssertEqual(3, output3)
        XCTAssertEqual(5, output5)
    }
    
    /*
    func testLocation() {
        let inputs : [String] = [
        "4545.90N/10040.50W-",
        "1010.10S/02030.40E-",
        "0000.00N/00000.00W-",
        "3   .  N/01234.56E-",
        "30  .  N/10234.56E-",
        "301 .  N/01234.56E-",
        "3012.  N/01234.56E-",
        "3012.3 N/01234.56E-",
        ]
        
        let expectedOutputs : [CLLocation] = [
        CLLocation(
    }
    */
}
