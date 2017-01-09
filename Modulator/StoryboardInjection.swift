//
//  StoryboardInjection.swift
//  FreeAPRS
//
//  Created by James on 1/8/17.
//  Copyright © 2017 dimnsionofsound. All rights reserved.
//

import Foundation

import SwinjectStoryboard
import Swinject


extension SwinjectStoryboard {
    class func setup() {
        // "Singletons" first
        defaultContainer.register(UserDefaults.self) { _ in
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
        
        defaultContainer.register(AudioIOManagerProtocol.self) { r in
            let audioIOManager = AudioIOManager()
            
            let ud = r.resolve(UserDefaults.self)
            
            audioIOManager.configureAudioInOut(withPreferredSampleRate: Float(ud!.integer(forKey: "preferredFs")),
                                    preferredNumberOfInputChannels: 1,
                                    preferredNumberOfOutputChannels: 2,
                                    singleChannelInput: true,
                                    channelIndexForSingleChannelInput: 0,
                                    preferredSamplesPerBuffer: 32768)
            return audioIOManager }
            .inObjectScope(.container)
        
        // Modem Classes
        defaultContainer.register(AudioDispatcher.self) { r in
            AudioDispatcher(operationQueue: r.resolve(OperationQueue.self)!, opFactory: r.resolve(AudioProcessOperationFactory.self)!)
        }
        
        defaultContainer.register(OperationQueue.self) { _ in
            OperationQueue() }
        
        defaultContainer.register(AudioSource.self) { r in
            AudioSource(audioIOManager: r.resolve(AudioIOManagerProtocol.self)!)
        }
        
        defaultContainer.register(APRSListener.self) { r in
            APRSListener(withDataStore: r.resolve(APRSPacketDataStore.self)!, audioIOManager: r.resolve(AudioIOManagerProtocol.self)!, userDefaults: r.resolve(UserDefaults.self)!)
        }
        
        defaultContainer.register(APRSEncoder.self) { r in
            APRSEncoder(sampleRate: r.resolve(AudioIOManagerProtocol.self)!.sampleRate, userDefaults: r.resolve(UserDefaults.self)!)
        }
        
        defaultContainer.register(APRSPacketDataStore.self) { r in
            APRSPacketDataStore()
        }.inObjectScope(.container)
        
        
        // View Controllers
        defaultContainer.storyboardInitCompleted(TransmitViewController.self) { r, c in
            c.audioIOManager = r.resolve(AudioIOManagerProtocol.self)
            c.audioSource = r.resolve(AudioSource.self)
            c.encoder = r.resolve(APRSEncoder.self)
        }
        
        defaultContainer.storyboardInitCompleted(PacketTableViewController.self) { r, c in
            c.packetDataStore = r.resolve(APRSPacketDataStore.self)
        }
        
        defaultContainer.storyboardInitCompleted(ReceiveViewController.self) {
            r, c in
            c.packetStore = r.resolve(APRSPacketDataStore.self)
            c.listener = r.resolve(APRSListener.self)
        }
        
        defaultContainer.storyboardInitCompleted(SettingsTableViewController.self) { r, c in }
        
        defaultContainer.storyboardInitCompleted(UINavigationController.self) {
            r, c in
        }
        
        defaultContainer.storyboardInitCompleted(UIViewController.self) {
            r, c in
        }
        
        defaultContainer.storyboardInitCompleted(UITabBarController.self) {
            r, c in
        }
        
        defaultContainer.storyboardInitCompleted(SpaceToneSkewSettingsTableViewController.self) {
            r, c in
            c.userDefaults = r.resolve(UserDefaults.self)
        }
    }
}
