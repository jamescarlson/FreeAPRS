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
    
    let audioProcessOperation : Operation
    
    init(operationQueue: OperationQueue, audioProcessOperation: Operation) {
        self.operationQueue = operationQueue
        self.audioProcessOperation = audioProcessOperation
    }
    
    
    /*
     Can use adapter Operations to get data from a producer and pass data into
    a consumer. 
     
     let op1 = MyProducerOperation()
     let op2 = MyConsumerOperation()
     let adapterOp = BlockOperation
     
     
    */
    
    @objc func process(samples: UnsafePointer<Int16>) {
        //Do something
        NSLog("processing some audio samples its lit")
    }
}
