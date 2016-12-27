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
    @IBOutlet weak var rmsLabel: UILabel!
    @IBOutlet weak var skewDecodesLabel: UILabel!
    let opQueue = OperationQueue()
    let packetStore = APRSPacketDataStore()
    var listener : APRSListener?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listener = APRSListener(withDataStore: packetStore, audioIOManager: AudioIOManager.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(updateTextView), name: packetStore.notificationIdentifier, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateRmsLabel), name: Notification.Name("RMSValue"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDecodesLabel), name: Notification.Name("DecodePerSkew"), object: nil)
        // Do any additional setup after loading the view, typically from a nib.
        
        listener?.startListening()
        
    }

    @IBAction func logReceivedPacketCount(_ sender: AnyObject) {
        NSLog("Number of received packets: \(self.packetStore.count)")
        
    }
    
    func updateRmsLabel(note : Notification) {
        if let value = note.userInfo?["value"] as? Float {
            self.rmsLabel.text = "In RMS: \(value)"
        }
    }
    
    func updateDecodesLabel(note : Notification) {
        if let value = note.userInfo?["decodes"] as? [Int] {
            self.skewDecodesLabel.text = String(describing: value)
        }
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

