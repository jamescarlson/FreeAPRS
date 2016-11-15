//
//  AudioDispatcher.swift
//  Modulator
//
//  Created by James on 10/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

@objc class AudioDispatcher : NSObject {
    let operationQueue : OperationQueue
    
    let opFactory : AudioProcessOperationFactory
    
    init(operationQueue: OperationQueue, opFactory: AudioProcessOperationFactory) {
        self.operationQueue = operationQueue
        self.opFactory = opFactory
    }
    
    
    /*
     Can use adapter Operations to get data from a producer and pass data into
    a consumer. 
     
     let op1 = MyProducerOperation()
     let op2 = MyConsumerOperation()
     let adapterOp = BlockOperation
     
     
    */
    
    @objc func process(samples: UnsafePointer<Int16>, length: Int, channels: Int, channelIndex: Int = 0) {
        //Do something
        
        let bufferPointer = UnsafeBufferPointer(start: samples, count: length)
        let samples = [Int16](bufferPointer)
        
        let floatSamples = int16toFloat(samples, channels: channels, channelIndex: channelIndex)
        
        let operation = opFactory.getOperation()
        operation.inputSamples = floatSamples
        
        operationQueue.addOperation(operation)
        
    }
}
