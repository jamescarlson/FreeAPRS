//
//  APRSPacketDeduplicatorTests.swift
//  FreeAPRS
//
//  Created by James on 11/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import XCTest
@testable import FreeAPRS

class APRSPacketDeduplicatorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDeduplicatePacketsSimple() {
        let simpleDeduplicator = APRSPacketSimpleDeduplicator(numPacketsToRemember: 20)
        
        let builder1 = APRSPacketBuilder()
        builder1.source = "AAAAA"
        builder1.information = "Test"
        
        let builder2 = APRSPacketBuilder()
        builder2.source = "BBBBB"
        builder2.information = "Test 2"
        
        var inArray = [APRSPacket]()
        var expected = [APRSPacket?]()
        var result = [APRSPacket?]()
        
        
        inArray.append(builder1.build()!)
        expected.append(builder1.build()!)
        for _ in 1..<10 {
            inArray.append(builder1.build()!)
            expected.append(nil)
        }
        
        inArray.append(builder2.build()!)
        expected.append(builder2.build()!)
        for _ in 1..<10 {
            inArray.append(builder2.build()!)
            expected.append(nil)
        }
        
        for x in 0..<inArray.count {
            result.append(simpleDeduplicator.add(packet: inArray[x]))
            XCTAssert(result[x] == expected[x])
        }
    }
    
    func testDeduplicatePacketsSimpleNotEnoughRemebering() {
        let simpleDeduplicator = APRSPacketSimpleDeduplicator(numPacketsToRemember: 1)
        
        let builder1 = APRSPacketBuilder()
        builder1.source = "AAAAA"
        builder1.information = "Test"
        
        let builder2 = APRSPacketBuilder()
        builder2.source = "BBBBB"
        builder2.information = "Test 2"
        
        var inArray = [APRSPacket]()
        var expected = [APRSPacket?]()
        var result = [APRSPacket?]()
        
        inArray.append(builder1.build()!)
        expected.append(builder1.build()!)
        for _ in 1..<10 {
            inArray.append(builder1.build()!)
            expected.append(nil)
        }
        
        inArray.append(builder2.build()!)
        expected.append(builder2.build()!)
        for _ in 1..<10 {
            inArray.append(builder2.build()!)
            expected.append(nil)
        }
        
        inArray.append(builder1.build()!)
        expected.append(builder1.build()!)
        for _ in 1..<10 {
            inArray.append(builder1.build()!)
            expected.append(nil)
        }
        
        for x in 0..<inArray.count {
            result.append(simpleDeduplicator.add(packet: inArray[x]))
            NSLog(String(describing: result[x]))
            XCTAssert(result[x] == expected[x])
        }
    }
    
    func testDeduplicatePacketsDigipeater() {
        let simpleDeduplicator = APRSPacketDigipeaterDeduplicator(numPacketsToRemember: 20)
        
        let builder1unrepeated = APRSPacketBuilder()
        builder1unrepeated.source = "AAAAA"
        builder1unrepeated.information = "Test"
        
        let builder2unrepeated = APRSPacketBuilder()
        builder2unrepeated.source = "BBBBB"
        builder2unrepeated.information = "Test 2"
        
        let builder1repeated = APRSPacketBuilder()
        builder1repeated.source = "AAAAA"
        builder1repeated.information = "Test"
        builder1repeated.digipeatersHasBeenRepeated = [true]
        
        
        let builder2repeated = APRSPacketBuilder()
        builder2repeated.source = "BBBBB"
        builder2repeated.information = "Test 2"
        builder2repeated.digipeatersHasBeenRepeated = [true]
        
        var inArray = [APRSPacket]()
        var expected = [APRSPacket?]()
        var result = [APRSPacket?]()
        
        inArray.append(builder1unrepeated.build()!)
        expected.append(builder1unrepeated.build()!)
        for _ in 1..<10 {
            inArray.append(builder1unrepeated.build()!)
            expected.append(nil)
        }
        
        for _ in 0..<10 {
            inArray.append(builder1repeated.build()!)
            expected.append(nil)
        }
        
        inArray.append(builder2unrepeated.build()!)
        expected.append(builder2unrepeated.build()!)
        for _ in 1..<10 {
            inArray.append(builder2unrepeated.build()!)
            expected.append(nil)
        }
        
        for _ in 0..<10 {
            inArray.append(builder2repeated.build()!)
            expected.append(nil)
        }
        
        for x in 0..<inArray.count {
            result.append(simpleDeduplicator.add(packet: inArray[x]))
            XCTAssert(result[x] == expected[x])
        }
    }
    
}
