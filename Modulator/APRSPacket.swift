//
//  APRSPacket.swift
//  Modulator
//
//  Created by James on 10/4/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation
import CoreLocation

/* An immutable representation of an APRS packet. */

let flag : UInt8 = 0b01111110

// MARK: Operators

/// Shift each byte in a UInt8 Array left by the amount on the right side
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

/// Shift each byte in a UInt8 Array right by the amount on the right side
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

/// Bitwise Or every item in a UInt8 Array.
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

// Compare two APRSPackets by checking if their byte representation is equal
func ==(lhs: APRSPacket, rhs: APRSPacket) -> Bool {
    return lhs.getAllBytes() == rhs.getAllBytes()
}


// MARK: Packet data and types


/// Types of APRS Packets
enum PacketType : String {
    case location = "Location"
    case object = "Object"
    case item = "Item"
    case message = "Message"
    case status = "Status"
    case other = "Other"
}

/// Types of APRS Messages
enum MessageType {
    case message
    case ack
    case rej
}

/// Struct representing an APRS Message of any of the `MessageType` types.
struct APRSMessage {
    /** Type of this message, if it's an ack or rej (reject), may not have a message body. */
    var type : MessageType
    
    /** Destination of this message. May be different than the packet's
    destination callsign. */
    var destination : String
    
    /// Message Body
    var message : String?
    
    /// ID of this message, will be nil for ack/rej
    var messageID : Int?
    
    /// ID of the message ACKed by this packet
    var messageACK : Int?
    
    /// ID of the message REJected by this packet
    var messageNACK : Int?
}

/// Struct representing an APRS Object or Item
struct APRSObject {
    var name : String
    var alive : Bool
}

/** Struct to store data from the APRS information field in usefule,
 parsed form, such as location, timestamp, object/item information,
 etc. */
struct APRSData {
    /// The type of packet this data represents j
    var type : PacketType? = nil
    
    /** Date/Time this packet was received, or the one given in the
    packet if present. */
    var timestamp : Date? = nil
    
    /// Location contained in the packet,  if present
    var location : CLLocation? = nil
    
    /// Comment contained in the packet, if present
    var comment : String? = nil
    
    /// Status contained in the packet, if present
    var status : String? = nil
    
    /// Message contained in the packet, if present
    var message : APRSMessage? = nil
    
    /// Symbol for this packet, if present
    var symbol : Symbol? = nil
    
    /// Object or item contained in this packet, if present
    var object : APRSObject? = nil
}


/** Class to store received and about-to-be-transmitted APRS Packets.
 
 Class instead of struct since these can get somewhat large with the array of
 bools and all the contianed data.
 
 Does not know anything about the rest of the specification with regard
 to what is stored in the Information field. Has an optional APRSData
 member which can be filled in with .parsePacket() that contains parsed
 data from the Information field. 
 */
class APRSPacket : Equatable {
    /* APRS Frames, for our use, are only Information frames. They look like
        this, each byte is sent LSB first, down along the packet, with bit
        stuffing. Bit stuffing is not shown here.
     
     Min length between flags: 19 bytes, 152 bits (assuming no bits stuffed.)
     Max length between flags: 330 Bytes, 2640 bits (assuming no bits stuffed.)
        3168 if the entire packet was stuffed (i.e. consisted of all 1s). 
     
     ------ Begin APRS Packet ------
     
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
     
     ------ End APRS Packet ------
     
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
    
    // MARK: instance variables
    
    /// Source Callsign
    let source : String
    
    /// Source Command/Response bit - doesn't seem to really do much for UI Frames
    let sourceCommand : Bool
    
    /// Destination Callsign
    let destination : String
    
    /// Destination Command/Response bit
    let destinationCommand : Bool
    
    /// Source Secondary Station Identifier, from 0 to 15
    let sourceSSID : UInt8
    
    /// Destination Secondary Station Identifier, from 0 to 15
    let destinationSSID : UInt8
    
    /** Array of digipeaters representing the desired propagation
    path for this packet */
    let digipeaters : [String]
    
    /// Array of digipeater Secondary Station Identifiers
    let digipeaterSSIDs : [UInt8]
    
    /** Each set to True if this packet has traversed the corresponding
    digipeater from the `digipeaters` array */
    let digipeatersHasBeenRepeated : [Bool]
    
    /** Information field containing most of the useful APRS data such
    as timestamp, location, status, comment, etc. */
    let information : String
    
    /** Frame Check Sequence, a checksum for the packet to ensure it
    has not been corrupted in transit. Computed on initialization. */
    let FCS : UInt16
   
    /** Contains all interesting infromation in parsed format from the
    Information field. */
    var data : APRSData? = nil
    
    /** Representation of this packet in bytes, for translation to and from
    bit-stuffed on the wire format and instance variables. */
    private var allBytes : [UInt8]
    
    /** On the wire format, sans flags, including stuffing such that there are
    no more than 5 ones in a row transmitted. */
    private var stuffedBits : [Bool]
    
    /** In case the initializer is used that allows packets through which do
    not pass the Frame Check Sequence, this is set to false if the packet
    has correct formatting but is not considered "intact" by checksum 
    standards */
    private var passesCRC = true
    
    // MARK: Initialize from information
    
    /** Initialize an APRSPacket using human readable information for
    each field. */
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
        
    }
    
    /* MARK: Initialize from raw bits */
    
    /** Given a string of bits from between two flags, unstuff the bits
        and create an APRSPacket if everything matches up and the checksum
        passes. */
    init?(fromStuffedBitArray: [Bool]) {
        
        
        /* ====== First need to unstuff the input bits. ====== */
        
        self.stuffedBits = fromStuffedBitArray
        
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
                
                if (doEndIndex + 7 >= unstuffedBytes.count) {
                    // Decoded that digipeater info was longer than in actuality
                    return nil
                }
                
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
        
        if (currentIndex > unstuffedBytes.count - 2) {
            return nil
            //Information field was shorter than expected
        }
        
        for x in unstuffedBytes[currentIndex..<unstuffedBytes.count - 2] {
            let u = UnicodeScalar(x)
            information.append(Character(u))
        }
        
        self.information = information
        self.FCS = testFCS
        
    }
    
    /** Given a string of bits from between two flags, unstuff the bits
     and create an APRSPacket if everything matches up. */
    init?(fromStuffedBitArrayUnchecked: [Bool]) {
        
        
        /* ====== First need to unstuff the input bits. ====== */
        
        self.stuffedBits = fromStuffedBitArrayUnchecked
        
        var unstuffedBits = [Bool]()
        
        var contiguous_ones = 0
        
        for bit in fromStuffedBitArrayUnchecked {
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
            passesCRC = false
        }
        if (UInt8(testFCS >> 8) != unstuffedBytes[unstuffedBytes.count - 1]) {
            passesCRC = false
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
                
                if (doEndIndex + 7 >= unstuffedBytes.count) {
                    // Decoded that digipeater info was longer than in actuality
                    return nil
                }
                
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
        
        if (currentIndex > unstuffedBytes.count - 2) {
            return nil
            //Information field was shorter than expected
        }
        
        for x in unstuffedBytes[currentIndex..<unstuffedBytes.count - 2] {
            let u = UnicodeScalar(x)
            information.append(Character(u))
        }
        
        self.information = information
        self.FCS = testFCS
    }
    

    // MARK: Getters
    func getAllBytes() -> [UInt8] {
        return allBytes
    }
    
    func getStuffedBits() -> [Bool] {
        return stuffedBits
    }
    
    // MARK: Parse information field
    /** Parse the information field of the packet into an APRSData and
    set the `data` member of this packet to it. */
    func parsePacket() {
        var data = APRSData()
        
        var ptrToParsedPacket : UnsafeMutablePointer<fap_packet_t>
        
        var inputString = String(describing: self)
        
        ptrToParsedPacket = fap_parseaprs(inputString, UInt32(inputString.utf8.count), 0)
        
        let parsedPacket = ptrToParsedPacket.pointee
        
        if (parsedPacket.error_code != nil) {
            var reason = [CChar](repeating: 0, count: 60)
            
            fap_explain_error(parsedPacket.error_code.pointee, &reason)
            
            var stringReason : String? = nil
            
            /* Avoid ever having to interact with C APIs from Swift if you can. */
            reason.withUnsafeBufferPointer({ (ptr) in
                stringReason = String(cString: ptr.baseAddress!)
            })
            
            NSLog("[parsePacket] Couldn't parse packet: \(inputString), error was: \(stringReason)")
        }
        
        /* Determine the type of packet that we're dealing with. */
        guard let type = parsedPacket.type?.pointee else {
            NSLog("[parsePacket] Nil packet type for packet: \(inputString), returing.")
            return
        }
        
        switch type {
        case fapLOCATION, fapMICE, fapNMEA:
            data.type = .location
            break
        case fapOBJECT:
            data.type = .object
            break
        case fapITEM:
            data.type = .item
            break
        case fapMESSAGE:
            data.type = .message
            break
        case fapSTATUS:
            data.type = .status
            break
        default:
            data.type = .other
            NSLog("[parsePacket] Unsupported packet type for: \(inputString), parsing any recognized parts.")
            break
        }
        
        /* Add Timestamp to packet */
        let packetTimestamp = parsedPacket.timestamp?.pointee
        
        if (packetTimestamp != nil) {
            data.timestamp = Date(timeIntervalSince1970: Double(packetTimestamp!))
        } else {
            data.timestamp = Date(timeIntervalSinceNow: 0)
        }
        
        /* Add location related fields to packet */
        let latitude : Double? = parsedPacket.latitude?.pointee
        let longitude : Double? = parsedPacket.longitude?.pointee
        var positionResolution : Double? = parsedPacket.pos_resolution?.pointee
        
        let altitude : Double = parsedPacket.altitude?.pointee ?? 0
        
        /* Want course to be nil if unknown. fap says 0 is uknown, 360 is north */
        var course : UInt32? = parsedPacket.course?.pointee
        if (course == 0) {
            course = nil
        } else if (course == 360) {
            course = 0
        }
        
        var speed : Double? = parsedPacket.speed?.pointee
        
        /* Do we have basic location information? */
        if (latitude != nil && longitude != nil && positionResolution != nil) {
            
            let locationCoordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
            
            if (CLLocationCoordinate2DIsValid(locationCoordinate)) {
                
                /* Change uncertainty diameter to radius. */
                positionResolution = positionResolution! / 2.0
                
                
                if (course != nil && speed != nil) {
                    /* Change speed from km/h to m/s */
                    speed = speed! / 3.6
                    
                    data.location = CLLocation(coordinate: locationCoordinate, altitude: altitude, horizontalAccuracy: positionResolution!, verticalAccuracy: 0, course: CLLocationDirection(course!), speed: speed!, timestamp: data.timestamp!)
                } else {
                    data.location = CLLocation(coordinate: locationCoordinate, altitude: altitude, horizontalAccuracy: positionResolution!, verticalAccuracy: 0, timestamp: data.timestamp!)
                }
            }
        }
        
        
        /* "/" == 47 == Primary Symbol Table
           "\" == 92 == Secondary Symbol Table
            Leave as nil if niether works. */
        
        let code = String(describing: UnicodeScalar(UInt8(parsedPacket.symbol_code)))
        if (parsedPacket.symbol_table == 47) {
            data.symbol = primarySymbolTable[code]
        } else if (parsedPacket.symbol_table == 92) {
            data.symbol = secondarySymbolTable[code]
        }
        
        if let commmentPtr = parsedPacket.comment {
            data.comment = String(cString: commmentPtr)
        }
        
        if let statusPtr = parsedPacket.status {
            /* The status string in the fap library is not null terminated for
                some reason so we have to give it special treatment here. */
            
            /* One longer to leave the null on the end */
            var statusArray = [Int8](repeating: 0, count: Int(parsedPacket.status_len) + 1)
            for index in 0..<statusArray.count - 1 {
                statusArray[index] = statusPtr.advanced(by: index).pointee
            }
            
            statusArray.withUnsafeBufferPointer({ptr in
                data.status = String(cString: ptr.baseAddress!)
            })
        }
        
        // Parse messaging portion of packet
        
        var doMessageParse = false
        
        if let messagingEnabledPtr = parsedPacket.messaging {
            if (messagingEnabledPtr.pointee != 0) {
                doMessageParse = true
            }
        }
        
        doMessageParse = doMessageParse || data.type == .message
        
        parseMessage : if (doMessageParse) {
            /* Make sure we have a destination */
            
            var messageDest : String
            if let destPtr = parsedPacket.destination {
                messageDest = String(cString: destPtr)
            } else {
                break parseMessage
            }
            
            var message : String? = nil
            if let messagePtr = parsedPacket.message {
                message = String(cString: messagePtr)
            }
            
            var acked : Int? = nil
            if let ackedPtr = parsedPacket.message_ack {
                let ackedString = String(cString: ackedPtr)
                
                acked = Int(ackedString)
            }
            
            var rejected : Int? = nil
            if let rejectedPtr = parsedPacket.message_nack {
                let rejectedString = String(cString: rejectedPtr)
                
                rejected = Int(rejectedString)
            }
            
            var id : Int? = nil
            if let idPtr = parsedPacket.message_id {
                let idString = String(cString: idPtr)
                
                id = Int(idString)
            }
            
            var messageType : MessageType
            if (rejected != nil) {
                messageType = .rej
            } else if (acked != nil) {
                messageType = .ack
            } else {
                messageType = .message
            }
            
            data.message = APRSMessage(type: messageType, destination: messageDest, message: message, messageID: id, messageACK: acked, messageNACK: rejected)
        }
        
        parseObjectItem : if (data.type == .object || data.type == .item) {
            let name : String
            if let namePtr = parsedPacket.object_or_item_name {
                name = String(cString: namePtr)
            } else {
                break parseObjectItem
            }
            
            let alive : Bool
            if let alivePtr = parsedPacket.alive {
                alive = Bool(alivePtr.pointee != 0)
            } else {
                break parseObjectItem
            }
            
            data.object = APRSObject(name: name, alive: alive)
        }
        
        self.data = data
        
        fap_free(ptrToParsedPacket)
    }
}

extension APRSPacket : CustomStringConvertible {
    var description: String {
        
        var digipeaterString = ""
        let destSuffix = (destinationSSID == 0) ? "" : "-" + String(destinationSSID)
        let sourceSuffix = (sourceSSID == 0) ? "" : "-" + String(sourceSSID)
        
        for x in 0..<digipeaters.count {
            digipeaterString.append("," +
                digipeaters[x] + "-" + String(digipeaterSSIDs[x]) +
                (digipeatersHasBeenRepeated[x] ? "*" : ""))
        }
        
        return "\(source)\(sourceSuffix)>\(destination)\(destSuffix)\(digipeaterString):\(information)"
    }
}

extension APRSPacket : Hashable {
    var hashValue : Int {
        get {
            return Int(self.FCS)
        }
    }
}
