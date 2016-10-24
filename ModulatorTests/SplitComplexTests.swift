//
//  SplitComplexTests.swift
//  Modulator
//
//  Created by James on 9/27/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import XCTest
@testable import Modulator

class SplitComplexTests: XCTestCase {
    let absoluteAdditivePrecision = Float(0.01)

    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAbs() {
        var input = SplitComplex(real: [Float(0.0), Float(0.7071), Float(4.0)],
                                 imag: [Float(1.0), Float(0.7071), Float(3.0)])
        var expected = [Float(1.0), Float(1.0), Float(5.0)]
        XCTAssert(arrayApproximatelyEqualTo(input.abs, b: expected, eps: absoluteAdditivePrecision))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
