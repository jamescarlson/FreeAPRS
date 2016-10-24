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
        var impulse20Samples = SplitComplex(repeating: 0.0, count: 20)
        let oneThird = Float(1.0 / 3.0)
        let oneThirdI = DSPComplex(real: 0, imag: (1.0 / 3.0))
        let averageThreeReal = SplitComplex(real: [Float](repeating: oneThird, count: 3),
                                            imag: [Float](repeating: 0.0, count: 3))
        let averageThreeComplex = SplitComplex(real: [Float](repeating: 0.0, count: 3),
                                               imag: [Float](repeating: oneThird, count: 3))

        var threeZeros = SplitComplex(count: 3)
        impulse20Samples[0] = DSPComplex(real: 0, imag: 1)
        impulse20Samples[19] = DSPComplex(real: 0, imag: 1)
        let filter20U = ComplexFIRFilter(kernel: impulse20Samples)
        
        var expected = SplitComplex(repeating: 0.0, count: 20)
        expected[0] = oneThirdI * 2
        expected[1] = oneThirdI * 2
        expected[2] = oneThirdI
        expected[19] = oneThirdI

        
        let expected0 = averageThreeComplex
        let expected6 = SplitComplex(real: [Float](repeating: 0, count: 3),
                                     imag: [Float(0.0), oneThird, oneThird])
        let expected7 = SplitComplex(real: [Float](repeating: 0, count: 3),
                                     imag: [oneThird, Float(0.0), Float(0.0)])
        
        
        
        let result0 = filter20U.filter(averageThreeReal)
        filter20U.filter(threeZeros) //1
        filter20U.filter(threeZeros)
        filter20U.filter(threeZeros)
        filter20U.filter(threeZeros)
        filter20U.filter(threeZeros)
        let result6 = filter20U.filter(threeZeros) //6
        let result7 = filter20U.filter(threeZeros) //7
        
        XCTAssert(zArrayApproximatelyEqualTo(a: expected0, b: result0, eps: absoluteAdditivePrecision), "Trivial convolution with long kernel")
        
        XCTAssert(zArrayApproximatelyEqualTo(a: expected6, b: result6, eps: absoluteAdditivePrecision), "Should get overlap from earlier")
        
        XCTAssert(zArrayApproximatelyEqualTo(a: expected7, b: result7, eps: absoluteAdditivePrecision), "Should get overlap from earlier")
    }
    
    func testOverlapAddKernelLongerThanInputDifferentBlockLength() {
        var impulse20Samples = SplitComplex(repeating: 0.0, count: 20)
        let oneThird = Float(1.0 / 3.0)
        let oneThirdIandR = DSPComplex(real: oneThird, imag: oneThird)
        var averageThree = SplitComplex(real: [Float](repeating: oneThird, count: 3),
                                        imag: [Float](repeating: 0.0, count: 3))
        impulse20Samples[0] = DSPComplex(real: 1.0, imag: 0.0)
        impulse20Samples[19] = DSPComplex(real: 1.0, imag: 1.0)
        let filter20U = ComplexFIRFilter(kernel: impulse20Samples)
        
        let expected0 = averageThree
        var expectedRest = SplitComplex(repeating: 0.0, count: 19)
        var nineteenZeros = SplitComplex(repeating: 0.0, count: 19)
        expectedRest[16] = oneThirdIandR
        expectedRest[17] = oneThirdIandR
        expectedRest[18] = oneThirdIandR
        
        let result0 = filter20U.filter(averageThree)
        let resultRest = filter20U.filter(nineteenZeros)
        
        XCTAssert(zArrayApproximatelyEqualTo(a: expected0, b: result0, eps: absoluteAdditivePrecision), "Trivial convolution with long kernel")
        
        XCTAssert(zArrayApproximatelyEqualTo(a: expectedRest, b: resultRest, eps: absoluteAdditivePrecision), "Should get overlap from earlier")
    }
    
    
    func testFIRLowPassCreate() {
        let expectedKernelReal = [Float](
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
        let expectedKernel = SplitComplex(real: expectedKernelReal,
                                          imag: [Float](repeating: 0.0, count: 50))
        let filter2000hz48000fs = ComplexFIRFilter(filterType: FilterType.lowpass, length: 50, fs: 48000, cutoff: 2000)
        XCTAssert(zArrayApproximatelyEqualTo(a: expectedKernel, b: filter2000hz48000fs.kernel, eps: absoluteAdditivePrecision),
                  "Sinc filter should match up")
        
    }
    
    func testFIRHighPassCreate() {
        let expectedKernelReal = [Float](
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
        
        let expectedReal = slowPointwiseMultiply(expectedKernelReal, y: multiplier)
        let expected = SplitComplex(real: expectedReal,
                                    imag: [Float](repeating: 0.0, count: 50))
        
        let filterHighPass = ComplexFIRFilter(filterType: FilterType.highpass, length: 50, fs: 48000, cutoff: 2000)
        XCTAssert(zArrayApproximatelyEqualTo(a: expected, b: filterHighPass.kernel, eps: absoluteAdditivePrecision))
    }
    
    func testFIRBandPassCreate() {
        let expectedKernelReal = [Float](
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
        
        let expectedKernel = SplitComplex(real: expectedKernelReal,
                                          imag: [Float](repeating: 0.0, count: 50))
        
        let filterBandPass = ComplexFIRFilter(filterType: FilterType.bandpass, length: 50, fs: 48000, cutoff: 2000, center: 6000)
        XCTAssert(zArrayApproximatelyEqualTo(a: filterBandPass.kernel, b: expectedKernel, eps: absoluteAdditivePrecision))
    }
    
    func testComplexBandpassCreate() {
        var expected = SplitComplex(real: [0.0, -6.705131e-06, -3.38791724e-05, 0.000126033381, 0.000732256914, 0.0013834564, 0.000919319747, -0.00129917695, -0.00396515802, -0.00447966531, -0.00182949076, 0.00145095948, 0.00148620654, -0.00182915654, -0.00271369983, 0.00525080645, 0.0200719927, 0.0284756292, 0.0155355372, -0.0193391498, -0.0554887354, -0.0633590147, -0.0289060064, 0.0307905991, 0.0766915008, 0.0766913369, 0.0307901874, -0.0289064292, -0.0633592308, -0.055488687, -0.0193389151, 0.0155357877, 0.0284757856, 0.0200720187, 0.00525076175, -0.0027137599, -0.0018292038, 0.00148617348, 0.00145093224, -0.00182951323, -0.00447967742, -0.00396515662, -0.00129916309, 0.000919337035, 0.00138346967, 0.000732262211, 0.000126033527, -3.38804493e-05, -6.70549161e-06, 0.0], imag: [-0.0, -2.77734966e-06, -8.17914406e-05, -0.000304271671, -0.000303310662, 0.000573047146, 0.00221943879, 0.00313648139, 0.00164241588, -0.00185554707, -0.00441680709, -0.00350290257, -0.000615602243, -0.000757667876, -0.00655151205, -0.012676456, -0.00831402093, 0.0117950868, 0.0375063904, 0.0466885008, 0.0229840167, -0.0262443647, -0.0697858185, -0.0743344799, -0.0317664035, 0.0317668505, 0.0743346885, 0.0697857141, 0.0262440257, -0.0229843706, -0.0466886945, -0.0375063904, -0.0117949601, 0.00831416622, 0.0126765519, 0.0065515521, 0.000757675269, 0.000615598576, 0.00350289349, 0.00441678986, 0.00185552228, -0.00164244161, -0.00313649839, -0.00221944484, -0.000573043362, 0.000303317793, 0.000304276909, 8.17931868e-05, 2.77745403e-06, 0.0])
        
        
        
        //var modulation = complexExponential(50, fs: 48000, fc: 6000, centered: false)
        let filterBandPassComplex = ComplexFIRFilter(filterType: FilterType.complexbandpass,
                                                     length: 50, fs: 48000,
                                                     cutoff: 2000, center: 6000)
        XCTAssert(zArrayApproximatelyEqualTo(a: filterBandPassComplex.kernel, b: expected, eps: absoluteAdditivePrecision))
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
