//
//  SplitComplex.swift
//  Modulator
//
//  Created by James on 9/26/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation
import Accelerate

class SplitComplex {
    var real : UnsafeMutablePointer<Float>
    var imag : UnsafeMutablePointer<Float>
    var dspSC : DSPSplitComplex
    var dspSCPtr : UnsafeMutablePointer<DSPSplitComplex>
    var dspSCConst : UnsafePointer<DSPSplitComplex>
    var abs : [Float] {
        get {
            var result = [Float](repeating: 0.0, count: self.count)
            vDSP_zvabs(self.dspSCConst, 1, &result, 1, vDSP_Length(self.count))
            return result
        }
    }
    let count : Int
    
    //TODO: What is going on here
    /* Upon testing with the stored property version of this, every dspSCConst
    I found inside of ComplexFIRFilter's tests had poitners that were off by 
    around 1184 bytes, right from the start. I'm sleepy and I don't want to 
    debug this anymore so I'm just gonna let the hack live until I feel like
    getting back to it. RIP... 
     
     
    Just gonna stop using arrays and allocate the memory myself.
     */
    
    init(real: [Float], imag: [Float]) {
        assert(real.count == imag.count)
        self.real = UnsafeMutablePointer<Float>.allocate(capacity: real.count)
        self.imag = UnsafeMutablePointer<Float>.allocate(capacity: imag.count)
        
        self.real.initialize(from: real)
        self.imag.initialize(from: imag)
        self.dspSC = DSPSplitComplex(realp: self.real, imagp: self.imag)
        self.dspSCPtr = UnsafeMutablePointer<DSPSplitComplex>(&dspSC)
        self.dspSCConst = UnsafePointer<DSPSplitComplex>(dspSCPtr)
        self.count = real.count
    }
    
    init(sp: SplitComplex, count: Int) {
        assert (sp.count < count)
        self.count = sp.count
        
        self.real = UnsafeMutablePointer<Float>.allocate(capacity: count)
        self.imag = UnsafeMutablePointer<Float>.allocate(capacity: count)
        
        self.real.initialize(to: 0.0, count: count)
        self.real.initialize(from: sp.real, count: sp.count)
        self.imag.initialize(to: 0.0, count: count)
        self.imag.initialize(from: sp.imag, count: sp.count)
        
        
        self.dspSC = DSPSplitComplex(realp: self.real, imagp: self.imag)
        self.dspSCPtr = UnsafeMutablePointer<DSPSplitComplex>(&dspSC)
        self.dspSCConst = UnsafePointer<DSPSplitComplex>(dspSCPtr)
    }
    
    convenience init(count: Int) {
        self.init(repeating: 0.0, count: count)
    }
    
    init(repeating: Float, count: Int) {
        self.count = count
        self.real = UnsafeMutablePointer<Float>.allocate(capacity: count)
        self.imag = UnsafeMutablePointer<Float>.allocate(capacity: count)
        
        self.real.initialize(to: repeating, count: count)
        self.imag.initialize(to: repeating, count: count)
        
        self.dspSC = DSPSplitComplex(realp: self.real, imagp: self.imag)
        self.dspSCPtr = UnsafeMutablePointer<DSPSplitComplex>(&dspSC)
        self.dspSCConst = UnsafePointer<DSPSplitComplex>(dspSCPtr)

    }
    
    init(real: [Float]) {
        self.count = real.count
        self.real = UnsafeMutablePointer<Float>.allocate(capacity: real.count)
        self.imag = UnsafeMutablePointer<Float>.allocate(capacity: real.count)
        
        self.real.initialize(from: real)
        self.imag.initialize(to: 0.0, count: real.count)

        self.dspSC = DSPSplitComplex(realp: self.real, imagp: self.imag)
        self.dspSCPtr = UnsafeMutablePointer<DSPSplitComplex>(&dspSC)
        self.dspSCConst = UnsafePointer<DSPSplitComplex>(dspSCPtr)

    }
    
    init(real: UnsafePointer<Float>, imag: UnsafePointer<Float>, count: Int) {
        self.count = count
        self.real = UnsafeMutablePointer<Float>.allocate(capacity: count)
        self.imag = UnsafeMutablePointer<Float>.allocate(capacity: count)
        
        self.real.initialize(from: real, count: count)
        self.imag.initialize(from: imag, count: count)
        
        self.dspSC = DSPSplitComplex(realp: self.real, imagp: self.imag)
        self.dspSCPtr = UnsafeMutablePointer<DSPSplitComplex>(&dspSC)
        self.dspSCConst = UnsafePointer<DSPSplitComplex>(dspSCPtr)
    }
    
    func testPtrMatch() -> Bool {
        var rv : Bool
            = withUnsafePointer(to: &self.dspSC, {
                (ptr) -> Bool in
                if (ptr != self.dspSCConst) {
                    print(ptr)
                    print(self.dspSCConst)
                    return false
                }
                return true
                })
        return rv
    }
    
    /* Vectorized scale by real. */
    static func *(left: Float, right: SplitComplex) -> SplitComplex {
        var result = SplitComplex(count: right.count)
        var scalar = left
        vDSP_vsmul(right.real, 1, &scalar, result.real, 1, vDSP_Length(right.count))
        vDSP_vsmul(right.imag, 1, &scalar, result.imag, 1, vDSP_Length(right.count))
        return result
    }
    
    static func *(left: SplitComplex, right: Float) -> SplitComplex {
        return right * left
    }
    
    /* Non-vectorized pointwise multiply. Should only be used in setup. */
    static func *(left: SplitComplex, right: [Float]) -> SplitComplex {
        assert(left.count == right.count)
        let realOutputArray = slowPointwiseMultiply(left.real, y: right, count: left.count)
        let imagOutputArray = slowPointwiseMultiply(left.imag, y: right, count: left.count)
        
        let result = SplitComplex(real: realOutputArray, imag: imagOutputArray)
        return result
    }
    
    
    static func *(left: [Float], right: SplitComplex) -> SplitComplex {
        return right * left;
    }
    
    /* Needing the left and right to be inouts irks me...
    Sice dspSCConst is a mutating getter (ha...) they must be. See explanation
    in the property. */
    static func *(left: SplitComplex, right: SplitComplex) -> SplitComplex {
        /* Re{ A * B } = Re{A} * Re{B} - Im{A} * Im{B}
         Im{ A * B } = Re{A} * Im{B} + Re{B} * Im{A} */
        assert(left.count == right.count)
        var result = SplitComplex(count: left.count)
        vDSP_zvmul(left.dspSCConst,     1,
                   right.dspSCConst,   1,
                   &result.dspSC,      1,
                   vDSP_Length(left.count), 1)
        return result
    }
    
    subscript(index: Int) -> DSPComplex {
        get {
            return DSPComplex(real: self.real[index], imag: self.imag[index])
        } set(newValue) {
            self.real[index] = newValue.real
            self.imag[index] = newValue.imag
        }
    }
    
    subscript(start: Int, exclusiveEnd: Int) -> SplitComplex {
        get {
            let advancedReal = self.real.advanced(by: start)
            let advancedImag = self.imag.advanced(by: start)
            return SplitComplex(real: advancedReal,
                                imag: advancedImag,
                                count: exclusiveEnd - start)
        }
    }
    
    deinit {
        self.real.deinitialize(count: self.count)
        self.imag.deinitialize(count: self.count)
        self.real.deallocate(capacity: self.count)
        self.imag.deallocate(capacity: self.count)
    }
}


extension DSPComplex {
    static func *(left: DSPComplex, right: DSPComplex) -> DSPComplex {
        return DSPComplex(real: left.real * right.real - (left.imag * right.imag),
                          imag: left.imag * right.real + (left.real * right.imag))
    }
    
    static func *(left: DSPComplex, right: Float) -> DSPComplex {
        return DSPComplex(real: left.real * right, imag: left.imag * right)
    }
    
    static func *(left: Float, right: DSPComplex) -> DSPComplex {
        return right * left
    }
    
    static func +(left: DSPComplex, right: DSPComplex) -> DSPComplex {
        return DSPComplex(real: left.real + right.real,
                          imag: left.imag + right.imag)
    }
    
    static func +=(left: inout DSPComplex, right: DSPComplex) {
        left = left + right
    }
}
