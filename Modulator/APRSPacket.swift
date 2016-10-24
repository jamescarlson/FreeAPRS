//
//  APRSPacket.swift
//  Modulator
//
//  Created by James on 10/4/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

/* An immutable representation of an APRS packet. */

let flag : UInt8 = 0b01111110


/* Shift each byte in a UInt8 Array left by the amount on the right side */
infix operator <<! : MultiplicationPrecedence

func <<! (left: [UInt8], right: UInt8) -> [UInt8] {
    var output = [UInt8](left)
    for i in 0..<left.count {
        output[i] <<= right
    }
    return output
}

func <<! (left: String.UTF8View, right: UInt8) -> [UInt8] {
    return [UInt8](left) <<! right
}

/* Shift each byte in a UInt8 Array right by the amount on the right side */
infix operator >>! : MultiplicationPrecedence

func >>! (left: [UInt8], right: UInt8) -> [UInt8] {
    var output = [UInt8](left)
    for i in 0..<left.count {
        output[i] >>= right
    }
    return output
}

func >>! (left: String.UTF8View, right: UInt8) -> [UInt8] {
    return [UInt8](left) >>! right
}

/* Bitwise Or every item in a UInt8 Array. */
func | (left: String.UTF8View, right: UInt8) -> [UInt8] {
    return [UInt8](left) | right
}

func | (left: [UInt8], right: UInt8) -> [UInt8] {
    var output = [UInt8](left)
    for i in 0..<left.count {
        output[i] |= right
    }
    return output
}



struct APRSPacket {
    /* APRS Frames, for our use, are only Information frames. They look like
        this, each byte is sent LSB first, down along the packet, with bit
        stuffing. Bit stuffing is not shown here.
     
     Min length between flags: 19 bytes, 152 bits (assuming no bits stuffed.)
     Max length between flags: 330 Bytes, 2640 bits (assuming no bits stuffed.)
        3168 if the entire packet was stuffed (i.e. consisted of all 1s). 
     
     Flag: 01111110
     
     Address: 112/560 Bits
        - At least 14 bytes long.
        - UPPERCASE ALPHA or NUMERIC characters, shifted (<<) one (1) bit left
          to make room for extension bit
            - Extension bit: set to 0 if there are more bytes, 1 if this is the
              last byte transmitted in the Address field.
        Non-Repeater:
            - 7 bits Destination, 7 bits Source
            - Last byte contains SSID - secondary station identifier - 4 bits
                - Bits: CRR[SSID]E
                    - C : Command-Response Bit (leave at 1)
                    - R : Reserved, set to one (1) by default
                    - SSID : 4 bits, a number.
                    - E : HDLC Extension bit as before.
        Repeaters:
            - Add another 7*K bytes, each 7 of which contain the callsign of the
              desired repeater. Encoded as before, except last byte with SSID
              looks like:
                - Bits: HRR[SSID]E
                    - H : "Has been repeated". Sent as 0, set to 1 when a
                      repeater repeats the packet.
                    - R : Reserved, set to one (1) by default
                    - SSID : 4 bits, a number.
                    - E : HDLC Extension bit as before.
        Multiple Repeaters: (And you thought it couldn't get more spaghetti'd!)
            - Just keep adding repeater callsign 7-byte-chunks
            - As the packet goes through each repeater, the repeater in question
              will set the H bit in its SSID byte to one (1) when it retransmits
              the packet.
     
     Control: 8 Bits
        - APRS only uses Unnumbered Frames
        - Bytes: MMM(P/F)MM11 -> 00000011
            - M: Unnumbered Frame Modifier Bits - Set to 0 for UI Frame
            - (P/F): Poll/Final Bit - Set to 0 since we don't want a response.
     
     
     PID: 8 Bits
        0xF0 - 11110000 - No layer 3 protocol implemented
     
     Info: N * 8 Bits - Up to 256 Bytes long
     
     FCS: 16 Bits
        CRC-16-CCITT
     
     Flag: 01111110
     
     -------
     
     Bit Stuffing:
        Any time any sequence of 5 contiguous one (1) bits is sent, a zero (0)
        bit will be inserted after. On receive, any sequence of 5 one (1) bits
        not contained in a Flag will have the following zero (0) discarded. 
     
     Frame Check Sequence:
        16 bits calculated by both sender and receiver, sort of checksum.
        Calculated by ISO 3309 (HDLC) recommendations.
            Side note: This part was extremely unclear due to the multitiude of 
            different ways CRC checksums are computed, as well as the mild lack
            of free information on how to compute the one specific to X.25
            available on the internet. I only got it to work after toying around
            with it for many hours and then using an unoptimized CRC
            implementation.
     
     Invalid Frames:
        - Less than 136 bits, including Flags
        - Not an integer number of bytes long
        - Not bounded by opening and closing Flags
     
     Frame Abort:
        - 15 contiguous ones (1)s or more are sent with No Bit Stuffing
     
     Frame Fill:
        - If continuously transmitting without data, send Flags over and over
    */
    
    let source : String
    let sourceCommand: Bool
    let destination : String
    let destinationCommand: Bool
    let sourceSSID : UInt8
    let destinationSSID : UInt8
    let digipeaters: [String]
    let digipeaterSSIDs : [UInt8]
    let digipeatersHasBeenRepeated : [Bool]
    let information : String
    let FCS : UInt16 //Computed on initialization
    private var allBytes : [UInt8]
    private var stuffedBits : [Bool]
    
    init?(destination: String,
          destinationSSID: UInt8,
          destinationCommand: Bool,
          source: String,
          sourceSSID: UInt8,
          sourceCommand: Bool,
          digipeaters: [String],
          digipeaterSSIDs: [UInt8],
          digipeatersHasBeenRepeated: [Bool],
          information: String) {
        
        
        /* ====== Verify Inputs ====== */
        
        
        if (destination.utf8.count > 6 ||
            !destination.isUppercaseAlphanumeric) { return nil }
        self.destination = destination
        
        if (source.utf8.count > 6 ||
            !source.isUppercaseAlphanumeric) { return nil }
        self.source = source
        
        if (sourceSSID > 15) { return nil }
        self.sourceSSID = sourceSSID
        
        if (destinationSSID > 15) { return nil }
        self.destinationSSID = destinationSSID
        
        if (digipeaters.count != digipeaterSSIDs.count) { return nil }
        if (digipeaters.count != digipeatersHasBeenRepeated.count) { return nil }
        
        for i in 0..<digipeaters.count {
            if (digipeaters[i].utf8.count > 6 ||
                !digipeaters[i].isUppercaseAlphanumeric) { return nil }
            if (digipeaterSSIDs[i] > 15) { return nil }
        }
        self.digipeaters = digipeaters
        self.digipeaterSSIDs = digipeaterSSIDs
        self.digipeatersHasBeenRepeated = digipeatersHasBeenRepeated
        
        if (information.utf8.count > 256 ) { return nil }
        self.information = information
        
        self.destinationCommand = destinationCommand
        self.sourceCommand = sourceCommand
        
        /* ====== Create byte representation without bit stuffing. ====== */
        
        
        allBytes = [UInt8]()
        allBytes.append(flag)
        
        /* Make sure source and destination addresses are 6 bytes. */
        
        allBytes.append(contentsOf: self.destination.utf8 <<! 1)
        allBytes.append(contentsOf:
            String(repeating: " ",
                   count : 6 - self.destination.utf8.count).utf8 <<! 1)
        allBytes.append((self.destinationSSID << 1)
            | 0b01100000
            | (destinationCommand ? 0b10000000 : 0))
        
        allBytes.append(contentsOf: self.source.utf8 <<! 1)
        allBytes.append(contentsOf:
            String(repeating: " ",
                   count : 6 - self.source.utf8.count).utf8 <<! 1)
        allBytes.append((self.sourceSSID << 1)
            | 0b01100000
            | (sourceCommand ? 0b10000000 : 0))
        
        for i in 0..<digipeaters.count {
            
            allBytes.append(contentsOf: self.digipeaters[i].utf8 <<! 1)
            allBytes.append(contentsOf:
                String(repeating: " ",
                       count : 6 - self.digipeaters[i].utf8.count).utf8 <<! 1)
            
            let thisSSID = self.digipeaterSSIDs[i] << 1
            
            /* because swift complains if I do this inside the append(...)
             Wut!? */
            
            allBytes.append(thisSSID |
                (self.digipeatersHasBeenRepeated[i] ? 0b11100000 : 0b01100000))
            
        }
        
        /* Can finally set the Extension bit to 1 since we're done with address
         field. */
        
        allBytes[allBytes.count - 1] |= 0b1
        
        allBytes.append(0b00000011) // Control
        allBytes.append(0b11110000) // PID - No Layer 3 implemented
        
        allBytes.append(contentsOf: self.information.utf8)
        
        
        /* ====== Compute Frame Check Sequence CRC ====== */
        
        
        let everythingButFlag = Array(allBytes.suffix(allBytes.count - 1))
        
        FCS = CRCAX25(data: everythingButFlag)
        
        allBytes.append(UInt8(FCS & 0b11111111))
        allBytes.append(UInt8(FCS >> 8))
        allBytes.append(flag)
        
        
        /* ====== Compute Bit Stuffed Representation ====== */
        
        
        var contiguous_ones = 0;
        
        let allNonFlagBytes = Array(allBytes[1..<allBytes.count - 1])
        let littleEndianUnstuffedBytes = bytesToBoolsLittleEndian(input: allNonFlagBytes)
        
        stuffedBits = [Bool]()
        stuffedBits.append(contentsOf: byteToBoolsLittleEndian(input: flag))
        
        for bit in littleEndianUnstuffedBytes { //All Bytes except flags
            stuffedBits.append(bit)
            if (bit) {
                contiguous_ones += 1
            } else {
                contiguous_ones = 0
            }
            if (contiguous_ones >= 5) {
                stuffedBits.append(false)
                contiguous_ones = 0
            }
        }
        
        stuffedBits.append(contentsOf: byteToBoolsLittleEndian(input: flag))
    }

    func getAllBytes() -> [UInt8] {
        return allBytes
    }
    
    func getStuffedBits() -> [Bool] {
        return stuffedBits
    }
    
    func getStuffedBitsWithoutFlags() -> [Bool] {
        return Array(stuffedBits[8..<stuffedBits.count - 8])
    }
    
    /* Given a string of bits from between two flags, unstuff the bits
        and create an APRSPacket if everything matches up. */
    init?(fromStuffedBitArray: [Bool]) {
        
        
        /* ====== First need to unstuff the input bits. ====== */
        
        self.stuffedBits = byteToBoolsLittleEndian(input: flag)
        self.stuffedBits.append(contentsOf: fromStuffedBitArray)
        self.stuffedBits.append(contentsOf: byteToBoolsLittleEndian(input: flag))
        
        var unstuffedBits = [Bool]()
        
        var contiguous_ones = 0
        
        for bit in fromStuffedBitArray {
            if (contiguous_ones >= 5) {
                if (bit) {
                    return nil // Bit stuffing failure
                }
                contiguous_ones = 0
                continue
            }
            unstuffedBits.append(bit)
            if (bit) {
                contiguous_ones += 1
            } else {
                contiguous_ones = 0
            }
        }
        
        if (unstuffedBits.count % 8 != 0) {
            return nil
        }
        
        
        /* ====== Now parse all the fields ====== */
        
        
        allBytes = [UInt8]()
        allBytes.append(flag)
        
        let unstuffedBytes = boolsToBytesLittleEndian(input: unstuffedBits)
        allBytes.append(contentsOf: unstuffedBytes)
        allBytes.append(flag)
      
        let testFCS = CRCAX25(data: Array(unstuffedBytes[0..<unstuffedBytes.count - 2]))
        
        /* Check FCS */
        if (UInt8(testFCS & 0b11111111) != unstuffedBytes[unstuffedBytes.count - 2]) {
            return nil
        }
        if (UInt8(testFCS >> 8) != unstuffedBytes[unstuffedBytes.count - 1]) {
            return nil
        }
        
        
        var destination = ""
        for x in unstuffedBytes[0..<6] { //Destination
            let u = UnicodeScalar(x >> 1)
            destination.append(Character(u))
        }
        self.destination = destination.trim()
        
        self.destinationCommand = (unstuffedBytes[6] >> 7) == 1
        self.destinationSSID = UInt8((unstuffedBytes[6] >> 1) & 0b1111)
        
        var source = ""
        for x in unstuffedBytes[7..<13] { //Source
            let u = UnicodeScalar(x >> 1)
            source.append(Character(u))
        }
        self.source = source.trim()
        
        self.sourceCommand = (unstuffedBytes[13] >> 7) == 1
        self.sourceSSID = UInt8((unstuffedBytes[13] >> 1) & 0b1111)
        
        var doEndIndex = 13
        var numRepeaters = 0
        
        var digipeaters = [String]()
        var digipeaterSSIDs = [UInt8]()
        var digipeatersHasBeenRepeated = [Bool]()
        
        while ((UInt8(unstuffedBytes[doEndIndex] & 1) != 1)
            && numRepeaters < 8) {
            
                var digipeater = ""
                for x in unstuffedBytes[doEndIndex + 1..<doEndIndex + 7] {
                    let u = UnicodeScalar(x >> 1)
                    digipeater.append(Character(u))
                }
                let digipeaterHasBeenRepeated = (unstuffedBytes[doEndIndex + 7] >> 7) == 1
                let digipeaterSSID = UInt8((unstuffedBytes[doEndIndex + 7] >> 1) & 0b1111)
                
                digipeaters.append(digipeater.trim())
                digipeatersHasBeenRepeated.append(digipeaterHasBeenRepeated)
                digipeaterSSIDs.append(digipeaterSSID)
                
                doEndIndex += 7
                numRepeaters += 1
        }
        
        self.digipeaters = digipeaters
        self.digipeaterSSIDs = digipeaterSSIDs
        self.digipeatersHasBeenRepeated = digipeatersHasBeenRepeated
        
        let currentIndex = doEndIndex + 1 + 2 //Move out of Digipeaters, and
        // move 2 bytes past control and protocol fields
        
        var information = ""
        for x in unstuffedBytes[currentIndex..<unstuffedBytes.count - 2] {
            let u = UnicodeScalar(x)
            information.append(Character(u))
        }
        
        self.information = information
        self.FCS = testFCS
        
    }
    
    
    
}
