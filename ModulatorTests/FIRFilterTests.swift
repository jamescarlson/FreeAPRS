//
//  FIRFilterTests.swift
//  Modulator
//
//  Created by James on 8/23/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

import XCTest
@testable import Modulator

class FIRFilterTests: XCTestCase {
    
    let absoluteAdditivePrecision = Float(0.01)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBasicConvolve() {
        
        var impulse20Samples = [Float](repeating: 0.0, count: 20)
        let oneThird = Float(1.0 / 3.0)
        let averageThree = [Float](repeating: oneThird, count: 3)
        impulse20Samples[0] = 1.0
        let filterAvgThree = FIRFilter(kernel: averageThree)
    
        var expected = [Float](repeating: 0.0, count: 20)
        expected[0] = oneThird
        expected[1] = oneThird
        expected[2] = oneThird
        
        let result = filterAvgThree.filter(&impulse20Samples)
        
        XCTAssert(arrayApproximatelyEqualTo(expected, b: result, eps: absoluteAdditivePrecision), "Output should be three samples of 1/3 value.")
    }
    
    func testOverlapAddKernelShorterThanInput() {
        
        var impulse20Samples = [Float](repeating: 0.0, count: 20)
        let oneThird = Float(1.0 / 3.0)
        let averageThree = [Float](repeating: oneThird, count: 3)
        impulse20Samples[0] = 1.0
        impulse20Samples[19] = 1.0
        let filterAvgThree = FIRFilter(kernel: averageThree)
        
        var expected = [Float](repeating: 0.0, count: 20)
        expected[0] = oneThird * 2
        expected[1] = oneThird * 2
        expected[2] = oneThird
        expected[19] = oneThird
        
        filterAvgThree.filter(&impulse20Samples)
        let result = filterAvgThree.filter(&impulse20Samples)
        
        XCTAssert(arrayApproximatelyEqualTo(expected, b: result, eps: absoluteAdditivePrecision), "Output of second filtering should have additions from previous convolution.")
    
    }
    
    func testOverlapAddKernelLongerThanInputSameBlockLength() {
        var impulse20Samples = [Float](repeating: 0.0, count: 20)
        let oneThird = Float(1.0 / 3.0)
        var averageThree = [Float](repeating: oneThird, count: 3)
        var threeZeros = [Float](repeating: 0.0, count: 3)
        impulse20Samples[0] = 1.0
        impulse20Samples[19] = 1.0
        let filter20U = FIRFilter(kernel: impulse20Samples)
        
        let expected0 = averageThree
        let expected6 = [Float(0.0), oneThird, oneThird]
        let expected7 = [oneThird, Float(0.0), Float(0.0)]
        
        
        
        let result0 = filter20U.filter(&averageThree)
        filter20U.filter(&threeZeros) //1
        filter20U.filter(&threeZeros)
        filter20U.filter(&threeZeros)
        filter20U.filter(&threeZeros)
        filter20U.filter(&threeZeros)
        let result6 = filter20U.filter(&threeZeros) //6
        let result7 = filter20U.filter(&threeZeros) //7
        
        XCTAssert(arrayApproximatelyEqualTo(expected0, b: result0, eps: absoluteAdditivePrecision), "Trivial convolution with long kernel")
        
        XCTAssert(arrayApproximatelyEqualTo(expected6, b: result6, eps: absoluteAdditivePrecision), "Should get overlap from earlier")
        
        XCTAssert(arrayApproximatelyEqualTo(expected7, b: result7, eps: absoluteAdditivePrecision), "Should get overlap from earlier")
    }
    
    func testOverlapAddKernelLongerThanInputDifferentBlockLength() {
        var impulse20Samples = [Float](repeating: 0.0, count: 20)
        let oneThird = Float(1.0 / 3.0)
        var averageThree = [Float](repeating: oneThird, count: 3)
        impulse20Samples[0] = 1.0
        impulse20Samples[19] = 1.0
        let filter20U = FIRFilter(kernel: impulse20Samples)
        
        let expected0 = averageThree
        var expectedRest = [Float](repeating: 0.0, count: 19)
        var nineteenZeros = [Float](repeating: 0.0, count: 19)
        expectedRest[16] = oneThird
        expectedRest[17] = oneThird
        expectedRest[18] = oneThird
        
        let result0 = filter20U.filter(&averageThree)
        let resultRest = filter20U.filter(&nineteenZeros)
        
        XCTAssert(arrayApproximatelyEqualTo(expected0, b: result0, eps: absoluteAdditivePrecision), "Trivial convolution with long kernel")
        
        XCTAssert(arrayApproximatelyEqualTo(expectedRest, b: resultRest, eps: absoluteAdditivePrecision), "Should get overlap from earlier")
    }

    
    func testFIRLowPassCreateAndFilter() {
        let expectedKernel = [Float](
            [  0.00000000e+00,  -7.16752468e-06,  -8.74319329e-05,
                -3.25254595e-04,  -7.82753799e-04,  -1.47886031e-03,
                -2.37249093e-03,  -3.35277359e-03,  -4.23859134e-03,
                -4.78858276e-03,  -4.72138030e-03,  -3.74445793e-03,
                -1.58868150e-03,   1.95531383e-03,   7.00331452e-03,
                1.35506657e-02,   2.14561570e-02,   3.04393811e-02,
                4.00928192e-02,   4.99082297e-02,   5.93152167e-02,
                6.77283631e-02,   7.45981994e-02,   7.94607040e-02,
                8.19800622e-02,   8.19800622e-02,   7.94607040e-02,
                7.45981994e-02,   6.77283631e-02,   5.93152167e-02,
                4.99082297e-02,   4.00928192e-02,   3.04393811e-02,
                2.14561570e-02,   1.35506657e-02,   7.00331452e-03,
                1.95531383e-03,  -1.58868150e-03,  -3.74445793e-03,
                -4.72138030e-03,  -4.78858276e-03,  -4.23859134e-03,
                -3.35277359e-03,  -2.37249093e-03,  -1.47886031e-03,
                -7.82753799e-04,  -3.25254595e-04,  -8.74319329e-05,
                -7.16752468e-06,   0.00000000e+00])
        let filter2000hz48000fs = FIRFilter(filterType: FilterType.lowpass, length: 50, fs: 48000, cutoff: 2000)
        XCTAssert(arrayApproximatelyEqualTo(expectedKernel, b: filter2000hz48000fs.kernel, eps: absoluteAdditivePrecision),
                  "Sinc filter should match up")
        
    }
    
    /*
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    */
    
}
