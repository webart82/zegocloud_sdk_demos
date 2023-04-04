//
//  CallingViewController.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import UIKit
import ZegoExpressEngine
import ZIM

enum CallButtonType: Int {
    case hangUpButton
    case toggleCameraButton
    case toggleMicrophoneButton
    case switchCameraButton
    case swtichAudioOutputButton
}

class CallingViewController: UIViewController {
    
    @IBOutlet weak var largetViewContainer: UIView! {
        didSet {
            largetViewContainer.backgroundColor = UIColor.colorWithHexString("#4A4B4D")
        }
    }
    @IBOutlet weak var largetVideoView: UIView!
    @IBOutlet weak var smallViewContainer: UIView! {
        didSet {
            smallViewContainer.backgroundColor = UIColor.colorWithHexString("#333437")
        }
    }
    @IBOutlet weak var smallVideoView: UIView!
    @IBOutlet weak var bottomBar: UIView! {
        didSet {
            bottomBar.backgroundColor = UIColor.colorWithHexString("#222222", alpha: 0.9)
        }
    }
    var remoteUser: UserInfo?
    var localUser: UserInfo? {
        get {
            return ZegoSDKManager.shared.localUser
        }
    }
    var buttonList: [CallButtonType] {
        get {
            if type == .voice {
                return [.toggleMicrophoneButton, .hangUpButton, .swtichAudioOutputButton]
            } else {
                return [.toggleMicrophoneButton, .toggleCameraButton,.hangUpButton, .swtichAudioOutputButton, .switchCameraButton]
            }
        }
    }
    var type: CallType {
        get {
            return ZegoCallStateManager.shared.currentCallData?.type ?? .voice
        }
    }
    
    private var margin: CGFloat {
        get {
            if type == .voice {
                return 55.5
            } else {
                return 21.5
            }
        }
    }
    
    private var itemSpace: CGFloat {
        get {
            if type == .voice {
                return (ScreenWidth - 111 - 180) / 2
            } else {
                return (ScreenWidth - 43 - 300) / 4
            }
         }
    }
    
    let itemSize: CGSize = CGSize.init(width: 60, height: 60)
    
    var isSpeaker: Bool = true
    var isFrontFacingCamera: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ZegoSDKManager.shared.addEventHandler(self)
        ZegoSDKManager.shared.addZIMEventHandler(self)
        setDeviceStatus()
        setUpBottomBar()
        showLocalPreview()
    }
    
    func setDeviceStatus() {
        ZegoSDKManager.shared.turnMicrophoneOn(true)
        if type == .video {
            ZegoSDKManager.shared.turnCameraOn(true)
        } else {
            ZegoSDKManager.shared.turnCameraOn(false)
        }
        ZegoSDKManager.shared.enableSpeaker(enable: isSpeaker)
        ZegoSDKManager.shared.useFrontFacingCamera(isFrontFacing: isFrontFacingCamera)
    }
    
    func setUpBottomBar() {
        var index = 0
        var lastView: UIView?
        for type in buttonList {
            let button: UIButton = UIButton(type: .custom)
            button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
            if index == 0 {
                button.frame = CGRect.init(x: self.margin, y: (70 - itemSize.height) * 0.5, width: itemSize.width, height: itemSize.width)
            } else {
                if let lastView = lastView {
                    button.frame = CGRect.init(x: lastView.frame.maxX + itemSpace, y: lastView.frame.minY, width: itemSize.width, height: itemSize.height)
                }
            }
            lastView = button
            index = index + 1
            switch type {
            case .hangUpButton:
                button.tag = 100
                button.setImage(UIImage(named: "call_hand_up_icon"), for: .normal)
            case .toggleCameraButton:
                button.tag = 101
                button.setImage(UIImage(named: "icon_camera_normal"), for: .normal)
                button.setImage(UIImage(named: "icon_camera_off"), for: .selected)
                
            case .toggleMicrophoneButton:
                button.tag = 102
                button.setImage(UIImage(named: "icon_mic_normal"), for: .normal)
                button.setImage(UIImage(named: "icon_mic_off"), for: .selected)
            case .switchCameraButton:
                button.tag = 103
                button.setImage(UIImage(named: "icon_camera_overturn"), for: .normal)
            case .swtichAudioOutputButton:
                button.tag = 104
                button.setImage(UIImage(named: "icon_speaker_normal"), for: .normal)
                button.setImage(UIImage(named: "icon_speaker_off"), for: .selected)
            }
            bottomBar.addSubview(button)
        }
    }
    
    @objc func buttonClick(_ sender: UIButton) {
        switch sender.tag {
        case 100:
            ZegoCallStateManager.shared.clearCallData()
            ZegoSDKManager.shared.leaveRoom()
            self.dismiss(animated: true)
        case 101:
            sender.isSelected = !sender.isSelected
            ZegoSDKManager.shared.turnCameraOn(!ZegoSDKManager.shared.isCameraOn(localUser?.userID ?? ""))
        case 102:
            sender.isSelected = !sender.isSelected
            ZegoSDKManager.shared.turnMicrophoneOn(!ZegoSDKManager.shared.isMicrophoneOn(localUser?.userID ?? ""))
        case 103:
            isFrontFacingCamera = !isFrontFacingCamera
            ZegoSDKManager.shared.useFrontFacingCamera(isFrontFacing: isFrontFacingCamera)
        case 104:
            sender.isSelected = !sender.isSelected
            isSpeaker = !isSpeaker
            ZegoSDKManager.shared.enableSpeaker(enable: isSpeaker)
        default:
            break
        }
    }
    
    
    func showLocalPreview() {
        if type == .video {
            ZegoSDKManager.shared.setLocalVideoView(renderView: smallVideoView)
        }
        ZegoSDKManager.shared.startPublishingStream()
    }

}

extension CallingViewController: ZegoEventHandler, ZIMEventHandler {
    
    func onRemoteCameraStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        if state != .open && type == .video {
            self.view.makeToast("remote user camera close", duration: 2.0, position: .center)
        }
    }
    
    func onRemoteMicStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        if state != .open {
            self.view.makeToast("remote user microphone close", duration: 2.0, position: .center)
        }
    }
    
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        if updateType == .delete {
            for user in userList {
                if user.userID == remoteUser?.userID {
                    ZegoCallStateManager.shared.clearCallData()
                    ZegoSDKManager.shared.leaveRoom()
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        for stream in streamList {
            if updateType == .add {
                if type == .video {
                    let canvas = ZegoCanvas(view: largetVideoView)
                    canvas.viewMode = .aspectFill
                    ZegoSDKManager.shared.playingStream(stream.streamID, canvas: canvas)
                } else {
                    ZegoSDKManager.shared.playingStream(stream.streamID, canvas: nil)
                }
            } else {
                ZegoSDKManager.shared.stopPlayingStream(stream.streamID)
            }
        }
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
