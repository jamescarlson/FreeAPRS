//
//  TransmitViewController.swift
//  FreeAPRS
//
//  Created by James on 12/25/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import UIKit

class TransmitViewController: UIViewController {
    let audioIOManager = AudioIOManager.sharedInstance()!
    let audioSource = AudioSource(audioIOManager: AudioIOManager.sharedInstance())
    var encoder : APRSEncoder? = nil
    
    @IBOutlet weak var callsignTextField: UITextField!
    @IBOutlet weak var informationTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        encoder = APRSEncoder(sampleRate: audioIOManager.sampleRate)
        audioIOManager.armAudioOut()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func transmitButtonPressed(_ sender: UIButton) {
        
        /*
        var toPlay = sine(2000, fs: audioIOManager.sampleRate, fc: 800, centered: false)
        var mid = sine(60000, fs: audioIOManager.sampleRate, fc: 400, centered: false)
        let end = sine(2000, fs: audioIOManager.sampleRate, fc: 200, centered: false)
        toPlay.append(contentsOf: mid)
        toPlay.append(contentsOf: end)
        
        audioSource.play(monoSamples: toPlay)
        */
        
        var builder = APRSPacketBuilder()
        builder.source = callsignTextField.text
        
        builder.information = informationTextField.text
        
        let packet = builder.build()
        
        if (packet != nil) {
            let toPlay = encoder!.encode(packet: packet!)
            audioSource.play(monoSamples: toPlay)
        }
        
        
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
