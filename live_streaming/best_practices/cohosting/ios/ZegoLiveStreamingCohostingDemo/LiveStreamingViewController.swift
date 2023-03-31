//
//  LiveStreamingViewController.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/31.
//

import UIKit
import ZegoExpressEngine
import Toast

class LiveStreamingViewController: UIViewController {

    @IBOutlet weak var mainStreamView: VideoView!
    @IBOutlet weak var preBackgroundView: UIView!
    @IBOutlet weak var startLiveButton: UIButton!
    
    @IBOutlet weak var liveContainerView: UIView!
    @IBOutlet weak var userNameConstraint: NSLayoutConstraint!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var memberButton: UIButton!
    @IBOutlet weak var flipButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var endCoHostButton: UIButton!
    @IBOutlet weak var coHostButton: UIButton!
    @IBOutlet weak var coHostWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    var expressService = ZegoSDKManager.shared.expressService
    
    var coHostVideoViews: [VideoView] = []
    
    var isMySelfHost: Bool = false
    var liveID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        expressService.delegate = self
        configUI()
    }
    
    func configUI() {
        liveContainerView.isHidden = isMySelfHost
        preBackgroundView.isHidden = !isMySelfHost
        if isMySelfHost {
            startPreviewIfHost()
            updateUserNameLabel(expressService.localUser?.name)
        } else {
            userNameLabel.isHidden = true
            coHostButton.isHidden = false
            flipButton.isHidden = true
            micButton.isHidden = true
            cameraButton.isHidden = true
            
            expressService.joinRoom(liveID, isHost: false)
        }
    }
    
    func updateUserNameLabel(_ name: String?) {
        userNameLabel.isHidden = false
        userNameLabel.text = name
        userNameConstraint.constant = userNameLabel.intrinsicContentSize.width + 20
    }
    
    func startPreviewIfHost() {
        preBackgroundView.isHidden = !isMySelfHost
        if isMySelfHost {
            expressService.startCameraPreview(mainStreamView.renderView)
        }
    }
    
    // MARK: - Actions
    @IBAction func startLive(_ sender: UIButton) {
        // join room and publish
        expressService.joinRoom(liveID, isHost: true)
        expressService.startPublishLocalVideo()
        
        // modify UI
        preBackgroundView.isHidden = true
        liveContainerView.isHidden = false
        
        mainStreamView.update(expressService.localUser?.id, expressService.localUser?.name)
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        func leaveRoom() {
            expressService.leaveRoom()
            dismiss(animated: true)
        }
        
        if !isMySelfHost {
            leaveRoom()
            return
        }
        let alert = UIAlertController(title: "Stop the Live", message: "Are you sure to stop the live?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let okAction = UIAlertAction(title: "Stop it", style: .default) { _ in
            leaveRoom()
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    @IBAction func switchCamera(_ sender: UIButton) {
        expressService.useFrontFacingCamera(!expressService.isUsingFrontCamera)
    }
    
    @IBAction func memberButtonAction(_ sender: UIButton) {
        
    }
    
    @IBAction func endCoHostAction(_ sender: UIButton) {
        
    }
    
    @IBAction func micAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        expressService.turnMicrophoneOn(!sender.isSelected)
    }
    
    @IBAction func cameraAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        expressService.turnCameraOn(!sender.isSelected)
    }
    
    
    @IBAction func coHostAction(_ sender: UIButton) {
        func clickButton() {
            sender.isSelected = !sender.isSelected
            coHostWidthConstraint.constant = sender.isSelected ? 210 : 165
        }
        
        clickButton()
        
        let operatorID = expressService.localUser?.id ?? ""
        guard let targetID = expressService.host?.id else {
            self.view.makeToast("Host is not in the room.", position: .center)
            clickButton()
            return
        }
        
        var command = CustomCommand(actionType: .acceptCoHostApply, operatorID: operatorID, targetID: targetID)
        if sender.isSelected {
            command.actionType = .cancelCoHostApply
        }
        expressService.SendInRoomCommand(command) { errorCode in
            if errorCode != 0 {
                self.view.makeToast("Send In Room Command Failed: \(errorCode)", position: .center)
                clickButton()
            }
        }
    }
}

extension LiveStreamingViewController: ExpressServiceDelegate {
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        if updateType == .add {
            for stream in streamList {
                addCoHost(stream)
            }
        } else {
            for stream in streamList {
                removeCoHost(stream)
            }
        }
    }
    
    func onInRoomCommandReceived(_ command: CustomCommand, from userID: String) {
        switch command.actionType {
        case .applyCoHost:
            onReceiveApplyCoHostRequest(command)
        case .acceptCoHostApply:
            onReceiveAcceptCoHostApply()
        default:
            break
        }
    }
}

// MARK: - CoHost
extension LiveStreamingViewController {
    
    func onReceiveApplyCoHostRequest(_ command: CustomCommand) {
        let alert = UIAlertController(title: "Co-Host Requesting", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Agree", style: .default) { _ in
            let operatorID = self.expressService.localUser?.id ?? ""
            let newCommand = CustomCommand(actionType: .acceptCoHostApply, operatorID: operatorID, targetID: command.operatorID)
            self.expressService.SendInRoomCommand(newCommand, callback: nil)
        }
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    func onReceiveAcceptCoHostApply() {
        let streamID = ""
        let userID = expressService.localUser?.id ?? ""
        let userName = expressService.localUser?.name ?? ""
        addCoHost(streamID, userID, userName, isMySelf: true)
    }
    
    func addCoHost(_ stream: ZegoStream) {
        addCoHost(stream.streamID, stream.user.userID, stream.user.userName)
    }
    
    func addCoHost(_ streamID: String, _ userID: String, _ userName: String, isMySelf: Bool = false) {
        let isHost = streamID.hasSuffix("_host")
        if isHost {
            expressService.startPlayRemoteAudioVideo(mainStreamView.renderView, streamID: streamID)
            updateUserNameLabel(userName)
            mainStreamView.update(userID, userName)
        }
        
        // add cohost
        else {
            
            if coHostVideoViews.count == 4 { return }
            
            let videoView = VideoView()
            videoView.update(userID, userName)
            coHostVideoViews.append(videoView)
            if isMySelf {
                expressService.startPublishLocalVideo()
                expressService.startCameraPreview(videoView.renderView)
            } else {
                expressService.startPlayRemoteAudioVideo(videoView.renderView, streamID: streamID)
            }
            updateCoHostConstraints()
        }
    }
    
    func removeCoHost(_ stream: ZegoStream) {
        expressService.stopPlayRemoteAudioVideo(stream.streamID)
        let isHost = stream.streamID.hasSuffix("_host")
        if isHost {
            
        } else {
            coHostVideoViews.forEach( { $0.removeFromSuperview() } )
            coHostVideoViews = coHostVideoViews.filter({ $0.userID != stream.user.userID })
            updateCoHostConstraints()
        }
    }
    
    func updateCoHostConstraints() {
        
        let bottomMargin = 85.0
        let margin = 5.0
        let w = 93.0
        let h = 124.0
        for (i, view) in coHostVideoViews.enumerated() {
            view.translatesAutoresizingMaskIntoConstraints = false
            liveContainerView.addSubview(view)
            view.layer.cornerRadius = 5.0
            view.layer.masksToBounds = true
            
            let constant: CGFloat = bottomMargin + Double(i) * (h+margin)
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: w),
                view.heightAnchor.constraint(equalToConstant: h),
                view.trailingAnchor.constraint(equalTo: liveContainerView.trailingAnchor, constant: -16),
                view.bottomAnchor.constraint(equalTo: liveContainerView.bottomAnchor, constant: -constant)
            ])
        }
    }
}
