//
//  NRZIEncoder.swift
//  FreeAPRS
//
//  Created by James on 12/25/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

/** Encodes NRZI from NRZ: That is, a 0/false on the input will cause a change
 in the output from a 1 to 0, or 0 to 1. A 1/true on the input will cause the
 output to stay the same. */
class NRZIEncoder {
    var current = true
    
    func encode(input: [Bool]) -> [Bool] {
        var output = [Bool](repeating: false, count: input.count)
        for i in 0..<input.count {
            if (input[i]) {
                output[i] = current
            } else {
                output[i] = !current
                current = !current
            }
        }
        return output
    }
}
