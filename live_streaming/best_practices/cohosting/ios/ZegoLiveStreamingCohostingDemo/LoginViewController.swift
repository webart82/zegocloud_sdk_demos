//
//  LoginViewController.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/30.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userIDTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let selfUserID = UserDefaults.standard.string(forKey: "userID") ?? String(UInt32.random(in: 100..<10000))
        let selfUserName = UserDefaults.standard.string(forKey: "userName") ?? randomName()
        userIDTextField.text = selfUserID
        userNameTextField.text = selfUserName
        
        initData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // logout
        ZegoSDKManager.shared.disconnectUser()
    }
    
    func initData() {        
        ZegoSDKManager.shared.initWith(appID: APP_ID, appSign: APP_SIGN)
    }


    @IBAction func loginAction(_ sender: UIButton) {
        let userID = userIDTextField.text ?? "123"
        let userName = userNameTextField.text ?? "Tina"
        
        // save user id and user name.
        UserDefaults.standard.set(userID, forKey: "userID")
        UserDefaults.standard.set(userName, forKey: "userName")
        
        ZegoSDKManager.shared.connectUser(userID: userID, userName: userName) { code in
            if code == 0 {
                self.performSegue(withIdentifier: "login", sender: sender)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let homeVC = segue.destination as? HomeViewController else {
            return
        }
        homeVC.userID = userIDTextField.text ?? "123"
        homeVC.userName = userNameTextField.text ?? "Tina"
    }
}

