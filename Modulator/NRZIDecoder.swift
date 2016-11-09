//
//  NRZIDecoder.swift
//  Modulator
//
//  Created by James on 10/24/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

class NRZIDecoder {
    var lastSample : Bool
    
    init() {
        lastSample = true;
    }
    
    func decode(input: [Bool]) -> [Bool] {
        var output = [Bool](repeating: false, count: input.count)
        for i in 0..<input.count {
            output[i] = input[i] == lastSample
            lastSample = input[i]
        }
        return output
    }
}
