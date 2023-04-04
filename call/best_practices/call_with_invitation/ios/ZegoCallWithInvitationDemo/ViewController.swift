//
//  ViewController.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import UIKit
import Toast
import ZIM

class ViewController: UIViewController {
    
    
    @IBOutlet weak var inviteeUserIDTextField: UITextField!
    @IBOutlet weak var userIDDisplayLabel: UILabel!
    
    var myUserID: String = ""
    var invitee: UserInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        myUserID = "\(Int32(arc4random() % 100000))"
        userIDDisplayLabel.text = "my userid:\(myUserID)"
        ZegoSDKManager.shared.addZIMEventHandler(self)
        loginZIM()
    }
    
    func loginZIM() {
        ZegoSDKManager.shared.connectUser(userID: "\(myUserID)", userName: "user_\(myUserID)", token: nil) { errorCode, errorMessage in
            if errorCode != 0 {
                // login sucess
                self.view.makeToast("zim login fail:\(errorCode)", duration: 2.0, position: .center)
            }
        }
    }
    
    @IBAction func voiceCallClick(_ sender: UIButton) {
        startCall(.voice)
    }
    
    @IBAction func videoCallClick(_ sender: UIButton) {
        startCall(.video)
    }
    
    func startCall(_ type: CallType)  {
        guard let inviteeUserID = inviteeUserIDTextField.text else { return }
        invitee = UserInfo(userID: inviteeUserID, userName: "user_\(inviteeUserID)")
        //send call invitation
        ZegoSDKManager.shared.sendInvitation(with: [inviteeUserID], type: type) { errorCode, errorMessage, invitationID, errorInvitees in
            if errorCode == 0 {
                // call waiting
                if errorInvitees.contains(inviteeUserID) {
                    self.view.makeToast("user is not online", duration: 2.0, position: .center)
                } else {
                    self.joinRoom(roomID: invitationID)
                }
            } else {
                self.view.makeToast("call fail:\(errorCode)", duration: 2.0, position: .center)
            }
        }
    }
    
    func joinRoom(roomID: String) {
        ZegoSDKManager.shared.joinRoom(userID: myUserID, userName: "user_\(myUserID)", roomID: roomID) { errorCode, errorMessage in
            if errorCode == 0 {
                guard let invitee = self.invitee else { return }
                self.showCallWaitingPage(invitee: invitee)
            } else {
                self.view.makeToast("join room fail\(errorCode)", duration: 2.0, position: .center)
            }
        }
    }
    
    func showCallPage() {
        let callMainPage: CallingViewController = Bundle.main.loadNibNamed("CallingViewController", owner: self, options: nil)?.first as! CallingViewController
        callMainPage.modalPresentationStyle = .fullScreen
        self.present(callMainPage, animated: true)
    }

    
    func showCallWaitingPage(invitee: UserInfo) {
        let callWaitingVC: CallWaitViewController = Bundle.main.loadNibNamed("CallWaitViewController", owner: self, options: nil)?.first as! CallWaitViewController
        callWaitingVC.modalPresentationStyle = .fullScreen
        callWaitingVC.isInviter = true
        callWaitingVC.invitee = invitee
        callWaitingVC.delegate = self
        self.present(callWaitingVC, animated: true)
    }
    
    func showReceiveCallWaitingPage(inviter: UserInfo, callID: String) {
        let callWaitingVC: CallWaitViewController = Bundle.main.loadNibNamed("CallWaitViewController", owner: self, options: nil)?.first as! CallWaitViewController
        callWaitingVC.modalPresentationStyle = .fullScreen
        callWaitingVC.isInviter = false
        callWaitingVC.inviter = inviter
        self.present(callWaitingVC, animated: true)
    }

}

extension ViewController: ZIMEventHandler, CallWaitViewControllerDelegate, CallAcceptTipViewDelegate {
    func zim(_ zim: ZIM, callInvitationReceived info: ZIMCallInvitationReceivedInfo, callID: String) {
        // receive call
        guard let inviter = ZegoCallDataManager.shared.currentCallData?.inviter else { return }
        let dialog: ZegoCallInvitationDialog = ZegoCallInvitationDialog.show(inviter, callID: callID, type: ZegoCallDataManager.shared.currentCallData?.type ?? .voice)
        dialog.delegate = self
    }
    
    func zim(_ zim: ZIM, callInvitationAccepted info: ZIMCallInvitationAcceptedInfo, callID: String) {
        // accept call
    }
    
    func zim(_ zim: ZIM, callInvitationRejected info: ZIMCallInvitationRejectedInfo, callID: String) {
        //receive reject call
        self.view.makeToast("call is rejected:\(info.extendedData)", duration: 2.0, position: .center)
    }
    
    func zim(_ zim: ZIM, callInvitationCancelled info: ZIMCallInvitationCancelledInfo, callID: String) {
        //receive cancel call
        ZegoCallInvitationDialog.hide()
    }
    
    func zim(_ zim: ZIM, callInvitationTimeout callID: String) {
        ZegoCallInvitationDialog.hide()
    }
    
    func zim(_ zim: ZIM, callInviteesAnsweredTimeout invitees: [String], callID: String) {
        ZegoCallInvitationDialog.hide()
    }
    
    func startShowCallPage(_ remoteUser: UserInfo) {
        showCallPage(remoteUser)
    }
    
    func onAcceptButtonClick(_ remoteUser: UserInfo) {
        showCallPage(remoteUser)
    }
    
    func showCallPage(_ remoteUser: UserInfo) {
        let callMainPage: CallingViewController = Bundle.main.loadNibNamed("CallingViewController", owner: self, options: nil)?.first as! CallingViewController
        callMainPage.modalPresentationStyle = .fullScreen
        callMainPage.remoteUser = remoteUser
        self.present(callMainPage, animated: false)
    }
}

