//
//  APRSPacketTests.swift
//  Modulator
//
//  Created by James on 10/19/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import XCTest
@testable import Modulator

func - (left: [UInt8], right: [UInt8]) -> [Int] {
    let newLen = min(left.count, right.count)
    var out = [Int](repeating: 0, count: newLen)
    for x in 0..<newLen {
        out[x] = Int(left[x]) - Int(right[x])
    }
    return out
}

class APRSPacketTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreatePacketWithKnownExample() {
        /* THIS TEST USES AN EXAMPLE THAT DOES NOT PRODUCE BIT STUFFING. */

        let expected : [UInt8] = [126, 130, 160, 164, 166, 64, 64, 96, 150, 154, 108, 132, 152, 142, 96, 174, 146, 136, 138, 98, 64, 98, 174, 146, 136, 138, 100, 64, 99, 3, 240, 58, 83, 77, 83, 71, 84, 69, 32, 32, 32, 58, 64, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 32, 32, 74, 97, 109, 101, 115, 32, 67, 97, 114, 108, 115, 111, 110, 58, 32, 84, 72, 73, 83, 32, 73, 83, 32, 65, 87, 69, 83, 79, 77, 69, 44, 44, 184, 18, 126]
        
        let aprspacket = APRSPacket(destination: "APRS", destinationSSID: 0, destinationCommand: false,source: "KM6BLG", sourceSSID: 0, sourceCommand: false, digipeaters: ["WIDE1", "WIDE2"], digipeaterSSIDs: [1, 1], digipeatersHasBeenRepeated: [false, false], information: ":SMSGTE   :@5555555555  James Carlson: THIS IS AWESOME,,")!

        XCTAssert(expected == aprspacket.getAllBytes())
    }
    
    func testCreatePacketAndGetBits() {
        let aprspacket = APRSPacket(destination: "APRS", destinationSSID: 0, destinationCommand: false,source: "KM6BLG", sourceSSID: 0, sourceCommand: false, digipeaters: ["WIDE1", "WIDE2"], digipeaterSSIDs: [1, 1], digipeatersHasBeenRepeated: [false, false], information: ":SMSGTE   :@5555555555  James Carlson: THIS IS AWESOME,,")!
        
        let expected : [Bool] = [false, true, true, true, true, true, true, false, false, true, false, false, false, false, false, true, false, false, false, false, false, true, false, true, false, false, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, true, true, false, false, true, true, false, true, false, false, true, false, true, false, true, true, false, false, true, false, false, true, true, false, true, true, false, false, false, true, false, false, false, false, true, false, false, false, true, true, false, false, true, false, true, true, true, false, false, false, true, false, false, false, false, false, true, true, false, false, true, true, true, false, true, false, true, false, true, false, false, true, false, false, true, false, false, false, true, false, false, false, true, false, true, false, true, false, false, false, true, false, true, false, false, false, true, true, false, false, false, false, false, false, false, true, false, false, true, false, false, false, true, true, false, false, true, true, true, false, true, false, true, false, true, false, false, true, false, false, true, false, false, false, true, false, false, false, true, false, true, false, true, false, false, false, true, false, false, true, false, false, true, true, false, false, false, false, false, false, false, true, false, true, true, false, false, false, true, true, false, true, true, false, false, false, false, false, false, false, false, false, false, true, true, true, true, false, true, false, true, true, true, false, false, true, true, false, false, true, false, true, false, true, false, true, true, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, false, false, false, true, false, false, false, true, false, true, false, true, false, true, false, true, false, false, false, true, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, true, false, true, true, true, false, false, false, false, false, false, false, false, true, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, true, false, true, false, false, true, false, true, false, false, false, false, true, true, false, true, false, true, true, false, true, true, false, true, false, true, false, false, true, true, false, true, true, false, false, true, true, true, false, false, false, false, false, false, true, false, false, true, true, false, false, false, false, true, false, true, false, false, false, false, true, true, false, false, true, false, false, true, true, true, false, false, false, true, true, false, true, true, false, true, true, false, false, true, true, true, false, true, true, true, true, false, true, true, false, false, true, true, true, false, true, true, false, false, true, false, true, true, true, false, false, false, false, false, false, false, true, false, false, false, false, true, false, true, false, true, false, false, false, false, true, false, false, true, false, true, false, false, true, false, false, true, false, true, true, false, false, true, false, true, false, false, false, false, false, false, true, false, false, true, false, false, true, false, false, true, false, true, true, false, false, true, false, true, false, false, false, false, false, false, true, false, false, true, false, false, false, false, false, true, false, true, true, true, false, true, false, true, false, true, false, true, false, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, false, false, false, true, false, false, false, true, true, false, true, false, false, false, false, true, true, false, true, false, false, false, false, false, true, true, true, false, true, false, true, false, false, true, false, false, false, false, true, true, true, true, true, true, false]
        
        XCTAssert(expected == aprspacket.getStuffedBits())
    }
    
    func testCreatePacketAndGetStuffedBits() {
        let aprspacket = APRSPacket(destination: "APRS", destinationSSID: 0, destinationCommand: false,source: "KM6BLG", sourceSSID: 0, sourceCommand: false, digipeaters: ["WIDE1", "WIDE2"], digipeaterSSIDs: [1, 1], digipeatersHasBeenRepeated: [false, false], information: ":SMSGTE   :@5555555555  James Carlson: ? THIS? IS__? AWESOME,,")!
        
        let expected : [Bool] = [false, true, true, true, true, true, true, false, false, true, false, false, false, false, false, true, false, false, false, false, false, true, false, true, false, false, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, true, true, false, false, true, true, false, true, false, false, true, false, true, false, true, true, false, false, true, false, false, true, true, false, true, true, false, false, false, true, false, false, false, false, true, false, false, false, true, true, false, false, true, false, true, true, true, false, false, false, true, false, false, false, false, false, true, true, false, false, true, true, true, false, true, false, true, false, true, false, false, true, false, false, true, false, false, false, true, false, false, false, true, false, true, false, true, false, false, false, true, false, true, false, false, false, true, true, false, false, false, false, false, false, false, true, false, false, true, false, false, false, true, true, false, false, true, true, true, false, true, false, true, false, true, false, false, true, false, false, true, false, false, false, true, false, false, false, true, false, true, false, true, false, false, false, true, false, false, true, false, false, true, true, false, false, false, false, false, false, false, true, false, true, true, false, false, false, true, true, false, true, true, false, false, false, false, false, false, false, false, false, false, true, true, true, true, false, true, false, true, true, true, false, false, true, true, false, false, true, false, true, false, true, false, true, true, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, false, false, false, true, false, false, false, true, false, true, false, true, false, true, false, true, false, false, false, true, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, true, false, true, true, true, false, false, false, false, false, false, false, false, true, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, true, false, true, false, false, true, false, true, false, false, false, false, true, true, false, true, false, true, true, false, true, true, false, true, false, true, false, false, true, true, false, true, true, false, false, true, true, true, false, false, false, false, false, false, true, false, false, true, true, false, false, false, false, true, false, true, false, false, false, false, true, true, false, false, true, false, false, true, true, true, false, false, false, true, true, false, true, true, false, true, true, false, false, true, true, true, false, true, true, true, true, false, true, true, false, false, true, true, true, false, true, true, false, false, true, false, true, true, true, false, false, false, false, false, false, false, true, false, false, true, true, true, true, true, false, true, false, false, false, false, false, false, false, true, false, false, false, false, true, false, true, false, true, false, false, false, false, true, false, false, true, false, true, false, false, true, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, true, true, false, true, false, false, false, false, false, false, false, true, false, false, true, false, false, true, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, true, true, false, false, true, false, true, true, true, true, true, false, false, true, false, true, true, true, true, true, false, true, false, false, false, false, false, false, false, true, false, false, true, false, false, false, false, false, true, false, true, true, true, false, true, false, true, false, true, false, true, false, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, false, false, false, true, false, false, false, true, true, false, true, false, false, false, false, true, true, false, true, false, false, false, true, true, true, true, false, true, true, true, true, false, true, false, false, false, false, false, true, true, true, true, true, true, false]
        
        XCTAssert(expected == aprspacket.getStuffedBits())
    }
    
    
    func testCreatePacketFromInfoAndThenBackFromBytes() {
        let a = APRSPacket(destination: "APRS", destinationSSID: 0, destinationCommand: false,source: "KM6BLG", sourceSSID: 0, sourceCommand: false, digipeaters: ["WIDE1", "WIDE2"], digipeaterSSIDs: [1, 1], digipeatersHasBeenRepeated: [false, false], information: ":SMSGTE   :@5555555555  James Carlson: ? THIS? IS__? AWESOME,,")!
        
        let bits = a.getStuffedBits()
        let bitsBetweenFlags = Array(bits[8..<bits.count - 8])
        
        XCTAssert(a.getStuffedBitsWithoutFlags() == bitsBetweenFlags)
        
        let b = APRSPacket(fromStuffedBitArray: bitsBetweenFlags)!
        
        let bits2 = b.getStuffedBits()

        XCTAssert(bits == bits2)
        
        XCTAssert(a.destination == b.destination)
        XCTAssert(a.source == b.source)
        XCTAssert(a.destinationSSID == b.destinationSSID)
        XCTAssert(a.sourceSSID == b.sourceSSID)
        XCTAssert(a.destinationCommand == b.destinationCommand)
        XCTAssert(a.sourceCommand == b.sourceCommand)
        XCTAssert(a.digipeaters == b.digipeaters)
        XCTAssert(a.digipeaterSSIDs == b.digipeaterSSIDs)
        XCTAssert(a.digipeatersHasBeenRepeated == b.digipeatersHasBeenRepeated)
        XCTAssert(a.information == b.information)
    }
    
    func testFailToCreateCorruptedPacketFromBits() {
        let a = APRSPacket(destination: "APRS", destinationSSID: 0, destinationCommand: false,source: "KM6BLG", sourceSSID: 0, sourceCommand: false, digipeaters: ["WIDE1", "WIDE2"], digipeaterSSIDs: [1, 1], digipeatersHasBeenRepeated: [false, false], information: ":SMSGTE   :@5555555555  James Carlson: ? THIS? IS__? AWESOME,,")!
        
        var bits = a.getStuffedBitsWithoutFlags()
        bits[97] = !bits[97]
        
        XCTAssertNil(APRSPacket(fromStuffedBitArray: bits))
    }    
}
