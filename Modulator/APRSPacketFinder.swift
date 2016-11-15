//
//  Listener.swift
//  Modulator
//
//  Created by James on 8/9/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

class APRSPacketFinder {
    /*
    Min length between flags: 19 bytes, 152 bits (assuming no bits stuffed.)
    Max length between flags: 330 Bytes, 2640 bits (assuming no bits stuffed.)
    3168 if the entire packet was stuffed (i.e. consisted of all 1s).
     */
    
    let minPacketLength = 152
    let maxPacketLength = 3168
    let partialFlag : [Bool] = [true, true, true, true, true, true, false]
    var consecutiveOnes = 0
    var betweenFlagValues = [Bool]()
    var bitsAfterLastFoundFlag : [Bool]?
    
    func findPackets(_ input : [Bool]) -> [APRSPacket] {
        var output = [APRSPacket]()
        
        var afterFlagIndices = findIndicesAfterPartialFlags(input: input)
        
        /* First handle case of no flags found. Keep adding to bits since we
            found a flag before, but if waiting too long, set to nil since we
            know a packet cannot be so long. */
        
        if (afterFlagIndices.count == 0) {
            if (bitsAfterLastFoundFlag != nil) {
                if (bitsAfterLastFoundFlag!.count > maxPacketLength) {
                    bitsAfterLastFoundFlag = input
                } else {
                    bitsAfterLastFoundFlag! += input
                }
            }
            
            return output
        }
       
        /* Take care of any packet that is straddling the boundary of two
            calls to findPackets. Takes the bits from the last call that were
            after a flag, appends the bits before the first found flag here, 
            and if within the size conditions, passes to APRSPacket to try to
            decode and add to result. */
        
        if (bitsAfterLastFoundFlag != nil) {
            let lengthBetwenFlagsAroundBoundary =
                bitsAfterLastFoundFlag!.count + afterFlagIndices[0] - 8
            if (lengthBetwenFlagsAroundBoundary >= minPacketLength &&
                lengthBetwenFlagsAroundBoundary <= maxPacketLength) {
                
                var bitsBetweenFlags = bitsAfterLastFoundFlag! +
                    input[0..<afterFlagIndices[0]]
                
                /* Make sure that we don't index into the negative if the flag is
                    on the boundary. */
                bitsBetweenFlags =
                    Array(bitsBetweenFlags[0..<bitsAfterLastFoundFlag!.count +
                        afterFlagIndices[0] - 8])
                
                if let possiblePacket = APRSPacket(fromStuffedBitArrayUnchecked: bitsBetweenFlags) {
                    output.append(possiblePacket)
                }
            }
            
            bitsAfterLastFoundFlag = nil
        }
        
        /* Now can handle the general case of between flags. Will not execute if 
            only one flag is found. */
        
        var lastFlagIndex = afterFlagIndices[0]
        var thisFlagIndex : Int
        for thisFlagIndexIndex in 1..<afterFlagIndices.count {
            thisFlagIndex = afterFlagIndices[thisFlagIndexIndex]
            let packetLength = thisFlagIndex - lastFlagIndex - 8
            
            if (validPacketLength(packetLength)) {
                
                let bitsBetweenFlags = Array(input[lastFlagIndex..<thisFlagIndex - 8])
                if let possiblePacket = APRSPacket(fromStuffedBitArray: bitsBetweenFlags) {
                    output.append(possiblePacket)
                }

            }
            
            lastFlagIndex = thisFlagIndex
        }
        
        /* When we have more bits off the end of a flag. */
        assert(bitsAfterLastFoundFlag == nil)
        
        self.bitsAfterLastFoundFlag = Array(input[lastFlagIndex..<input.count])
        
        return output
    }
    
    func validPacketLength(_ len : Int) -> Bool {
        return (len >= minPacketLength && len <= maxPacketLength)
    }
    
    func findIndicesAfterPartialFlags(input: [Bool]) -> [Int] {
        var output = [Int]()
        
        var consecutiveOnes = 0
        for i in 0..<input.count {
            let thisBit = input[i]
            if (thisBit) {
                consecutiveOnes += 1
            } else {
                if (consecutiveOnes == 6) {
                    // This is a flag.
                    output.append(i + 1)
                }
                consecutiveOnes = 0
            }
        }
        
        return output
    }
    
    
    
}
