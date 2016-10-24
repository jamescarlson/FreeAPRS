//
//  ViewController.swift
//  Modulator
//
//  Created by James on 7/14/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import UIKit

class ReceiveViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSLog("Lit")
        
        let opQueue = OperationQueue()
        let op = BlockOperation(block: { () -> () in
            NSLog("yayy block crew")
            })
        
        let dispatcher = AudioDispatcher(operationQueue: opQueue, audioProcessOperation: op)
        let ai : SAMicrophoneInput = SAMicrophoneInput(dispatcher)
        ai.startAudioIn()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

