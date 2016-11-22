//
//  AudioProcessOperation.swift
//  FreeAPRS
//
//  Created by James on 11/22/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

class AudioProcessOperation : Operation {
    var inputSamples : [Float]?
    
    /* Should only be run after inputSamples is initialized. */
    override func main() {
        if self.isCancelled { return }
        
        process(inputSamples: &self.inputSamples!)
    }
    
    func process(inputSamples: inout [Float]) {
        /* Default implementation does nothing. */
    }
}
