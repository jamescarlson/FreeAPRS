//
//  FIRFilterTests.swift
//  Modulator
//
//  Created by James on 8/23/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

import XCTest
import Accelerate
@testable import Modulator

class ComplexFIRFilterTests : XCTestCase {
    
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
        
        var impulse20Samples = SplitComplex(repeating: 0.0, count: 16)
        let oneThird = Float(1.0 / 3.0)
        let oneThirdI = DSPComplex(real: 0, imag: (1.0 / 3.0))
        let averageThreeReal = SplitComplex(real: [Float](repeating: oneThird, count: 3),
                                        imag: [Float](repeating: 0.0, count: 3))
        impulse20Samples[0] = DSPComplex(real: 0, imag: 1)
        let filterAvgThree = ComplexFIRFilter(kernel: averageThreeReal)
        
        var expected = SplitComplex(repeating: 0.0, count: 16)
        expected[0] = oneThirdI
        expected[1] = oneThirdI
        expected[2] = oneThirdI
        
        let result = filterAvgThree.filter(impulse20Samples)
        
        XCTAssert(zArrayApproximatelyEqualTo(a: result, b: expected, eps: absoluteAdditivePrecision), "Output should be three samples of 1/3 value.")
    }
    
    func testOverlapAddKernelShorterThanInput() {
        
        var impulse20Samples = SplitComplex(repeating: 0.0, count: 20)
        let oneThird = Float(1.0 / 3.0)
        let oneThirdI = DSPComplex(real: 0, imag: (1.0 / 3.0))
        let averageThreeReal = SplitComplex(real: [Float](repeating: oneThird, count: 3),
                                            imag: [Float](repeating: 0.0, count: 3))
        impulse20Samples[0] = DSPComplex(real: 0, imag: 1)
        impulse20Samples[19] = DSPComplex(real: 0, imag: 1)
        let filterAvgThree = ComplexFIRFilter(kernel: averageThreeReal)
        
        
        var expected = SplitComplex(repeating: 0.0, count: 20)
        expected[0] = oneThirdI * 2
        expected[1] = oneThirdI * 2
        expected[2] = oneThirdI
        expected[19] = oneThirdI
        
        filterAvgThree.filter(impulse20Samples)
        let result = filterAvgThree.filter(impulse20Samples)
        
        XCTAssert(zArrayApproximatelyEqualTo(a: expected, b: result, eps: absoluteAdditivePrecision), "Output of second filtering should have additions from previous convolution.")
        
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
    
    
    func testFIRLowPassCreate() {
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
    
    func testFIRHighPassCreate() {
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
        let multiplier = [Float](
            [1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0,
             1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0,
             1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0,
             1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0,
             1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0]
        )
        
        let expected = slowPointwiseMultiply(expectedKernel, y: multiplier)
        
        let filterHighPass = FIRFilter(filterType: FilterType.highpass, length: 50, fs: 48000, cutoff: 2000)
        XCTAssert(arrayApproximatelyEqualTo(expected, b: filterHighPass.kernel, eps: absoluteAdditivePrecision))
    }
    
    func testFIRBandPassCreate() {
        let expectedKernel = [Float](
            [  0.00000000e+00,  -6.62193171e-06,  -3.34587933e-05,
               1.24469485e-04,   7.23170239e-04,   1.36628855e-03,
               9.07911332e-04,  -1.28305428e-03,  -3.91594994e-03,
               -4.42407033e-03,  -1.80678513e-03,   1.43295014e-03,
               1.46775198e-03,  -1.80647216e-03,  -2.68003090e-03,
               5.18565476e-03,   1.98229293e-02,   2.81222877e-02,
               1.53427583e-02,  -1.90991699e-02,  -5.48001731e-02,
               -6.25727779e-02,  -2.85473033e-02,   3.04085052e-02,
               7.57397921e-02,   7.57396112e-02,   3.04080837e-02,
               -2.85476991e-02,  -6.25729272e-02,  -5.48000458e-02,
               -1.90989051e-02,   1.53429697e-02,   2.81223548e-02,
               1.98228820e-02,   5.18558328e-03,  -2.68006805e-03,
               -1.80647647e-03,   1.46774848e-03,   1.43293039e-03,
               -1.80681003e-03,  -4.42408089e-03,  -3.91594084e-03,
               -1.28303650e-03,   9.07923847e-04,   1.36629173e-03,
               7.23168512e-04,   1.24467769e-04,  -3.34592572e-05,
               -6.62194752e-06,   0.00000000e+00]
        )
        
        let filterBandPass = FIRFilter(filterType: FilterType.bandpass, length: 50, fs: 48000, cutoff: 2000, center: 6000)
        XCTAssert(arrayApproximatelyEqualTo(filterBandPass.kernel, b: expectedKernel, eps: absoluteAdditivePrecision))
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
