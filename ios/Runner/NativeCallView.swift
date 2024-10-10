//
//  NativeCallView.swift
//  Runner
//
//  Created by YUN WAH LEE on 28/2/24.
//

import Foundation
import Flutter
import AgoraRtcKit
import AVKit
import AVFoundation
import SDWebImage

public class NativeCallView: NSObject, FlutterPlatformView {
    var agoraCallManager: AgoraCallManager
    var uid : UInt
    var avatarUrl: String = ""
    var nickname: String = ""
    let customView = UIView()

    public init(agoraCallManager manager: AgoraCallManager, withargs args: Dictionary<String, Any>, withId id: Int64){
        agoraCallManager = manager
        uid = args["uid"] as? UInt ?? 0
        avatarUrl = args["remoteProfile"] as? String ?? ""
        nickname = args["nickname"] as? String ?? ""
        super.init()
    }
    
    public func view() -> UIView {
        if(uid == agoraCallManager.localUserId){
            agoraCallManager.localVideo.avatarUrl = avatarUrl
            agoraCallManager.localVideo.uid = uid
            agoraCallManager.localVideo.nickname = nickname

            customView.layer.addSublayer(agoraCallManager.fullLocalVideo.videoView.displayLayer)
            customView.layer.addSublayer(agoraCallManager.localVideo.videoView.displayLayer)
            
            agoraCallManager.fullLocalVideo.initAvatarView()
        }else {
            agoraCallManager.remoteVideo.avatarUrl = avatarUrl
            agoraCallManager.remoteVideo.uid = uid
            agoraCallManager.remoteVideo.nickname = nickname

            customView.layer.addSublayer(agoraCallManager.fullRemoteVideo.videoView.displayLayer)
            customView.layer.addSublayer(agoraCallManager.remoteVideo.videoView.displayLayer)
            
            agoraCallManager.fullRemoteVideo.initAvatarView()
        }
        customView.backgroundColor = .black
        return customView
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


class SampleBufferDisplayView: UIView {
    @IBOutlet weak var videoView: AgoraSampleBufferRender!
    
    let bgColors:[[String]] = [
        ["ffFE9D7F", "ffF44545"],
        ["ffFFAE7B", "ffF07F38"],
        ["ffFBC87B", "ffFFA800"],
        ["ffAAF490", "ff52D05E"],
        ["ff85A3F9", "ff5D60F6"],
        ["ff7EC2F4", "ff3B90E1"],
        ["ff6BF0F9", "ff1EAECD"],
        ["ffD784FC", "ffB35AD1"],
    ]
    
    let avatarSize = 80.0
    let winWidth = 120.0
    let winHeight = 200.0
    
    var uid: UInt = 0
    var nickname = ""
    var avatarUrl = ""
    var hasStream: Bool = false
    
    private var placeholder: UIView?
    var freezeView: UIView? {
        get {
            if self.placeholder == nil { placeholder = initAvatarView() }
            return self.placeholder
        }
        set {
            self.placeholder = newValue
        }
    }
    
    lazy var shortNameLbl: UIView = {
        let colorIndex = Int(uid) % 8
        
        let gradientView = GradientView(frame: CGRect(x: (winWidth - avatarSize) / 2, y: (winHeight - avatarSize) / 2, width: avatarSize, height: avatarSize), colors: bgColors[colorIndex].map{ UIColor(hexString: $0).cgColor })
        gradientView.clipsToBounds = true
        gradientView.layer.cornerRadius = avatarSize / 2

        return gradientView
    }()
    
    func initAvatarView() -> UIView{
        let freezeView = UIView(frame: CGRect(x: 0, y: 0, width: winWidth, height: winHeight))
        freezeView.backgroundColor = .black
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let callMgr = appDelegate.agoraCallManager {
            let avatarUrl = self.avatarUrl.isEmpty ? callMgr.avatarUrl : self.avatarUrl
            
            if let avatarURL = URL(string: avatarUrl) {
                let imageView = UIImageView(frame: CGRect(x: (winWidth - avatarSize) / 2, y: (winHeight - avatarSize) / 2, width: avatarSize, height: avatarSize))
                imageView.contentMode = .scaleAspectFill
                imageView.layer.cornerRadius = avatarSize / 2
                imageView.clipsToBounds = true
                freezeView.addSubview(imageView)
                
                imageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
                imageView.sd_imageIndicator?.startAnimatingIndicator()
                imageView.sd_setImage(with: avatarURL)
            }else{
                var remoteUserId = self.uid == 0 ? callMgr.remoteUserId : self.uid
                let username = self.nickname.isEmpty ? callMgr.nickname : self.nickname
                
                if(remoteUserId == 0){
                    //只限单聊，群聊后需要修改逻辑
                    remoteUserId = callMgr.allUsers.filter { $0 != callMgr.localUserId }.first ?? 0
                }
                
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: freezeView.frame.size.width, height: freezeView.frame.size.height))
                label.textAlignment = .center
                label.textColor = UIColor.white
                label.font = UIFont.boldSystemFont(ofSize: 24.0)
                label.text = self.getShortName(username: username)
                
                let colorIndex = Int(remoteUserId) % 8
                
                let gradientView = GradientView(frame: CGRect(x: (winWidth - avatarSize) / 2, y: (winHeight - avatarSize) / 2, width: avatarSize, height: avatarSize), colors: bgColors[colorIndex].map{ UIColor(hexString: $0).cgColor })
                gradientView.clipsToBounds = true
                gradientView.layer.cornerRadius = avatarSize / 2
                
                freezeView.addSubview(gradientView)
                freezeView.addSubview(label)
            }
        }
         
        return freezeView
    }
    
    func getShortName(username: String) -> String{
        var name = "-"
        if(!username.isEmpty){
            if(username.firstCharacterIsEmoji){
                name = String(username.first!)
            }else{
                let parts = username.split(separator: " ")
                if(parts.count > 1){
                    name = "\(String(parts[0].first!))\(String(parts[1].first!))".uppercased()
                }else{
                    name = String(username.first!).uppercased()
                }
            }
        }
        
        return name
    }
    
    func resetToDefault(){
        self.uid = 0
        self.avatarUrl = ""
        self.nickname = ""
        self.hasStream = false
        self.placeholder = nil
        
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
