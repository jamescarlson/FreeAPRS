//
//  APRSPacketTests.swift
//  Modulator
//
//  Created by James on 10/19/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import XCTest
import CoreLocation
@testable import FreeAPRS

func - (left: [UInt8], right: [UInt8]) -> [Int] {
    let newLen = min(left.count, right.count)
    var out = [Int](repeating: 0, count: newLen)
    for x in 0..<newLen {
        out[x] = Int(left[x]) - Int(right[x])
    }
    return out
}

class APRSPacketTests: XCTestCase {
    
    func testCreatePacketWithKnownExample() {
        /* THIS TEST USES AN EXAMPLE THAT DOES NOT PRODUCE BIT STUFFING. */

        let expected : [UInt8] = [126, 130, 160, 164, 166, 64, 64, 96, 150, 154, 108, 132, 152, 142, 96, 174, 146, 136, 138, 98, 64, 98, 174, 146, 136, 138, 100, 64, 99, 3, 240, 58, 83, 77, 83, 71, 84, 69, 32, 32, 32, 58, 64, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 32, 32, 74, 97, 109, 101, 115, 32, 67, 97, 114, 108, 115, 111, 110, 58, 32, 84, 72, 73, 83, 32, 73, 83, 32, 65, 87, 69, 83, 79, 77, 69, 44, 44, 184, 18, 126]
        
        let aprspacket = APRSPacket(destination: "APRS", destinationSSID: 0, destinationCommand: false,source: "KM6BLG", sourceSSID: 0, sourceCommand: false, digipeaters: ["WIDE1", "WIDE2"], digipeaterSSIDs: [1, 1], digipeatersHasBeenRepeated: [false, false], information: ":SMSGTE   :@5555555555  James Carlson: THIS IS AWESOME,,")!

        XCTAssert(expected == aprspacket.getAllBytes())
    }
    
    func testCreatePacketAndGetBits() {
        let aprspacket = APRSPacket(destination: "APRS", destinationSSID: 0, destinationCommand: false,source: "KM6BLG", sourceSSID: 0, sourceCommand: false, digipeaters: ["WIDE1", "WIDE2"], digipeaterSSIDs: [1, 1], digipeatersHasBeenRepeated: [false, false], information: ":SMSGTE   :@5555555555  James Carlson: THIS IS AWESOME,,")!
        
        let expected : [Bool] = [false, true, false, false, false, false, false, true, false, false, false, false, false, true, false, true, false, false, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, true, true, false, false, true, true, false, true, false, false, true, false, true, false, true, true, false, false, true, false, false, true, true, false, true, true, false, false, false, true, false, false, false, false, true, false, false, false, true, true, false, false, true, false, true, true, true, false, false, false, true, false, false, false, false, false, true, true, false, false, true, true, true, false, true, false, true, false, true, false, false, true, false, false, true, false, false, false, true, false, false, false, true, false, true, false, true, false, false, false, true, false, true, false, false, false, true, true, false, false, false, false, false, false, false, true, false, false, true, false, false, false, true, true, false, false, true, true, true, false, true, false, true, false, true, false, false, true, false, false, true, false, false, false, true, false, false, false, true, false, true, false, true, false, false, false, true, false, false, true, false, false, true, true, false, false, false, false, false, false, false, true, false, true, true, false, false, false, true, true, false, true, true, false, false, false, false, false, false, false, false, false, false, true, true, true, true, false, true, false, true, true, true, false, false, true, true, false, false, true, false, true, false, true, false, true, true, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, false, false, false, true, false, false, false, true, false, true, false, true, false, true, false, true, false, false, false, true, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, true, false, true, true, true, false, false, false, false, false, false, false, false, true, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, true, false, true, false, false, true, false, true, false, false, false, false, true, true, false, true, false, true, true, false, true, true, false, true, false, true, false, false, true, true, false, true, true, false, false, true, true, true, false, false, false, false, false, false, true, false, false, true, true, false, false, false, false, true, false, true, false, false, false, false, true, true, false, false, true, false, false, true, true, true, false, false, false, true, true, false, true, true, false, true, true, false, false, true, true, true, false, true, true, true, true, false, true, true, false, false, true, true, true, false, true, true, false, false, true, false, true, true, true, false, false, false, false, false, false, false, true, false, false, false, false, true, false, true, false, true, false, false, false, false, true, false, false, true, false, true, false, false, true, false, false, true, false, true, true, false, false, true, false, true, false, false, false, false, false, false, true, false, false, true, false, false, true, false, false, true, false, true, true, false, false, true, false, true, false, false, false, false, false, false, true, false, false, true, false, false, false, false, false, true, false, true, true, true, false, true, false, true, false, true, false, true, false, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, false, false, false, true, false, false, false, true, true, false, true, false, false, false, false, true, true, false, true, false, false, false, false, false, true, true, true, false, true, false, true, false, false, true, false, false, false]
        
        XCTAssert(expected == aprspacket.getStuffedBits())
    }
    
    func testCreatePacketAndGetStuffedBits() {
        let aprspacket = APRSPacket(destination: "APRS", destinationSSID: 0, destinationCommand: false,source: "KM6BLG", sourceSSID: 0, sourceCommand: false, digipeaters: ["WIDE1", "WIDE2"], digipeaterSSIDs: [1, 1], digipeatersHasBeenRepeated: [false, false], information: ":SMSGTE   :@5555555555  James Carlson: ? THIS? IS__? AWESOME,,")!
        
        let expected : [Bool] = [false, true, false, false, false, false, false, true, false, false, false, false, false, true, false, true, false, false, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, true, true, false, false, true, true, false, true, false, false, true, false, true, false, true, true, false, false, true, false, false, true, true, false, true, true, false, false, false, true, false, false, false, false, true, false, false, false, true, true, false, false, true, false, true, true, true, false, false, false, true, false, false, false, false, false, true, true, false, false, true, true, true, false, true, false, true, false, true, false, false, true, false, false, true, false, false, false, true, false, false, false, true, false, true, false, true, false, false, false, true, false, true, false, false, false, true, true, false, false, false, false, false, false, false, true, false, false, true, false, false, false, true, true, false, false, true, true, true, false, true, false, true, false, true, false, false, true, false, false, true, false, false, false, true, false, false, false, true, false, true, false, true, false, false, false, true, false, false, true, false, false, true, true, false, false, false, false, false, false, false, true, false, true, true, false, false, false, true, true, false, true, true, false, false, false, false, false, false, false, false, false, false, true, true, true, true, false, true, false, true, true, true, false, false, true, true, false, false, true, false, true, false, true, false, true, true, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, false, false, false, true, false, false, false, true, false, true, false, true, false, true, false, true, false, false, false, true, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, true, false, true, true, true, false, false, false, false, false, false, false, false, true, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, true, false, true, false, false, true, false, true, false, false, false, false, true, true, false, true, false, true, true, false, true, true, false, true, false, true, false, false, true, true, false, true, true, false, false, true, true, true, false, false, false, false, false, false, true, false, false, true, true, false, false, false, false, true, false, true, false, false, false, false, true, true, false, false, true, false, false, true, true, true, false, false, false, true, true, false, true, true, false, true, true, false, false, true, true, true, false, true, true, true, true, false, true, true, false, false, true, true, true, false, true, true, false, false, true, false, true, true, true, false, false, false, false, false, false, false, true, false, false, true, true, true, true, true, false, true, false, false, false, false, false, false, false, true, false, false, false, false, true, false, true, false, true, false, false, false, false, true, false, false, true, false, true, false, false, true, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, true, true, false, true, false, false, false, false, false, false, false, true, false, false, true, false, false, true, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, true, true, false, false, true, false, true, true, true, true, true, false, false, true, false, true, true, true, true, true, false, true, false, false, false, false, false, false, false, true, false, false, true, false, false, false, false, false, true, false, true, true, true, false, true, false, true, false, true, false, true, false, false, false, true, false, true, true, false, false, true, false, true, false, true, true, true, true, false, false, true, false, true, false, true, true, false, false, true, false, true, false, true, false, false, false, true, false, false, false, true, true, false, true, false, false, false, false, true, true, false, true, false, false, false, true, true, true, true, false, true, true, true, true, false, true, false, false, false, false]
        XCTAssert(expected == aprspacket.getStuffedBits())
    }
    
    
    func testCreatePacketFromInfoAndThenBackFromBytes() {
        let a = APRSPacket(destination: "APRS",
                           destinationSSID: 0,
                           destinationCommand: false,
                           source: "KM6BLG",
                           sourceSSID: 0,
                           sourceCommand: false,
                           digipeaters: ["WIDE1", "WIDE2"],
                           digipeaterSSIDs: [1, 1],
                           digipeatersHasBeenRepeated: [false, false],
                           information: ":SMSGTE   :@5555555555  James Carlson: ? THIS? IS__? AWESOME,,")!
        
        let b = APRSPacket(fromStuffedBitArray: a.getStuffedBits())!
        
        let bits2 = b.getStuffedBits()

        XCTAssert(a.getStuffedBits() == bits2)
        
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
        let a = APRSPacket(destination: "APRS",
                           destinationSSID: 0,
                           destinationCommand: false,
                           source: "KM6BLG",
                           sourceSSID: 0,
                           sourceCommand: false,
                           digipeaters: ["WIDE1", "WIDE2"],
                           digipeaterSSIDs: [1, 1],
                           digipeatersHasBeenRepeated: [false, false],
                           information: ":SMSGTE   :@5555555555  James Carlson: ? THIS? IS__? AWESOME,,")!
        
        var bits = a.getStuffedBits()
        bits[97] = !bits[97]
        
        XCTAssertNil(APRSPacket(fromStuffedBitArray: bits))
    }
    
    func testParsePacketMessage() {
         var a = APRSPacket(destination: "APRS",
                           destinationSSID: 0,
                           destinationCommand: false,
                           source: "KM6BLG",
                           sourceSSID: 0,
                           sourceCommand: false,
                           digipeaters: ["WIDE1", "WIDE2"],
                           digipeaterSSIDs: [1, 1],
                           digipeatersHasBeenRepeated: [false, false],
                           information: ":SMSGTE   :@5555555555  James Carlson: ? THIS? IS__? AWESOME,,")!
        
        a.parsePacket()
        
        XCTAssertEqual(a.data?.type, PacketType.message)
        XCTAssertEqual(a.data?.comment, nil)
        XCTAssertEqual(a.data?.message?.message, "@5555555555  James Carlson: ? THIS? IS__? AWESOME,,")
        XCTAssertEqual(a.data?.message?.destination, "SMSGTE")
        XCTAssertEqual(a.data?.message?.messageID, nil)
    }
    
    func testParsePacketLocation() {
        var builder = APRSPacketBuilder()
        builder.source = "KM6BLG"
        builder.information = "!0123.45N/01234.56Wj"
        
        var packet = builder.build()
        
        packet?.parsePacket()
        
        let expectedLocation = CLLocation(latitude: 1.3908, longitude: -12.576)
        
        XCTAssertEqual(packet?.data?.symbol, Symbol.jeep)
        XCTAssertEqual(packet?.data?.type, PacketType.location)
        XCTAssert(expectedLocation.distance(from: (packet?.data?.location)!) < 20)
        
    }
    
    func testParsePacketLocationWithTimestamp() {
        var builder = APRSPacketBuilder()
        builder.source = "KM6BLG"
        builder.information = "/234517h0123.45N/01234.56Wj"
        
        var packetLocal = builder.build()
        
        packetLocal?.parsePacket()
        
        let expectedLocation = CLLocation(latitude: 1.3908, longitude: -12.576)
        
        XCTAssertEqual(packetLocal?.data?.symbol, Symbol.jeep)
        XCTAssert(expectedLocation.distance(from: (packetLocal?.data?.location)!) < 20)
        
        /* If the date in the packet would be in the future if we just took the
            day to be today, we need to make sure we compare it to a date in
            the past. libfap seems to (correctly) only return dates in the past.
            */
        var components = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: Date(timeIntervalSinceNow: 0))
        components.setValue(23, for: .hour)
        components.setValue(45, for: .minute)
        components.setValue(17, for: .second)
        
        
        var expectedTime = components.date!
        
        if (expectedTime > Date(timeIntervalSinceNow: 0)) {
            expectedTime = expectedTime.addingTimeInterval(-86400)
        }
        
        XCTAssert(abs(Double((packetLocal?.data?.timestamp!.timeIntervalSince(expectedTime))!)) < 2.0)
        
        components = Calendar.current.dateComponents(in: TimeZone.current, from: Date(timeIntervalSinceNow: 0))
        
        builder.information = "/092345/0123.45N/01234.56Wj"
        var packetZulu = builder.build()
        
        packetZulu?.parsePacket()
        
        components.setValue(9, for: .day)
        components.setValue(23, for: .hour)
        components.setValue(45, for: .minute)
        
        expectedTime = components.date!
        if (expectedTime > Date(timeIntervalSinceNow: 0)) {
            expectedTime = expectedTime.addingTimeInterval(-86400)
        }
        
        XCTAssert(abs(Double((packetZulu?.data?.timestamp!.timeIntervalSince(expectedTime))!)) < 120.0)
    
    }
    
    func testParsePacketLocationWithComment() {
        var builder = APRSPacketBuilder()
        builder.source = "KM6BLG"
        builder.information = "/234517h0123.45N/01234.56WjThis Is A Comment"
        
        var packet = builder.build()
        
        packet?.parsePacket()
        
        XCTAssertEqual(packet?.data?.comment, "This Is A Comment")
    }
    
    func testParsePacketObject() {
        var builder = APRSPacketBuilder()
        builder.source = "KM6BLG"
        builder.information = ";LEADER   *092345z4903.50N/07201.75W>088/036"
        
        var packet = builder.build()
        
        packet?.parsePacket()
        
        XCTAssertEqual(packet?.data?.type, PacketType.object)
        XCTAssertEqual(packet?.data?.object?.alive, true)
        XCTAssertEqual(packet?.data?.object?.name, "LEADER   ")
        XCTAssertEqualWithAccuracy(Double((packet?.data?.location?.course)!), 88.0, accuracy: 1.0)
        XCTAssertEqualWithAccuracy(Double((packet?.data?.location?.speed)!), 18.52, accuracy: 1.0)
    }
    
    func testParsePacketItem() {
        var builder = APRSPacketBuilder()
        builder.source = "KM6BLG"
        builder.information = ")AID #2!4903.50N/07201.75WA"
        
        var packet = builder.build()
        
        packet?.parsePacket()
        
        XCTAssertEqual(packet?.data?.type, PacketType.item)
        XCTAssertEqual(packet?.data?.object?.alive, true)
        XCTAssertEqual(packet?.data?.object?.name, "AID #2")
        XCTAssertEqual(packet?.data?.symbol, Symbol.aidStation)
        
    }
    
    func testParsePacketStatus() {
        var builder = APRSPacketBuilder()
        builder.source = "KM6BLG"
        builder.information = ">this is a status"
        
        var packet = builder.build()
        
        packet?.parsePacket()
        
        XCTAssertEqual(packet?.data?.status, "this is a status")
    }
    
    
    
    
}
