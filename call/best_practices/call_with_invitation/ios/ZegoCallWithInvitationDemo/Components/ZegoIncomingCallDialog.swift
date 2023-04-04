//
//  CallAcceptTipView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit

protocol CallAcceptTipViewDelegate: AnyObject {
    func onAcceptButtonClick(_ remoteUser: UserInfo)
}

class ZegoIncomingCallDialog: UIView {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    
    @IBOutlet weak var headLabel: UILabel! {
        didSet {
            headLabel.layer.masksToBounds = true
            headLabel.layer.cornerRadius = 21
            headLabel.textAlignment = .center
        }
    }
    
    weak var delegate: CallAcceptTipViewDelegate?
    
    private var type: CallType = .voice
    var inviter: UserInfo?
    var callID: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapClick: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(viewTap))
        self.addGestureRecognizer(tapClick)
    }
    
    static func show(_ inviter: UserInfo, callID: String, type: CallType) -> ZegoIncomingCallDialog {
        return showTipView(inviter, callID: callID, type: type)
    }
    
    private static func showTipView(_ inviter: UserInfo, callID: String, type: CallType) -> ZegoIncomingCallDialog {
        let tipView: ZegoIncomingCallDialog = Bundle.main.loadNibNamed("ZegoCallInvitationDialog", owner: self, options: nil)?.first as! ZegoIncomingCallDialog
        let y = KeyWindow().safeAreaInsets.top
        tipView.frame = CGRect.init(x: 8, y: y + 8, width: UIScreen.main.bounds.size.width - 16, height: 80)
        tipView.layer.masksToBounds = true
        tipView.layer.cornerRadius = 8
        tipView.type = type
        tipView.callID = callID
        tipView.inviter = inviter
        tipView.setHeadUserName(inviter.userName)
        tipView.userNameLabel.text = inviter.userName
        switch type {
        case .voice:
            tipView.messageLabel.text = "voice call"
            tipView.acceptButton.setImage(UIImage(named: "call_accept_icon"), for: .normal)
        case .video:
            tipView.messageLabel.text =  "video call"
            tipView.acceptButton.setImage(UIImage(named: "call_video_icon"), for: .normal)
        }
        tipView.showTip()
        return tipView
    }
    
    private func setHeadUserName(_ userName: String?) {
        guard let userName = userName else { return }
        if userName.count > 0 {
            let firstStr: String = String(userName[userName.startIndex])
            self.headLabel.text = firstStr
        }
    }
        
    public static func hide() {
        DispatchQueue.main.async {
            for subview in KeyWindow().subviews {
                if subview is ZegoIncomingCallDialog {
                    let view: ZegoIncomingCallDialog = subview as! ZegoIncomingCallDialog
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    private func showTip()  {
        KeyWindow().addSubview(self)
    }

    
    @objc func viewTap() {
        guard let inviter = inviter else { return }
        showCallWaitingPage(inviter: inviter)
        ZegoIncomingCallDialog.hide()
    }
    
    func showCallWaitingPage(inviter: UserInfo) {
        let callWaitingVC: CallWaitingViewController = Bundle.main.loadNibNamed("CallWaitViewController", owner: self, options: nil)?.first as! CallWaitingViewController
        callWaitingVC.modalPresentationStyle = .fullScreen
        callWaitingVC.isInviter = false
        callWaitingVC.inviter = inviter
        callWaitingVC.delegate = currentViewController() as? any CallWaitingViewControllerDelegate
        currentViewController()?.present(callWaitingVC, animated: true)
    }
    
    @IBAction func acceptButtonClick(_ sender: UIButton) {
        guard let inviter = inviter,
        let callID = callID
        else { return }
        ZegoSDKManager.shared.acceptCallInvitation(with: callID, data: nil) { errorCode, errorMessage in
            if errorCode == 0 {
                ZegoSDKManager.shared.joinRoom(userID: ZegoSDKManager.shared.localUser?.userID ?? "", userName: ZegoSDKManager.shared.localUser?.userName ?? "", roomID: callID) { errorCode, errorMessage in
                    self.delegate?.onAcceptButtonClick(inviter)
                    ZegoIncomingCallDialog.hide()
                }
            } else {
                self.makeToast("accept call failed:\(errorCode)", duration: 2.0, position: .center)
            }
        }
    }
    
    @IBAction func rejectButtonClick(_ sender: UIButton) {
        guard let callID = callID else { return }
        ZegoSDKManager.shared.rejectCallInvitation(with: callID, data: nil, callback: nil)
        ZegoIncomingCallDialog.hide()
    }
    
    func showCallMainPage(_ remoteUser: UserInfo) {
        let callMainPage: CallingViewController = Bundle.main.loadNibNamed("CallingViewController", owner: self, options: nil)?.first as! CallingViewController
        callMainPage.modalPresentationStyle = .fullScreen
        callMainPage.remoteUser = remoteUser
        currentViewController()?.present(callMainPage, animated: true)
    }
    
}
