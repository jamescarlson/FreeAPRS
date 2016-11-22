//
//  APRSPacketDeduplicator.swift
//  FreeAPRS
//
//  Created by James on 11/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

struct Two<T:Hashable,U:Hashable> : Hashable {
    /* Thanks Marek Gregor */
    let values : (T, U)
    
    var hashValue : Int {
        get {
            let (a,b) = values
            return a.hashValue &* 31 &+ b.hashValue
        }
    }
}

struct Three<T: Hashable, U: Hashable, V:Hashable> : Hashable {
    let values : (T, U, V)
    
    var hashValue: Int {
        get {
            let (a, b, c) = values
            return a.hashValue &* (31 * 31) &+ b.hashValue &* 31 &+ c.hashValue
        }
    }
}


func ==<T:Hashable,U:Hashable>(lhs: Two<T,U>, rhs: Two<T,U>) -> Bool {
    return lhs.values == rhs.values
}

func ==<T:Hashable,U:Hashable,V:Hashable>(lhs: Three<T, U, V>, rhs: Three<T, U, V>) -> Bool {
    return lhs.values == rhs.values
}

    /* Two definitions of duplicate packet:
        - Simple: If the packets have the same source callsign and the same
            CRC, they are duplicates. This is used by the committee of
            demodulators to ensure that only one packet comes out even if all
            of the demodulators decode it.
        - Digipeater: If the packets have the same source, destination, and
            information field, we consider them duplicates.
 
    */

class APRSPacketSimpleDeduplicator {
    let numPacketsToRemember: Int
    var packetKeyQueue: CircularBufferQueue<Two<String, UInt16>>
    var packets: [Two<String, UInt16>:APRSPacket]
    
    init(numPacketsToRemember: Int) {
        self.numPacketsToRemember = numPacketsToRemember
        self.packetKeyQueue = CircularBufferQueue<Two<String, UInt16>>(withCapacity: numPacketsToRemember)
        self.packets = [:]
    }
    
    func add(packets: [APRSPacket]) -> [APRSPacket] {
        var result = [APRSPacket]()
        for packet in packets {
            if let actualPacket = self.add(packet: packet) {
                result.append(actualPacket)
            }
        }
        return result
    }
    
    func add(packet: APRSPacket) -> APRSPacket? {
        let key = Two(values: (packet.source, packet.FCS))
        
        if packets[key] != nil {
            return nil
        }
        
        if self.packetKeyQueue.count >= self.numPacketsToRemember {
            let packetKeyToRemove = self.packetKeyQueue.pop()
            self.packets.removeValue(forKey: packetKeyToRemove!)
        }
        
        self.packetKeyQueue.push(key)
        self.packets[key] = packet
        
        return packet
    }
}

class APRSPacketDigipeaterDeduplicator {

    let numPacketsToRemember: Int
    var packetKeyQueue: CircularBufferQueue<Three<String, String, String>>
    var packets: [Three<String, String, String>:APRSPacket]
    
    init(numPacketsToRemember: Int) {
        self.numPacketsToRemember = numPacketsToRemember
        self.packetKeyQueue = CircularBufferQueue<Three<String, String, String>>(withCapacity: numPacketsToRemember)
        self.packets = [:]
    }
    
    func add(packets: [APRSPacket]) -> [APRSPacket] {
        var result = [APRSPacket]()
        for packet in packets {
            if let actualPacket = self.add(packet: packet) {
                result.append(actualPacket)
            }
        }
        return result
    }
    
    func add(packet: APRSPacket) -> APRSPacket? {
        let key = Three(values: (packet.source, packet.destination, packet.information))
        
        if packets[key] != nil {
            return nil
        }
        
        if self.packetKeyQueue.count >= self.numPacketsToRemember {
            let packetKeyToRemove = self.packetKeyQueue.pop()
            self.packets.removeValue(forKey: packetKeyToRemove!)
        }
        
        self.packetKeyQueue.push(key)
        self.packets[key] = packet
        
        return packet
    }
}
