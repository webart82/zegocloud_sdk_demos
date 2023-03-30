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
    
    
    @IBAction func startLiveAction(_ sender: Any) {
        
        
    }
    
    @IBAction func watchLiveAction(_ sender: Any) {
        
        
    }
    
}
