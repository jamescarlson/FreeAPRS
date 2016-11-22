//
//  ViewController.swift
//  Modulator
//
//  Created by James on 7/14/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import UIKit

class ReceiveViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    let opQueue = OperationQueue()
    let packetStore = APRSPacketDataStore()
    var listener : APRSListener?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listener = APRSListener(withDataStore: packetStore, skews: [0.25, 0.5, 0.707, 0.9, 1.0, 1.12, 1.414, 2.0, 4.0])
        NotificationCenter.default.addObserver(self, selector: #selector(updateTextView), name: packetStore.notificationIdentifier, object: nil)
        // Do any additional setup after loading the view, typically from a nib.
        
        listener?.startListening()
        
    }

    @IBAction func logReceivedPacketCount(_ sender: AnyObject) {
        NSLog("Number of received packets: \(self.packetStore.count)")
        
    }
    
    func updateTextView() {
        if let newPacket = packetStore.last {
            textView.text.append("\n" + String(describing: newPacket))
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

