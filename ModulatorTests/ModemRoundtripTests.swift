//
//  ModemRoundtripTests.swift
//  FreeAPRS
//
//  Created by James on 12/26/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import XCTest
@testable import FreeAPRS
import Swinject

class ModemRoundtripTests: XCTestCase {
    
    var packet1 : APRSPacket! = nil
    var packet2 : APRSPacket! = nil
    var listener : APRSListener! = nil
    var dataStore : APRSPacketDataStore! = nil
    var audioIOManager : MockAudioIOManager! = nil
    
    var container : Container = Container()
    class MockAudioIOManager : AudioIOManagerProtocol {
        
        var samplesToPass : [Float]? = nil
        
        var dispatcher : AudioDispatcher! = nil
        var source : AudioSource! = nil
        
        
        var preferredSampleRate : Float = 48000
        
        var sampleRate : Float = 48000
        
        var preferredNumberOfInputChannels : Int32 = 1
        var numberOfInputChannels : Int32 = 1
        
        var singleChannelInput : Bool = true;
        
        var channelIndexForSingleChannelInput : Int32 = 0
        
        var preferredNumberOfOutputChannels : Int32 = 1
        var numberOfOutputChannels : Int32 = 1
        
        var preferredSamplesPerBuffer : Int32 = 32769
        
        
        func configureAudioInOut(withPreferredSampleRate: Float,
                                 preferredNumberOfInputChannels: Int32,
                                 preferredNumberOfOutputChannels: Int32,
                                 singleChannelInput: Bool,
                                 channelIndexForSingleChannelInput: Int32,
                                 preferredSamplesPerBuffer: Int32) {
            self.preferredSampleRate = withPreferredSampleRate
            self.sampleRate = withPreferredSampleRate
            self.preferredNumberOfInputChannels = preferredNumberOfInputChannels
            self.numberOfInputChannels = preferredNumberOfInputChannels
            self.preferredNumberOfOutputChannels = preferredNumberOfOutputChannels
            self.numberOfOutputChannels = preferredNumberOfOutputChannels
            self.preferredSamplesPerBuffer = preferredSamplesPerBuffer
        }
        
        func addAudioDispatcher(_ audioDispatcher: AudioDispatcher!) {
            self.dispatcher = audioDispatcher
        }
        
        func addAudioSource(_ audioSource: AudioSource!) {
            self.source = audioSource
        }
        
        func startAudioIn() -> Bool {
            // Don't do anything, rather, will pass samples when a test method
            // is called
            return true;
        }
        
        func endAudioIn() -> Bool {
            // Don't do anything
            return true;
        }
        
        func armAudioOut() -> Bool {
            // Don't do anything
            return true;
        }
        
        func disarmAudioOut() -> Bool {
            // Don't do anything
            return true;
        }
        
        func oneShotPlayAudioOut() {
            // Don't do anything
        }
        
        func pass(samples: [Float]) {
            assert(dispatcher != nil)
            dispatcher.process(monoSamples: samples)
            NSLog("Passing samples starting with: \(samples[0..<4])")
        }
        
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
        container.register(UserDefaults.self) { _ in
            let defaultSetings : [String: Any] = [
            "digipeaterFilterOut" : true,
            "spaceToneSkews" : [Float]([0.25, 0.5, 0.707, 0.9, 1.0, 1.11, 1.414, 2, 4]),
            "preferredFs" : 48000,
            "preFlagTime" : 0.2,
            "postFlagTime" : 0.2
            ]
        
            UserDefaults.standard.register(defaults: defaultSetings)
            return UserDefaults.standard
        }.inObjectScope(.container)
        
        container.register(AudioIOManagerProtocol.self) { r in
            let audioIOManager = MockAudioIOManager()
            
            let ud = r.resolve(UserDefaults.self)
            
            audioIOManager.configureAudioInOut(withPreferredSampleRate: Float(ud!.integer(forKey: "preferredFs")),
                                    preferredNumberOfInputChannels: 1,
                                    preferredNumberOfOutputChannels: 1,
                                    singleChannelInput: true,
                                    channelIndexForSingleChannelInput: 0,
                                    preferredSamplesPerBuffer: 32768)
            return audioIOManager }
            .inObjectScope(.container)
        
        // Modem Classes
        container.register(AudioDispatcher.self) { r in
            AudioDispatcher(operationQueue: r.resolve(OperationQueue.self)!, opFactory: r.resolve(AudioProcessOperationFactory.self)!)
        }
        
        container.register(OperationQueue.self) { _ in
            OperationQueue() }
        
        container.register(AudioSource.self) { r in
            AudioSource(audioIOManager: r.resolve(AudioIOManagerProtocol.self)!)
        }
        
        container.register(APRSListener.self) { r in
            APRSListener(withDataStore: r.resolve(APRSPacketDataStore.self)!, audioIOManager: r.resolve(AudioIOManagerProtocol.self)!, userDefaults: r.resolve(UserDefaults.self)!)
        }
        
        container.register(APRSEncoder.self) { r in
            APRSEncoder(sampleRate: r.resolve(AudioIOManagerProtocol.self)!.sampleRate, userDefaults: r.resolve(UserDefaults.self)!)
        }
        
        container.register(APRSPacketDataStore.self) { r in
            APRSPacketDataStore()
        }.inObjectScope(.container)
        
        
        let builder = APRSPacketBuilder()
        builder.source = "CALL"
        builder.information = ">THIS IS A STATUS"
        
        packet1 = builder.build()!
        
        builder.information = ":RECIPIENT:THIS IS A MESSAGE"
        
        packet2 = builder.build()!
        
        dataStore = container.resolve(APRSPacketDataStore.self)
        
        audioIOManager = container.resolve(AudioIOManagerProtocol.self)! as! MockAudioIOManager
        
        audioIOManager.configureAudioInOut(withPreferredSampleRate: 48000,
                                           preferredNumberOfInputChannels: 1,
                                           preferredNumberOfOutputChannels: 1,
                                           singleChannelInput: true,
                                           channelIndexForSingleChannelInput: 0,
                                           preferredSamplesPerBuffer: 32768)
        
        listener = container.resolve(APRSListener.self)!
        
        listener.startListening()
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRoundTripSimple() {
        let encoder = container.resolve(APRSEncoder.self)!
        
        let packet1Audio = encoder.encode(packet: packet1)
        let packet2Audio = encoder.encode(packet: packet2)
        
        
        audioIOManager.pass(samples: packet1Audio)
        // TODO: Fix this janky sleeping thing making the test pass so that
        // the test passing does not depend on the time to decode.
        usleep(500000)
        XCTAssertEqual(packet1, dataStore[0])
        
        audioIOManager.pass(samples: packet2Audio)
        usleep(500000)
        XCTAssertEqual(packet2, dataStore[1])
        
    }
    
}
