//
//  APRSPacketBuilder.swift
//  Modulator
//
//  Created by James on 10/6/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

/* Makes building an APRSPacket a little easier by providing sensible defaults. */
class APRSPacketBuilder {
    var destination: String = "APRS"
    var destinationSSID: UInt8 = 0
    var destinationCommand: Bool = false
    var source: String?
    var sourceSSID: UInt8 = 0
    var sourceCommand: Bool = false
    var digipeaters: [String] = ["WIDE1"]
    var digipeaterSSIDs: [UInt8] = [1]
    var digipeatersHasBeenRepeated: [Bool] = [false]
    var information: String?
    
    /* Create an APRSPacket from the set parameters. */
    func build() -> APRSPacket? {
        if (source == nil || information == nil) {
            return nil // Must provide at least a source and information
        }
        
        /* OK to force-unwrap optionals here because we checked earlier. */
        let packet = APRSPacket(destination: destination, destinationSSID: destinationSSID, destinationCommand: destinationCommand, source: source!, sourceSSID: sourceSSID, sourceCommand: sourceCommand, digipeaters: digipeaters, digipeaterSSIDs: digipeaterSSIDs, digipeatersHasBeenRepeated: digipeatersHasBeenRepeated, information: information!)
        
        return packet
    }
}
