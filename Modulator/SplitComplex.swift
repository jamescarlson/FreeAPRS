//
//  SplitComplex.swift
//  Modulator
//
//  Created by James on 9/26/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation
import Accelerate

struct SplitComplex {
    var real : [Float]
    var imag : [Float]
    var dspSC : DSPSplitComplex
    var dspSCConst : UnsafePointer<DSPSplitComplex> {
        mutating get {
            return withUnsafePointer(to: &self.dspSC, { (ptr) -> UnsafePointer<DSPSplitComplex> in
                return ptr } )
        }
    }
    var abs : [Float] {
        mutating get {
            var result = [Float](repeating: 0.0, count: self.count)
            vDSP_zvabs(self.dspSCConst, 1, &result, 1, vDSP_Length(self.count))
            return result
        }
    }
    
    //TODO: What is going on here
    /* Upon testing with the stored property version of this, every dspSCConst
    I found inside of ComplexFIRFilter's tests had poitners that were off by 
    around 1184 bytes, right from the start. I'm sleepy and I don't want to 
    debug this anymore so I'm just gonna let the hack live until I feel like
    getting back to it. RIP... */
    
    init(real: [Float], imag: [Float]) {
        assert(real.count == imag.count)
        self.real = real
        self.imag = imag
        self.dspSC = DSPSplitComplex(realp: &self.real, imagp: &self.imag)
    }
    
    init(sp: SplitComplex, count: Int) {
        assert (sp.count < count)
        self.real = [Float](repeating: 0, count: count)
        self.imag = [Float](repeating: 0, count: count)
        self.dspSC = DSPSplitComplex(realp: &self.real, imagp: &self.imag)

        /*
        vDSP_zvmov(sp.dspSCConst,   1,
                   &self.dspSC,     1,
                   vDSP_Length(sp.count))
        */
        for index in 0..<sp.count {
            self[index] = sp[index]
        }
    }
    
    init(count: Int) {
        self.init(repeating: 0.0, count: count)
    }
    
    init(repeating: Float, count: Int) {
        self.real = [Float](repeating: repeating, count: count)
        self.imag = [Float](repeating: repeating, count: count)
        self.dspSC = DSPSplitComplex(realp: &self.real, imagp: &self.imag)

    }
    
    init(real: [Float]) {
        self.real = real
        self.imag = [Float](repeating: 0.0, count: real.count)
        self.dspSC = DSPSplitComplex(realp: &self.real, imagp: &self.imag)

    }
    
    var count : Int {
        get {
            assert(real.count == imag.count)
            return real.count
        }
    }
    
    mutating func testPtrMatch() -> Bool {
        var p : UnsafePointer<DSPSplitComplex>
            = withUnsafePointer(to: &self.dspSC, {
                (ptr) -> UnsafePointer<DSPSplitComplex> in
                    return ptr
                })
        if (p != self.dspSCConst) {
            print(p)
            print(self.dspSCConst)
            return false
        }
        return true
    }
    
    /* Vectorized scale by real. */
    static func *(left: Float, right: SplitComplex) -> SplitComplex {
        var result = SplitComplex(count: right.count)
        var scalar = left
        vDSP_vsmul(right.real, 1, &scalar, &result.real, 1, vDSP_Length(right.count))
        vDSP_vsmul(right.imag, 1, &scalar, &result.imag, 1, vDSP_Length(right.count))
        return result
    }
    
    static func *(left: SplitComplex, right: Float) -> SplitComplex {
        return right * left
    }
    
    /* Non-vectorized pointwise multiply. Should only be used in setup. */
    static func *(left: SplitComplex, right: [Float]) -> SplitComplex {
        assert(left.count == right.count)
        var result = SplitComplex(real: left.real, imag: left.imag)
        result.real = slowPointwiseMultiply(left.real, y: right)
        result.imag = slowPointwiseMultiply(left.imag, y: right)
        return result
    }
    
    
    static func *(left: [Float], right: SplitComplex) -> SplitComplex {
        return right * left;
    }
    
    /* Needing the left and right to be inouts irks me...
    Sice dspSCConst is a mutating getter (ha...) they must be. See explanation
    in the property. */
    static func *( left: inout SplitComplex, right: inout SplitComplex) -> SplitComplex {
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
            return SplitComplex(real: Array(self.real[start..<exclusiveEnd]),
                                imag: Array(self.imag[start..<exclusiveEnd]))
        }
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
