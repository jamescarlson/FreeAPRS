//
//  ModulatorTests.swift
//  ModulatorTests
//
//  Created by James on 7/14/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import XCTest
import Accelerate
@testable import Modulator

class ModulatorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFFTPerformance() {
        // This is an example of a performance test case.
        var fftsetup = vDSP_create_fftsetup(vDSP_Length(12), FFTRadix(kFFTRadix2))

        var dummyData = [Float](repeating: 1, count: 4096)
        var dummyImagData = [Float](repeating: -1, count: 4096)
        
        var dummyDataForOutput = [Float](repeating: 0, count:4096)
        var dummyDataForImagOutpt = [Float](repeating: 0, count: 4096)
        
        
        var inputComplexData = DSPSplitComplex(realp: &dummyData, imagp: &dummyImagData)
        var outputComplexData = DSPSplitComplex(realp: &dummyDataForOutput, imagp: &dummyDataForImagOutpt)
        
        self.measure {
            // Put the code you want to measure the time of here.
            for i in 0..<10000 {
                vDSP_fft_zop(fftsetup!, &inputComplexData, 1, &outputComplexData, 1, 12, -1)
            }
            
        }
    }
    
    func testDFTPerformance() {
        var dftsetup = vDSP_DFT_zop_CreateSetup(nil, 4096, vDSP_DFT_Direction.FORWARD)
        
        var dummyData = [Float](repeating: 1, count: 4096)
        var dummyImagData = [Float](repeating: -1, count: 4096)
        
        var dummyDataForOutput = [Float](repeating: 0, count:4096)
        var dummyDataForImagOutpt = [Float](repeating: 0, count: 4096)
        
        
        self.measure {
            for i in 0..<10000 {
                vDSP_DFT_Execute(dftsetup!, dummyData, dummyImagData, &dummyDataForOutput, &dummyDataForImagOutpt)
            }
            
        }
    }
    
}
