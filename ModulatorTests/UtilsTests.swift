//
//  UtilsTests.swift
//  Modulator
//
//  Created by James on 9/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import XCTest

@testable import FreeAPRS

class UtilsTests: XCTestCase {
    let absoluteAdditivePrecision = Float(0.01)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testHannWindow() {
        let expected = [Float](
            [ 0.0        ,  0.00410499,  0.01635257,  0.03654162,  0.06434065,
              0.09929319,  0.14082532,  0.1882551 ,  0.24080372,  0.29760833,
              0.35773621,  0.42020005,  0.48397421,  0.54801151,  0.61126047,
              0.67268253,  0.73126915,  0.78605833,  0.83615045,  0.88072298,
              0.91904405,  0.95048443,  0.97452787,  0.99077958,  0.9989727 ,
              0.9989727 ,  0.99077958,  0.97452787,  0.95048443,  0.91904405,
              0.88072298,  0.83615045,  0.78605833,  0.73126915,  0.67268253,
              0.61126047,  0.54801151,  0.48397421,  0.42020005,  0.35773621,
              0.29760833,  0.24080372,  0.1882551 ,  0.14082532,  0.09929319,
              0.06434065,  0.03654162,  0.01635257,  0.00410499,  0.0       ])
        let hannResult = hann(50)
        XCTAssert(arrayApproximatelyEqualTo(expected, b: hannResult, eps: absoluteAdditivePrecision),
                  "Hann window should match up")
        
    }
    
}
