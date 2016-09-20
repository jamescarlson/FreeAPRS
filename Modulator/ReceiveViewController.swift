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
        let ai : AudioInput = AudioInput(sampleBlockSize: 1024)
        ai.startAudioIn()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

