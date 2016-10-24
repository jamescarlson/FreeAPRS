//
//  Utils.swift
//  Modulator
//
//  Created by James on 8/23/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation
import Accelerate
@testable import Modulator

public func approximatelyEqualTo(_ a : Float, b : Float, eps: Float) -> Bool {
    return fabs(a - b) <= eps
}

public func approximatelyEqualTo(a : DSPComplex, b: DSPComplex, eps: Float) -> Bool {
    return fabs(a.real - b.real) <= eps && fabs(a.imag - b.imag) <= eps
}

public func arrayApproximatelyEqualTo(_ a : [Float], b : [Float], eps: Float) -> Bool {
    if (a.count != b.count) {
        return false
    }
    for index in 0..<a.count {
        if (!approximatelyEqualTo(a[index], b: b[index], eps: eps)) {
            return false
        }
    }
    return true
}

public func arrayEqualTo(a: [UInt8], b: [UInt8]) -> Bool {
    if (a.count != b.count) {
        return false
    }
    
    for index in 0..<a.count {
        if (a[index] != b[index]) {
            return false
        }
    }
    return true
}

public func zArrayApproximatelyEqualTo(a: SplitComplex, b: SplitComplex, eps: Float) -> Bool {
    if (a.count != b.count) {
        return false
    }
    for index in 0..<a.count {
        if (!approximatelyEqualTo(a: a[index], b: b[index], eps: eps)) {
            return false
        }
    }
    return true
}

public func diffBools(a: [Bool], b:[Bool]) -> [Bool] {
    var output = [Bool]()
    let minLength = min(a.count, b.count)
    let maxLength = max(a.count, b.count)
    
    for index in 0..<minLength {
        output.append(a[index] == b[index])
    }
    
    output.append(contentsOf: [Bool](repeating: false, count: maxLength - minLength))
    return output
}
