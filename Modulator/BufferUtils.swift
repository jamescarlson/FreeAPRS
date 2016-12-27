//
//  File.swift
//  Modulator
//
//  Created by James on 9/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation
import Accelerate

func convertToUnsafeFromFloatArray (ptr: UnsafePointer<Float>) -> UnsafeRawPointer {
    return UnsafeRawPointer(ptr)
}

let crcSeed: UInt16 = 0xFFFF

func boolsToBytesBigEndian(input: [Bool]) -> [UInt8] {
    var output = [UInt8](repeating: 0, count: ((input.count - 1) / 8) + 1)
    for i in 0..<input.count / 8 {
        /* TODO: Check if the compiler would have unrolled this written as a for
            loop and precomputed the powers of 2. Probably doesn't matter much. */
        
        var thisUInt8 : UInt8 = input[i * 8] ? 128 : 0
        thisUInt8 |= input[i * 8 + 1] ? 64 : 0
        thisUInt8 |= input[i * 8 + 2] ? 32 : 0
        thisUInt8 |= input[i * 8 + 3] ? 16 : 0
        thisUInt8 |= input[i * 8 + 4] ? 8 : 0
        thisUInt8 |= input[i * 8 + 5] ? 4 : 0
        thisUInt8 |= input[i * 8 + 6] ? 2 : 0
        thisUInt8 |= input[i * 8 + 7] ? 1 : 0
        
        output[i] = thisUInt8
    }
    
    let offset = Int(input.count / 8)
    
    for i in 0..<input.count % 8 {
        
        /* Bug in swift not allowing me to use the boolean in this ternary 
            operator??? WTF */
        
        if (input[offset * 8 + i]) {
            output[offset] |= UInt8(1 << (7 - i))
        }
    }
    
    return output
}

func boolsToBytesLittleEndian(input: [Bool]) -> [UInt8] {
    var output = [UInt8](repeating: 0, count: ((input.count - 1) / 8) + 1)
    for i in 0..<input.count / 8 {
        /* TODO: Check if the compiler would have unrolled this written as a for
         loop and precomputed the powers of 2. Probably doesn't matter much. */
        
        var thisUInt8 : UInt8 = input[i * 8] ? 1 : 0
        thisUInt8 |= input[i * 8 + 1] ? 2 : 0
        thisUInt8 |= input[i * 8 + 2] ? 4 : 0
        thisUInt8 |= input[i * 8 + 3] ? 8 : 0
        thisUInt8 |= input[i * 8 + 4] ? 16 : 0
        thisUInt8 |= input[i * 8 + 5] ? 32 : 0
        thisUInt8 |= input[i * 8 + 6] ? 64 : 0
        thisUInt8 |= input[i * 8 + 7] ? 128 : 0
        
        output[i] = thisUInt8
    }
    
    let offset = Int(input.count / 8)
    
    for i in 0..<input.count % 8 {
        
        /* Bug in swift not allowing me to use the boolean in this ternary
         operator??? WTF */
        
        if (input[offset * 8 + i]) {
            output[offset] |= UInt8(1 << i)
        }
    }
    
    return output
}

func bytesToBoolsLittleEndian(input: [UInt8]) -> [Bool] {
    var output = [Bool]()
    for byteIndex in 0..<input.count {
        for bitIndex in 0..<8 {
            output.append(((input[byteIndex] >> UInt8(bitIndex)) & 0x01) == 1)
        }
    }
    return output
}

func bytesToBoolsBigEndian(input: [UInt8]) -> [Bool] {
    var output = [Bool]()
    for byteIndex in 0..<input.count {
        for bitIndex in 0..<8 {
            output.append(((input[byteIndex] >> UInt8(7 - bitIndex)) & 0x01) == 1)
        }
    }
    return output
}

func byteToBoolsLittleEndian(input: UInt8) -> [Bool] {
    var output = [Bool]()

    for bitIndex in 0..<8 {
        output.append(((input >> UInt8(7 - bitIndex)) & 0x01) == 1)
    }
    
    return output
}

func reflectUint16(input: UInt16) -> UInt16 {
    var out = UInt16(0)
    for x in 0..<16 {
        out |= ((input >> UInt16(15 - x)) & 1) << UInt16(x)
    }
    return out
}

func reflectByte(input: UInt8) -> UInt8 {
    var out = UInt8(0)
    for x in 0..<8 {
        out |= ((input >> UInt8(7 - x)) & 1) << UInt8(x)
    }
    return out
}

func CRCAX25(data: [Bool]) -> UInt16 {
    /* If data is not a multiple of 8 in length, it will be padded with zeros
    on the end. */
    var sum2 = crcSeed
    
    for bit in data {
        let check = ((sum2 >> 15) ^ (bit ? 1 : 0)) != 0
        sum2 = (sum2 << 1) ^ (check ? 0x1021 : 0)
    }
    
    return reflectUint16(input: ~sum2)
}

func CRCAX25(data: [UInt8]) -> UInt16 {
    
    return CRCAX25(data: bytesToBoolsLittleEndian(input: data))
}

func sign(input: [Float]) -> [Bool] {
    var output = [Bool]()
    output.reserveCapacity(input.count)
    
    for x in input {
        output.append( x > 0.0 )
    }
    
    return output
}

func int16toFloat(_ input: [Int16], channels: Int, channelIndex: Int = 0) -> [Float] {
    var output = [Float](repeating: 0, count: input.count)

    if (channels >= 2) {
        vDSP_vflt16(UnsafePointer<Int16>(input).advanced(by: channelIndex), vDSP_Stride(channels), &output, 1, vDSP_Length(input.count / channels))
    } else {
        vDSP_vflt16(input, 1, &output, 1, vDSP_Length(input.count))
    }
    
    return output
}

extension Array {
    func tile(numberOfTimes: Int) -> Array<Element> {
        var output = Array<Element>()
        for _ in 0..<numberOfTimes {
            output.append(contentsOf: self)
        }
        
        return output
    }
    
}

extension String {
    func trim() -> String
    {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
    var isAlphanumeric: Bool {
        return range(of: "^[a-zA-Z0-9]+$", options: .regularExpression) != nil
    }
    var isUppercaseAlphanumeric: Bool {
        return range(of: "^[A-Z0-9]+$", options: .regularExpression) != nil
    }
}
