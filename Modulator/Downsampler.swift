//
//  Downsampler.swift
//  Modulator
//
//  Created by James on 10/24/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

class Downsampler<T> {
    let factor : Int
    var offset : Int
    let defaultValue : T
    
    init(factor: Int, defaultValue: T) {
        self.factor = factor
        self.offset = 0
        self.defaultValue = defaultValue
    }
    
    func downsample(input: [T]) -> [T] {
        let newLength = ((input.count - offset - 1) / self.factor) + 1
        let remainder = (input.count - offset) % self.factor
        let newOffset = (self.factor - remainder) % self.factor
        var output = [T](repeating: defaultValue, count: newLength)
        
        var iIn = offset
        var iOut = 0
        self.offset = newOffset
        while (iIn < input.count) {
            output[iOut] = input[iIn]
            iIn += self.factor
            iOut += 1
        }
        
        return output
    }
}
