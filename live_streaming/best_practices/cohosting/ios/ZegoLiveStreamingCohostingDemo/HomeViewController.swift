//
//  HomeViewController.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/30.
//

import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var liveIDTextField: UITextField!
    
    var userID: String = ""
    var userName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        userIDLabel.text = "User ID: " + userID
        liveIDTextField.text = String(UInt32.random(in: 100..<10000))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let liveVC = segue.destination as? LiveStreamingViewController else {
            return
        }
        
        liveVC.isMySelfHost = segue.identifier! == "start_live"
        liveVC.liveID = liveIDTextField.text ?? ""
    }
}
