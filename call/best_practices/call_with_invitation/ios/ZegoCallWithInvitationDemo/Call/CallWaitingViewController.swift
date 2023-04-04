//
//  ZegoUIKitPrebuiltCallWaitingVC.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/11.
//

import UIKit
import ZIM

protocol CallWaitingViewControllerDelegate: AnyObject {
    func startShowCallPage(_ remoteUser: UserInfo)
}

class CallWaitingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ZegoSDKManager.shared.addZIMEventHandler(self)
    }
    
    @IBOutlet weak var backgroundImage: UIImageView! {
        didSet {
            backgroundImage.image = UIImage(named: "call_waiting_bg")
        }
    }
    
    @IBOutlet weak var videoPreviewView: UIView! {
        didSet {
            ZegoSDKManager.shared.setLocalVideoView(renderView: videoPreviewView)
        }
    }
    
    @IBOutlet weak var headLabel: UILabel! {
        didSet {
            headLabel.layer.masksToBounds = true
            headLabel.layer.cornerRadius = 50
            if !self.isInviter {
                self.setHeadUserName(invitee?.userName)
            }
        }
    }
    
    @IBOutlet weak var userNameLabel: UILabel! {
        didSet {
            userNameLabel.text = invitee?.userName
        }
    }
    @IBOutlet weak var callStatusLabel: UILabel!
    
    @IBOutlet weak var declineView: UIView! {
        didSet {
            declineView.isHidden = self.isInviter
        }
    }
    @IBOutlet weak var acceptView: UIView! {
        didSet {
            acceptView.isHidden = self.isInviter
        }
    }
    
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var declineButtonLabel: UILabel!
    @IBOutlet weak var cancelInviationButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton! {
        didSet {
            if ZegoCallStateManager.shared.currentCallData?.type == .video {
                acceptButton.setImage(UIImage(named: "call_video_icon"), for: .normal)
            } else {
                acceptButton.setImage(UIImage(named: "call_accept_icon"), for: .normal)
            }
        }
    }
    @IBOutlet weak var acceptButtonLabel: UILabel!
    @IBOutlet weak var switchFacingCameraButton: UIButton!
    
    var invitee: UserInfo? {
        didSet {
            if isInviter {
                self.setHeadUserName(invitee?.userName)
                self.userNameLabel.text = invitee?.userName
            }
        }
    }
    var inviter: UserInfo? {
        didSet {
            if !self.isInviter {
                self.setHeadUserName(inviter?.userName)
                self.userNameLabel.text = inviter?.userName
            }
        }
    }
        
    
    var isInviter: Bool = false {
        didSet {
            if isInviter {
                self.cancelInviationButton.isHidden = false
                self.acceptView.isHidden = true
                self.declineView.isHidden = true
            } else {
                self.cancelInviationButton.isHidden = true
                self.acceptView.isHidden = false
                self.declineView.isHidden = false
            }
            
        }
    }
    
    var showDeclineButton: Bool = true {
        didSet {
            if showDeclineButton == false {
                self.declineView.isHidden = true
                let acceptRect: CGRect = self.acceptView.frame
                let x: CGFloat = (self.view.frame.width - acceptRect.width)/2
                self.trailingConstraint.constant = x
            }
        }
    }
    
    weak var delegate: CallWaitingViewControllerDelegate?
    
    
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    

    
    private func setHeadUserName(_ userName: String?) {
        guard let userName = userName else { return }
        if userName.count > 0 {
            let firstStr: String = String(userName[userName.startIndex])
            self.headLabel.text = firstStr
        }
    }
    
    @IBAction func declineButtonClick(_ sender: Any) {
        guard let callID = ZegoCallStateManager.shared.currentCallData?.callID else { return }
        ZegoSDKManager.shared.rejectCallInvitation(with: callID, data: nil, callback: nil)
        ZegoSDKManager.shared.leaveRoom()
        self.dismiss(animated: true)
    }
    
    @IBAction func handupButtonClick(_ sender: Any) {
        guard let inviteeUserID = invitee?.userID,
              let callID = ZegoCallStateManager.shared.currentCallData?.callID
        else { return }
        ZegoSDKManager.shared.cancelCallInvitation(with: [inviteeUserID], invitationID: callID, data: nil, callback: nil)
        ZegoSDKManager.shared.leaveRoom()
        self.dismiss(animated: true)
    }
    
    @IBAction func acceptButtonClick(_ sender: Any) {
        guard let callID = ZegoCallStateManager.shared.currentCallData?.callID else { return }
        ZegoSDKManager.shared.acceptCallInvitation(with: callID, data: nil) { errorCode, errorMessage in
            if errorCode == 0 {
                //accept sucess
                if let localUserID = ZegoSDKManager.shared.localUser?.userID,
                   let locaUserName = ZegoSDKManager.shared.localUser?.userName
                {
                    ZegoSDKManager.shared.joinRoom(userID: localUserID, userName: locaUserName, roomID: callID) { errorCode, errorMessage in
                        if errorCode == 0 {
                            //start call
                            guard let remoteUser = ZegoCallStateManager.shared.currentCallData?.inviter else { return }
                            ZegoSDKManager.shared.startPublishingStream()
                            self.showCallPage(remoteUser)
                        } else {
                            self.view.makeToast("express joim room failed:\(errorCode)", duration: 2.0, position: .center)
                        }
                    }
                }
               
            }
        }
    }
    
    func showCallPage(_ remoteUser: UserInfo) {
        DispatchQueue.main.async {
            self.dismiss(animated: false)
            self.delegate?.startShowCallPage(remoteUser)
        }
    }

}

extension CallWaitingViewController: ZIMEventHandler {
    
    func zim(_ zim: ZIM, callInvitationAccepted info: ZIMCallInvitationAcceptedInfo, callID: String) {
        guard let remoteUser = ZegoCallStateManager.shared.currentCallData?.invitee else { return }
        ZegoSDKManager.shared.startPublishingStream()
        showCallPage(remoteUser)
    }
    
    func zim(_ zim: ZIM, callInvitationRejected info: ZIMCallInvitationRejectedInfo, callID: String) {
        let callData: [String: AnyObject]? = info.extendedData.convertStringToDictionary()
        if let callData = callData, callData["reason"] as? String ?? "" == "busy" {
            self.view.makeToast("invitee is busy", duration: 2.0, position: .center)
        }
        ZegoSDKManager.shared.leaveRoom()
        self.dismiss(animated: true)
    }
    
    func zim(_ zim: ZIM, callInvitationCancelled info: ZIMCallInvitationCancelledInfo, callID: String) {
        self.dismiss(animated: true)
    }
    
    func zim(_ zim: ZIM, callInvitationTimeout callID: String) {
        ZegoSDKManager.shared.leaveRoom()
        self.dismiss(animated: true)
    }
    
    func zim(_ zim: ZIM, callInviteesAnsweredTimeout invitees: [String], callID: String) {
        ZegoSDKManager.shared.leaveRoom()
        self.dismiss(animated: true)
    }
    
    func zim(_ zim: ZIM, connectionStateChanged state: ZIMConnectionState, event: ZIMConnectionEvent, extendedData: [AnyHashable : Any]) {
        if state == .disconnected {
            self.view.makeToast("zim disconnected", duration: 2.0, position: .center)
        } else if state == .connecting {
            self.view.makeToast("zim connecting", duration: 2.0, position: .center)
        } else if state == .reconnecting {
            self.view.makeToast("zim reconnecting", duration: 2.0, position: .center)
        }
    }
    
}
