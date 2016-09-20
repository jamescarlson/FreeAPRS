//
//  Utils.swift
//  Modulator
//
//  Created by James on 8/23/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

public func approximatelyEqualTo(a : Float, b : Float, eps: Float) -> Bool {
    return fabs(a - b) <= eps
}

public func arrayApproximatelyEqualTo(a : [Float], b : [Float], eps: Float) -> Bool {
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