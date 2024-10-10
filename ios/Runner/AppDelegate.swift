import UIKit
import Flutter
import SystemConfiguration
import UserNotifications
import flutter_local_notifications
import AudioToolbox
import PushKit
import CallKit
import Intents
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate{

    //let audioHelp = AudioHelp()
    var mainVC: FlutterViewController?

    var shareExtentToolsChannel: FlutterMethodChannel?
    
    var pushNotificationChannel : FlutterMethodChannel?
    
    var generalChannel : FlutterMethodChannel?
    
    var clipboardChannel : FlutterMethodChannel?

    var imageDict: NSArray?
    
    var voipToken: String?
    var rtcChannel : FlutterMethodChannel?
    var appInForeground: Bool = false
    var isEnableCallkit:Bool = true

    var isOpen : Bool = true
    private let channelIDKey = "channelIDKey"
    var channelIDList : [String] = []
    var channelIndex : Int = 0
    
    let callHelper = CallHelper()
    var providerDelegate: ProviderDelegate?
    var agoraCallManager: AgoraCallManager?
    
    var batteryMgr: BatteryMgr?
    
    // 用于缓存路径的，防止同一个剪切版的图片，多次存储
    var pasteboardDic:[Int:[[String]]] = [:]

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

        mainVC = controller

        shareExtentToolsChannel = FlutterMethodChannel.init(name: "jxim/share.extent", binaryMessenger: controller as! FlutterBinaryMessenger)
        pushNotificationChannel = FlutterMethodChannel.init(name: "jxim/notification", binaryMessenger: controller as! FlutterBinaryMessenger)
        rtcChannel = FlutterMethodChannel.init(name: "jxim/rtc", binaryMessenger: controller as! FlutterBinaryMessenger)
        generalChannel = FlutterMethodChannel.init(name: "jxim/general", binaryMessenger: controller as! FlutterBinaryMessenger)

        let batteryChannel : FlutterMethodChannel = FlutterMethodChannel.init(name: "jxim/battery", binaryMessenger: controller as! FlutterBinaryMessenger)
        batteryMgr = BatteryMgr(methodChannel: batteryChannel)

        generalChannel?.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if (call.method == "isBackgroundAudioPlaying") {
                self.isBackgroundAudioPlaying(result: result)
            }
        })
        
        clipboardChannel = FlutterMethodChannel(name: "jxim/clipboard", binaryMessenger: controller.binaryMessenger)

        shareExtentToolsChannel?.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if (call.method == "syncChatList") {
                self.syncChatList(call.arguments)
            }else if(call.method == "getShareFilePath"){
                self.getShareFilePath(result: result)
            }else if(call.method == "clearShare"){
                self.clearShareData(result: result)
            }else if(call.method == "clearChatList"){
                self.clearChatList()
            }
        })

        /// 不可用: 需要调研如何动态更改 加解密盐
        //NotificationService.encryptionKey = "HELLO"
        //NotificationService.setEncryptionKey(newValue: "HELLO")
        //print("App delegate: \(NotificationService.encryptionKey)")
        
        clipboardChannel?.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          
            if call.method == "getClipboardImages" {
                let pasteboard = UIPasteboard.general
                
                if(self.pasteboardDic[pasteboard.changeCount] != nil) {
                    result(self.pasteboardDic[pasteboard.changeCount])
                    return
                }
                
                DispatchQueue.global(qos: .default).async {
                    // 有新的照片就把原来的照片删除了，防止占用过多的硬盘
                    self.deleteFilesInTemporaryDirectory(matchingPrefix: "jxim_image_clipboard_")
                    self.pasteboardDic = [:]
                    
                    var images: [UIImage] = []
                    // 遍历剪贴板的所有 items，查找包含图片的数据
                    for item in pasteboard.items {
                        for (type, value) in item {
                            
                            // 检查是否为标准图片类型（PNG 或 JPEG）
                            if type.starts(with: "public.image") || type.starts(with: "public.png") || type.starts(with: "public.jpeg") {
                                if let image = value as? UIImage {
                                    // print("从其他应用复制的")
                                    // 检查是否为标准图片类型（PNG 或 JPEG）
                                    images.append(image)
                                } else if let imageData = value as? Data,
                                          let image = UIImage(data: imageData) {
                                    // 如果剪贴板数据是 Data 类型，也尝试转换为 UIImage
                                    images.append(image)
                                }
                                break
                            } 
                            
                            // 这里是从相册复制，处理多张图片的，先暂时不做，问题太多了
//                            else if type == "com.apple.mobileslideshow.asset.localidentifier" || type == "public.data" {
//                                // 处理 OS_dispatch_data 类型（例如从相册中复制的图片）
//
//                                if let dispatchData = value as? Data {
//                                    // 尝试将 Data 转换为 UIImage
//                                    if let image = UIImage(data: dispatchData) {
//                                        images.append(image)
//                                    }
//                                }
//                            }
                            
                        }
                    }
                        
                    
                    // 如果没有找到图片，返回错误
                    var imageFiles:[[String]] = []
                    for i in 0..<images.count {
                        let timestampMillis = Int(Date().timeIntervalSince1970 * 1000)
                        var imageType = "png"
                        if let _imageType = self.imageFormat(from: images[i].pngData()) {
                            imageType = _imageType.lowercased()
                        }
                        let fileName = "jxim_image_clipboard_\(timestampMillis).\(imageType)"
                        if let path = self.saveUIImageToFileSystem(image: images[i], filename: fileName) {
                            // 这里保存一个数组 [图片路径，图片宽度，图片高度] 都是字符串
                            imageFiles.append([path,"\(Int(images[i].size.width))","\(Int(images[i].size.height))"])
                        }
                    }
                    
                    self.pasteboardDic[pasteboard.changeCount] = imageFiles
                    result(imageFiles)
                }
            }
            
        })

        pushNotificationChannel?.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if (call.method == "isOpen") {
                if let args = call.arguments as? Dictionary<String, Any> {
                    if let isOpenString = args["isOpen"] as? String {
                        if let isOpen = Bool(isOpenString) {
                            self.isOpen = isOpen
                            self.appInForeground = true
                            result(isOpen)
                            return
                        } else {
                            print("Invalid value for 'isOpen'")
                        }
                    }else{
                        print("Invalid value for 'isOpen'")
                    }
                } else {
                    print("Invalid value for 'isOpen'")
                }
            }else if(call.method == "getID"){
                let registrationId : String = JPUSHService.registrationID()

                result(registrationId)
            }else if(call.method == "getVoipToken"){
                result(self.voipToken)
            }else if(call.method == "getAppState"){
                let isInPipMode = self.agoraCallManager?.pipController?.pipController.isPictureInPictureActive ?? false
                result(self.appInForeground || isInPipMode)
            }else if(call.method == "getLaunchType"){
                let type = self.getLaunchType()
                result(type)
            }else if(call.method == "updateBadgeNumber"){
                guard let num = call.arguments as? Int else {
                    return
                }
                let k = num == 0 ? 0 : num - 1
                JPUSHService.setBadge(k)
                NSLog("data Badge ----- ::\(k)")
                UIApplication.shared.applicationIconBadgeNumber = num
            }
          })

        rtcChannel?.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch(call.method) {
            case "incomingCallKit":
                do {
                    let extraData = try JSONSerialization.data(withJSONObject: call.arguments as? Dictionary<String, Any?> ?? [])
                    let extraObj = try JSONDecoder().decode(Extra.self, from: extraData)
                    self.providerDelegate?.reportIncomingCall(uuid: UUID(), payload: extraObj)
                } catch {
                    print("Error on incomingCallKit : \(error)")
                }
                break
                case "setupAgoraEngine" :
                    do {
                        if let args = call.arguments as? Dictionary<String, Any> {
                            self.agoraCallManager?.setupEngine(appId: args["appID"] as! String, isInviter: args["isInviter"] as! Bool, isVoiceCall: args["isVoiceCall"] as! Bool, fps: args["fps"] as! Int, width: args["width"] as! Int, height: args["height"] as! Int)


                            if let uid = args["uid"] as? Int,
                                let nickname = args["nickname"] as? String {
                                self.agoraCallManager?.setPIPView(uid: UInt(uid), avatarUrl: args["avatarUrl"] as? String ?? "", nickname: nickname)
                            }

                            self.agoraCallManager?.initPIPController(bufferRender: nil)
                        }
                    }
                break;
            case "joinChannel":
                if let args = call.arguments as? Dictionary<String, Any> {
                    let encryptKey = args["encryptKey"] as? String
                    self.agoraCallManager?.joinBroadcastStream(args["channelId"] as! String,token: args["token"] as? String, uid: args["uid"] as! UInt, encryptKey: encryptKey)
                }
                break
            case "muteLocalVideoStream":
                if let args = call.arguments as? Dictionary<String, Any> {
                    NSLog("data ::\(args["selfCameraOn"] as! Bool)")
                    self.agoraCallManager?.toggleLocalCam(isCameraOn: args["selfCameraOn"] as! Bool)
                }
                break
            case "toggleMic":
                if let args = call.arguments as? Dictionary<String, Any> {
                    NSLog("data ::\(args["isMute"] as! Bool)")
                    self.agoraCallManager?.toggleMic(isMute: args["isMute"] as! Bool)
                }
                break
            case "toggleSpeaker":
                if let args = call.arguments as? Dictionary<String, Any> {
                    NSLog("data ::\(args["isSpeaker"] as! Bool)")
                    self.agoraCallManager?.toggleSpeaker(isSpeaker:args["isSpeaker"] as! Bool)
                }
                break
            case "toggleFloat":
                if let args = call.arguments as? Dictionary<String, Any> {
                    self.agoraCallManager?.toggleFloating(isMe: args["isMe"] as? Bool ?? true)
                    self.agoraCallManager?.floatIsLocal = args["isMe"] as? Bool ?? true
                }
                break
            case "switchCamera":
                self.agoraCallManager?.switchCamera()
                break
            case "releaseEngine":
                var toResetAudio: Bool = true
                if let args = call.arguments as? Dictionary<String, Any>{
                    toResetAudio = args["resetAudioSession"] as? Bool ?? true
                }

                self.agoraCallManager?.releaseEngine(resetAudio: toResetAudio)
                break
            case "reportOutgoingCall":
                do {
                    let extraData = try JSONSerialization.data(withJSONObject: call.arguments as? Dictionary<String, Any?> ?? [])
                    let extraObj = try JSONDecoder().decode(Extra.self, from: extraData)

                    self.providerDelegate?.reportOutgoingCall(payload: extraObj)
                } catch {
                    print("Error on reportOutgoingCall : \(error)")
                }
                break
            case "outgoingCallConnected":
                do {
                    let extraData = try JSONSerialization.data(withJSONObject: call.arguments as? Dictionary<String, Any?> ?? [])
                    let extraObj = try JSONDecoder().decode(Extra.self, from: extraData)

                    self.providerDelegate?.outgoingCallConnected(payload: extraObj)
                } catch {
                    print("Error on outgoingCallConnected : \(error)")
                }
                break
            case "cancelCallKitCall":
                do {
                    let extraData = try JSONSerialization.data(withJSONObject: call.arguments as? Dictionary<String, Any?> ?? [])
                    let extraObj = try JSONDecoder().decode(Extra.self, from: extraData)

                    self.providerDelegate?.cancelCallKit(payload: extraObj)
                } catch {
                    print("Error on cancel call kit : \(error)")
                }
                break
            case "acceptCallKit":
                do {
                    let extraData = try JSONSerialization.data(withJSONObject: call.arguments as? Dictionary<String, Any?> ?? [])
                    let extraObj = try JSONDecoder().decode(Extra.self, from: extraData)
                    self.providerDelegate?.acceptCallKit(payload: extraObj)
                } catch {
                    print("Error on accept call kit : \(error)")
                }
                break;
            case "addChannelID":
                NSLog("channelIDList before Update ::\(self.channelIDList)")
                NSLog("channelIDList before Index: \(self.channelIndex)")

                if let result = call.arguments as? [String] {
                    for id in result {
                        if self.channelIDList.count < 20 {
                            self.channelIDList.append(id)
                        } else {
                            NSLog("channelIDList Index: \(self.channelIndex % 20)")
                            self.channelIDList[self.channelIndex % 20] = id
                        }
                        self.channelIndex += 1
                        NSLog("channelIDList after Index: \(self.channelIndex)")
                        self.saveChannelIndex(self.channelIndex)
                    }
                } else {
                    print("Result is nil") // Handle the case where result is nil
                }

                NSLog("channelIDList After Update ::\(self.channelIDList)")
                self.saveChannelIDList(self.channelIDList)
            case "toggleProximity":
                if let args = call.arguments as? Dictionary<String, Any> {
                    UIDevice.current.isProximityMonitoringEnabled = args["enable"] as? Bool ?? false
                }

                break;
            case "callViewDismiss":
                if let args = call.arguments as? Dictionary<String, Any> {
                    self.agoraCallManager?.onExitCallView(isExit: args["isExit"] as? Bool ?? false)
                }
                break
            case "isInForeground":
                result(self.appInForeground)
                break
            case "bluetooth":
                self.bluetoothPlay()
                break
            case "playRingSound":
                self.agoraCallManager?.soundMgr.playRingSound(volume: 1.0)
                result(true)
                break
            case "stopRingSound":
                self.agoraCallManager?.soundMgr.stopRingSound()
                result(true)
                break
            case "playDialingSound":
                /*if(!(self.agoraCallManager?.isVoiceCall ?? true)){
                    self.agoraCallManager?.soundMgr.setAudioConfig()
                }*/
                self.agoraCallManager?.soundMgr.playDialingSound(volume: 1.0)
                break
            case "playPickedSound":
                self.agoraCallManager?.playPickedSound()
                result(true)
                break
            case "playEndSound":
                self.agoraCallManager?.playEndSound()
                result(true)
                break
            case "playEnd2Sound":
                self.agoraCallManager?.playEnd2Sound()
                result(true)
                break
            case "playBusySound":
                self.agoraCallManager?.playBusySound()
                result(true)
                break;
            case "enableAgoraAudio":
                self.agoraCallManager?.openSoundPermission()
                break;
            case "isBluetoothConnected":
                let isConnected = AudioUtils.shared.hasBluetoothConnected()
                NSLog("isBlurCOnnected====> \(isConnected)")
                result(isConnected)
                break;
            case "toggleAudioRoute":
                guard let args = call.arguments as? Dictionary<String, Any> else {  result(false); return }
                let device = args["device"] as? String ?? ""
                NSLog("toggleAudioRoute device ::\(device)")
                if (device == "bluetooth") {
                    AudioUtils.shared.playBluetooth()
                } else if(device == "speaker"){
                    AudioUtils.shared.playSpeaker(isVoiceChat: self.agoraCallManager!.isEnableAudio)
                    self.agoraCallManager?.toggleSpeaker(isSpeaker: true)
                }else{
                    AudioUtils.shared.playEarpiece()
                    self.agoraCallManager?.toggleSpeaker(isSpeaker: false) 
                }
                result(true)
                break
            case "toggleAudioRouteForVoice":
                guard let args = call.arguments as? Dictionary<String, Any> else {  result(false); return }
                let device = args["device"] as? String ?? ""
                NSLog("toggleAudioRouteForVoice device ::\(device)")
                if (device == "bluetooth") {
                    AudioUtils.shared.playBluetooth()
                } else if(device == "speaker"){
                    AudioUtils.shared.playSpeakerForVoice()
                }else{
                    AudioUtils.shared.playEarpiece()
                }
                result(true)
                break
            default:
                break
            }
        })

        registerJPushNotification()
        voipRegistration()
        requestSiriAuthorizationIfNeeded()

        agoraCallManager = AgoraCallManager(rtcChannel: rtcChannel)
        providerDelegate = ProviderDelegate(callHelper: callHelper, rtcChannel: rtcChannel)

        let factory = NativeCallViewFactory(agoraCallManager: agoraCallManager!)
        registrar(forPlugin: "native Call")?.register(factory, withId:"native_video_widget")

        channelIDList = loadChannelIDList()
        channelIndex = loadChannelIndex()
        NSLog("channelIDList ::\(channelIDList)")
        NSLog("channelIDList Index ::\(channelIndex)")

        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }

        UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate

        if let geoApiKey = Bundle.main.object(forInfoDictionaryKey: "GeoApiKey") as? String{
            print("Geo Api Key: \(geoApiKey)")
            GMSServices.provideAPIKey(geoApiKey)
        }

        GeneratedPluginRegistrant.register(with: self)
        //当你调用 endReceivingRemoteControlEvents() 时，应用程序停止接收远程控制事件。这意味着如果用户通过锁屏界面、耳机按钮等设备发送控制事件，应用将不会再响应这些事件。
        UIApplication.shared.endReceivingRemoteControlEvents()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("request from outside app \(userActivity.activityType)")
        if (userActivity.activityType == "INStartAudioCallIntent"){

            guard let interaction = userActivity.interaction else {
                return false
            }
            if let interaction = userActivity.interaction,
                   let startAudioCallIntent = interaction.intent as? INStartAudioCallIntent,
                   let personHandle = startAudioCallIntent.contacts?.first?.personHandle {

                    if let chatId = personHandle.value {
                        self.rtcChannel?.invokeMethod("startCallIOS", arguments: chatId)
                    } else {
                        print("Person handle value is nil.")
                    }
                }
        }
        // 判断是否通过OpenInstall Universal Link 唤起App
         if OpeninstallFlutterPlugin.continue(userActivity) {
             print("OpeninstallFlutterPlugin: userActivity")
             return true
         }
        return true
    }

    private func voipRegistration() {
        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }

    private func registerJPushNotification(){
        let pushEntity = JPUSHRegisterEntity()
        if #available(iOS 12, *) {
            pushEntity.types = NSInteger(UNAuthorizationOptions.alert.rawValue) |
            NSInteger(UNAuthorizationOptions.sound.rawValue) |
            NSInteger(UNAuthorizationOptions.badge.rawValue) |
            NSInteger(UNAuthorizationOptions.provisional.rawValue)
        } else {
            pushEntity.types = NSInteger(UNAuthorizationOptions.alert.rawValue) |
            NSInteger(UNAuthorizationOptions.sound.rawValue) |
            NSInteger(UNAuthorizationOptions.badge.rawValue)
        }

        JPUSHService.register(forRemoteNotificationConfig: pushEntity, delegate: self)
        if let pushKey = Bundle.main.object(forInfoDictionaryKey: "PushKey") as? String,
            let pushChannel = Bundle.main.object(forInfoDictionaryKey: "PushChannel") as? String{
                print("Push Key: \(pushKey)")
                print("Push Channel: \(pushChannel)")
                JPUSHService.setup(withOption: nil, appKey: pushKey, channel:pushChannel, apsForProduction: false)
        }
    }
    func requestSiriAuthorizationIfNeeded() {
        let siriAuthorizationStatus = INPreferences.siriAuthorizationStatus()
        if siriAuthorizationStatus == .notDetermined {
            INPreferences.requestSiriAuthorization { status in
                switch status {
                case .authorized:
                    print("Siri authorization granted.")
                case .denied, .notDetermined, .restricted:
                    print("Siri authorization denied or not determined.")
                @unknown default:
                    print("Unknown Siri authorization status.")
                }
            }
        }
    }

    private func isBackgroundAudioPlaying(result: FlutterResult) {
        let audioSession = AVAudioSession.sharedInstance()
            do {
                result(audioSession.isOtherAudioPlaying)
            } catch {
                print("Failed to check background audio: \(error)")
                result(false)
            }
    }

    private func bluetoothPlay() {
        let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playback, mode: .default, options: [])
                try audioSession.setActive(true)
            } catch {
                print("Failed to check background audio: \(error)")

            }
    }

    private func syncChatList(_ arguments: Any?) {
        guard let args = arguments as? [String: Any],
              let bundleID = Bundle.main.bundleIdentifier,
              let encodedChatList = args["chatList"] as? String else {
            return
        }

        // Save to UserDefaults
        let groupDefaults = UserDefaults(suiteName: "group.\(bundleID).ImagePublish")
        groupDefaults?.set(encodedChatList, forKey: "chatList")
        if let data = groupDefaults?.string(forKey: "chatList") {
            NSLog("vvvv data saved \(data)")
        }
    }

    private func clearChatList() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return
        }

        let groupDefaults = UserDefaults(suiteName: "group.\(bundleID).ImagePublish")
        groupDefaults?.set("", forKey: "chatList")

        //同时清除推荐联系人
        DispatchQueue.main.async {
            INInteraction.deleteAll { error in
                if let error = error {
                    print("Error clearing all suggested contacts: \(error.localizedDescription)")
                } else {
                    print("All suggested contacts cleared successfully.")
                }
            }
        }
    }


    private func getShareFilePath(result: FlutterResult) {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let defaults = UserDefaults.init(suiteName: "group.\(bundleID).ImagePublish")
        if let array = defaults?.object(forKey: "share_image") {
            defaults?.setValue(nil, forKey: "share_image")
            imageDict = array as? NSArray
            result(array)
        }else{
            result(nil)
        }
    }

    private func clearShareData(result: FlutterResult) {
        imageDict = nil
        result(true)
    }

    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
        print("APNS Token -> \(token)")
        JPUSHService.registerDeviceToken(deviceToken)

        JPUSHService.registrationIDCompletionHandler { resCode, registrationID in
            if resCode == 0 {
                print("registrationID获取成功：\(String(describing: registrationID)) with: \(self.voipToken)")
                let data : [String: Any] = [
                    "registrationId": registrationID ?? "",
                    "platform": "2",
                    "voipToken":self.voipToken ?? "",
                    "source":"4"
                ]
                NSLog("FCMService:======> didRegisterForRemoteNotificationsWithDeviceToken \(String(describing: registrationID)) with: \(self.voipToken)")
                self.pushNotificationChannel?.invokeMethod("registerJPush", arguments: data)
            } else {
                print("registrationID获取失败，code：\(String(describing: registrationID))")
            }
        }
    }

    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
      print("Failed to register: \(error)")
    }

    override func application( _ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        NSLog("FCMService======> didReceiveRemoteNotification 1: \(userInfo)")
        LocalCallNotificationManager.shared.startNotification()
        if let deletedIDs = userInfo["to_delete"] as? Array<String>{
            NSLog("IOS 10 Notification: \(deletedIDs)")
            for deleteID in deletedIDs {
                UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                    for notification in notifications {
                        let notificationIdentifier = notification.request.identifier
                        let threadIdentifier = notification.request.content.threadIdentifier
                        let abc = notification.request.content.userInfo["delete_id"] as? String
                        NSLog("IOS 10 Notification abc: \(abc)")
                        if let currentDeleteID = notification.request.content.userInfo["delete_id"] as? String,
                           currentDeleteID == deleteID {
                            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
                        }
                        NSLog("IOS 10 Notification ID: \(notificationIdentifier)")
                    }
                }
            }
        }

        if let deletedIDs = userInfo["to_delete_chat"] as? Array<String>{
            for deleteID in deletedIDs {
                UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                    for notification in notifications {
                        let notificationIdentifier = notification.request.identifier
                        let threadIdentifier = notification.request.content.threadIdentifier
                        if let currentDeleteID = notification.request.content.userInfo["delete_id"] as? String{
                            let parts = currentDeleteID.split(separator: "-")

                            if parts.count >= 3 {
                                // Get the middle value
                                let middleValue = parts[1]
                                NSLog("Middle value: \(middleValue)")
                                if(middleValue == deleteID){
                                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
                                }
                            }
                        }
                        NSLog("IOS 10 Notification ID: \(notificationIdentifier)")
                    }
                }
            }
        }

        NSLog("vvvv iOS10 receive remote notification: \(userInfo)")
        if let isMissedCall = userInfo["is_missed_call"] as? Int,
           let isCancelCall = userInfo["is_cancel_call"] as? Int,
           let isVideoCall = userInfo["video_call"] as? Int,
           let rtcChannelId = userInfo["rtc_channel_id"] as? String {
            if isMissedCall == 1 || isCancelCall == 1 {
                var payload = Extra(chat_id: -1, rtc_channel_id: rtcChannelId, video_call: isVideoCall)
                providerDelegate?.cancelCallKit(payload: payload)

                // 取消那些不支持CallKit的地区的通话通知
                self.removeCallNotification(rtcChannelId: rtcChannelId, isIncomingCall: false)
            }
        } else {
            if let isStopCall = userInfo["stop_call"] as? Int,
               let isVideoCall = userInfo["video_call"] as? Int,
               let rtcChannelId = userInfo["rtc_channel_id"] as? String {
                if isStopCall == 1 {
                    var payload = Extra(chat_id: -1, rtc_channel_id: rtcChannelId, video_call: isVideoCall)
                    providerDelegate?.callEndFromFlutter = true
                    providerDelegate?.cancelCallKit(payload: payload)
                }
            }
        }

        JPUSHService.handleRemoteNotification(userInfo)
    }

    private func removeCallNotification(rtcChannelId: String, isIncomingCall: Bool){
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            for notification in notifications {
                let notificationIdentifier = notification.request.identifier
                let threadIdentifier = notification.request.content.threadIdentifier
                if let channelId = notification.request.content.userInfo["rtc_channel_id"] as? String {
                    if(channelId == rtcChannelId || isIncomingCall){
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
                    }
                }
            }
        }
    }

    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NSLog("FCMService======> didReceiveRemoteNotification 2: \(userInfo)")
        if let deletedIDs = userInfo["to_delete"] as? Array<String>{
            for deleteID in deletedIDs {
                UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                    for notification in notifications {
                        let notificationIdentifier = notification.request.identifier
                        if let currentDeleteID = notification.request.content.userInfo["delete_id"] as? String,
                           currentDeleteID == deleteID {
                            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
                        }
                        NSLog("IOS 10 Notification ID: \(notificationIdentifier)")
                    }
                }
            }
        }

        if let deletedIDs = userInfo["to_delete_chat"] as? Array<String>{
            for deleteID in deletedIDs {
                UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                    for notification in notifications {
                        let notificationIdentifier = notification.request.identifier
                        let threadIdentifier = notification.request.content.threadIdentifier
                        if let currentDeleteID = notification.request.content.userInfo["delete_id"] as? String{
                            let parts = currentDeleteID.split(separator: "-")

                            if parts.count >= 3 {
                                // Get the middle value
                                let middleValue = parts[1]
                                NSLog("Middle value: \(middleValue)")
                                if(middleValue == deleteID){
                                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
                                }
                            }
                        }
                        NSLog("IOS 10 Notification ID: \(notificationIdentifier)")
                    }
                }
            }
        }

        NSLog("vvvv iOS7及以上系统，收到通知:\(userInfo)")
        if let isMissedCall = userInfo["is_missed_call"] as? Int,
           let isCancelCall = userInfo["is_cancel_call"] as? Int,
           let isStopCall = userInfo["stop_call"] as? Int,
           let isVideoCall = userInfo["video_call"] as? Int,
           let rtcChannelId = userInfo["rtc_channel_id"] as? String {
            if isMissedCall == 1 || isCancelCall == 1 || isStopCall == 1 {
                var payload = Extra(chat_id: -1, rtc_channel_id: rtcChannelId, video_call: isVideoCall)
                providerDelegate?.cancelCallKit(payload: payload)
                LocalCallNotificationManager.shared.stopNotifications()
            } else {
                // Handle the case where isMissedCall and isCancelCall are not 1.
            }
        } else {
            // Handle the case where one or more values are nil or not of the expected type.
            if let isStopCall = userInfo["stop_call"] as? Int,
               let isVideoCall = userInfo["video_call"] as? Int,
               let rtcChannelId = userInfo["rtc_channel_id"] as? String {
                if isStopCall == 1 {
                    var payload = Extra(chat_id: -1, rtc_channel_id: rtcChannelId, video_call: isVideoCall)
                    providerDelegate?.callEndFromFlutter = true
                    providerDelegate?.cancelCallKit(payload: payload)
                }
            }
        }
        completionHandler(.newData)
    }

    // 适用于iOS 9之前版本
     override func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
         print("OpeninstallFlutterPlugin: open iOS 9 以下")
         // 判断是否通过OpenInstall URL Scheme 唤起App
         if OpeninstallFlutterPlugin.handLinkURL(url) {
             return true
         }
         // 其他第三方回调
         return true
     }

     // iOS 9及以上，会优先走这个方法
     @available(iOS 9.0, *)
     override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
         print("OpeninstallFlutterPlugin: open iOS 9 以上")
         // 判断是否通过OpenInstall URL Scheme 唤起App
         if OpeninstallFlutterPlugin.handLinkURL(url) {
             return true
         }
         // 其他第三方回调
         return true
     }

    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("FCMService======> withCompletionHandler 3")
        // 点击了本地推送的banner 会调用这个方法
        LocalCallNotificationManager.shared.stopNotifications()

        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            DispatchQueue.main.async {
                let content = response.notification.request.content.userInfo
                if let payload = content[AnyHashable("payload")] as? String {
                    if let data = payload.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                print("\(json)")
                                var chatId = 0;
                                if let payload1 = json["chat"] as? [String: Any],
                                   let id = payload1["chat_id"] as? Int{
                                    chatId = id
                                }
                                var notificationType = json["notification_type"] as? Int
                                let transactionID = json["transaction_id"] as? String

                                print("chat_id: \(chatId)")
                                print("notification_type: \(notificationType)")

                                if let isMissedCall = json["is_missed_call"] as? Int,
                                   let isStopCall = json["stop_call"] as? Int,
                                   let isCancelCall = json["is_cancel_call"] as? Int {
                                    if isMissedCall == 1 || isCancelCall == 1 || isStopCall == 1 {
                                        notificationType = 6
                                    } else {

                                    }
                                } else {

                                }

                                let data: [String: Any] = [
                                   "notification_type": notificationType,
                                   "chat_id": chatId,
                                   "transaction_id": transactionID ?? ""
                                ]

                               self.pushNotificationChannel?.invokeMethod("notificationRouting", arguments: data)

                            }
                        } catch {
                            print("Error parsing JSON: \(error)")
                        }
                    }
                }else{
                    print("jpushNotificationCenter -> \(content)")
                    var chatIDString: String = ""
                    if let cipherData = content["cipher_data"] as? String {
                        if let body = DecryptUtils.decryptData(encryptedData: cipherData),
                           let val = body["chat_id"] as? String {
                            chatIDString = val
                        } else {
                            NSLog("Failed to access chat_id")
                        }
                    } else {
                        NSLog("cipherData is not a String or is nil")
                    }

                    var notificationType = content["notification_type"] as? Int
                    let chatID = content["chat_id"] as? Int
                    let transactionID = content["transaction_id"] as? String

                    if let isMissedCall = content["is_missed_call"] as? Int,
                       let isStopCall = content["stop_call"] as? Int,
                       let isCancelCall = content["is_cancel_call"] as? Int {
                        if isMissedCall == 1 || isCancelCall == 1 || isStopCall == 1 {
                            notificationType = 6
                        } else {

                        }
                    } else {

                    }

                    let data : [String: Any] = [
                        "notification_type": notificationType ?? 0,
                        "chat_id" : chatID ?? chatIDString,
                        "transaction_id" : transactionID ?? 0,
                    ]
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.pushNotificationChannel?.invokeMethod("notificationRouting", arguments: data)
                    }
                }

//                JPUSHService.setBadge(0)
//                UIApplication.shared.applicationIconBadgeNumber = 0
                completionHandler()
            }
        }
    }

    func getKeyWindow() -> UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    func getLaunchType() -> String{
        let state = UIApplication.shared.applicationState
        if state == .background {
            return "background"
        }
        return "foreground"
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        appInForeground = false
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        application.cancelAllLocalNotifications()
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        appInForeground = true
        agoraCallManager?.stopPiPMode()
    }
    override func applicationWillTerminate(_ application: UIApplication) {
        JPUSHService.setBadge(application.applicationIconBadgeNumber)
    }

    func loadChannelIDList() -> [String] {
        if let encodedData = UserDefaults.standard.data(forKey: channelIDKey) {
            do {
                let decoder = JSONDecoder()
                let data = try decoder.decode([String].self, from: encodedData)
                return data
            } catch {
                print("Error decoding items: \(error)")
            }
        }
        return []
    }

    func saveChannelIDList(_ channelIDList: [String]) {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(channelIDList)
            UserDefaults.standard.set(encodedData, forKey: channelIDKey)
        } catch {
            print("Error encoding items: \(error)")
        }
    }

    func loadChannelIndex() -> Int {
        let userDefaults = UserDefaults.standard
        if let savedIndex = userDefaults.value(forKey: "channelIndex") as? Int {
            return savedIndex
            print("Saved Integer: \(savedIndex)")
        } else {
            print("Integer preference not found.")
        }
        return 0
    }

    func saveChannelIndex(_ index :Int){
        let userDefaults = UserDefaults.standard
        userDefaults.set(index, forKey: "channelIndex")
        userDefaults.synchronize()
    }

    func resetAudioSessionMode() {
        NSLog("resetAudioSessionMode=======>")
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            try audioSession.setCategory(.ambient, mode: .default)
            try audioSession.setActive(true)
        } catch {
            NSLog("Failed to reset audio session mode: \(error)")
        }
    }
    
    func imageFormat(from data: Data?) -> String? {
        guard let data = data else { return nil }
        // PNG文件的头部信息
        let pngHeader: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
        // JPEG文件的头部信息
        let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF]
        
        let header = [UInt8](data.prefix(3)) // 读取前3个字节

        if header == jpegHeader {
            return "JPEG"
        } else if data.prefix(pngHeader.count) == Data(pngHeader) {
            return "PNG"
        } else {
            return nil
        }
    }

    
    func saveUIImageToFileSystem(image: UIImage, filename: String) -> String? {
        // 将 UIImage 转换为 PNG 或 JPEG 数据
        if let imageData = image.pngData() {
            // 获取沙盒的临时目录路径
            let fileManager = FileManager.default
            let tmpDirURL = fileManager.temporaryDirectory
            
            // 创建文件路径
            let fileURL = tmpDirURL.appendingPathComponent(filename)
            
            do {
                // 将数据写入文件
                try imageData.write(to: fileURL)
                // 返回文件路径
                return fileURL.path
            } catch {
                print("Error writing image to file: \(error)")
                return nil
            }
        }
        return nil
    }
    
    func deleteImageFromFileSystem(filePath: String) -> Bool {
        let fileManager = FileManager.default
        do {
            // 尝试删除文件
            try fileManager.removeItem(atPath: filePath)
            print("File deleted successfully")
            return true
        } catch {
            print("Error deleting file: \(error)")
            return false
        }
    }
    
    func deleteFilesInTemporaryDirectory(matchingPrefix prefix: String) {
        let fileManager = FileManager.default
        let tmpDirURL = fileManager.temporaryDirectory

        do {
            // 获取临时目录中的所有文件 URL
            let fileURLs = try fileManager.contentsOfDirectory(at: tmpDirURL, includingPropertiesForKeys: nil, options: [])

            // 遍历文件 URL 并删除符合条件的文件
            for fileURL in fileURLs {
                if fileURL.lastPathComponent.contains(prefix) {
                    do {
                        try fileManager.removeItem(at: fileURL)
                        print("Deleted file: \(fileURL.lastPathComponent)")
                    } catch {
                        print("Error deleting file \(fileURL.lastPathComponent): \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("Error retrieving contents of temporary directory: \(error.localizedDescription)")
        }
    }
    
}

extension AppDelegate : PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        self.voipToken = deviceToken
        print("VOIP Token -> \(deviceToken)")

        JPUSHService.registerVoipToken(credentials.token)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        NSLog("FCMService======> 4: enableCallKit: \(isEnableCallkit), isAppInFore: \(appInForeground)")
        if(isEnableCallkit && !appInForeground){
            do {
                NSLog("FCMService======> 4a: aps: \(payload.dictionaryPayload["aps"]), voip: \(payload.dictionaryPayload["_j_voip"])")
                if (payload.dictionaryPayload["aps"] != nil) {
                    let apsData = try JSONSerialization.data(withJSONObject: payload.dictionaryPayload["aps"] ?? [])
                    let apsObj = try JSONDecoder().decode(Aps.self, from: apsData)
                    NSLog("channelIDList aps::\(channelIDList.contains( apsObj.extra.rtc_channel_id))")
                    if(channelIDList.contains( apsObj.extra.rtc_channel_id)){
                        completion()
                        return
                    }else{
                        self.providerDelegate?.reportIncomingCall(uuid: UUID(), payload:  apsObj.extra) {_ in
                            completion()
                        }
                        return
                    }
                } else if (payload.dictionaryPayload["_j_voip"] != nil) {
                    let apsData = try JSONSerialization.data(withJSONObject: payload.dictionaryPayload["_j_voip"] as? [String: Any] ?? [])
                    let apsObj = try JSONDecoder().decode(JVoIP.self, from: apsData)
                    NSLog("channelIDList voip:: has \(channelIDList.contains(apsObj.extras.rtc_channel_id))")
                    NSLog("FCMService======> 4b: apsObjIcon: \(apsObj.extras.icon), contains: \(channelIDList.contains(apsObj.extras.rtc_channel_id))")
                    if(channelIDList.contains(apsObj.extras.rtc_channel_id)){
                        completion()
                        return
                    }else{
                        self.providerDelegate?.reportIncomingCall(uuid: UUID(), payload: apsObj.extras) {_ in
                            completion()
                        }
                        return
                    }
                } else {
                    completion()
                }
            } catch {
                NSLog("FCMService======> 4e: enableCallKit: \(error)")
                print(error)
                completion()
            }
        } else {
            completion()
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry:didInvalidatePushTokenForType:")
    }
}

extension AppDelegate: JPUSHRegisterDelegate{
    
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: ((Int) -> Void)) {
        NSLog("FCMService======> willPresent")
        //open app show notification
//        completionHandler(Int(UNNotificationPresentationOptions.badge.rawValue | UNNotificationPresentationOptions.sound.rawValue | UNNotificationPresentationOptions.alert.rawValue))
    }
    
    @available(iOS 10.0, *)
        func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {
    
            DispatchQueue.main.async {
                let content = response.notification.request.content.userInfo
                print("jpushNotificationCenter -> \(content)")
                let notificationType = content["notification_type"] as? Int
                let chatID = content["chat_id"] as? Int
                let transactionID = content["transaction_id"] as? String


                let data : [String: Any] = [
                    "notification_type": notificationType ?? 0,
                    "chat_id" : chatID ?? 0,
                    "transaction_id" : transactionID ?? 0,
                ]

                self.pushNotificationChannel?.invokeMethod("notificationRouting", arguments: data)

//                JPUSHService.setBadge(0)
//                UIApplication.shared.applicationIconBadgeNumber = 0
                completionHandler()
            }
    
        }

    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification) {
        
    }
    
    func jpushNotificationAuthorization(_ status: JPAuthorizationStatus, withInfo info: [AnyHashable : Any]?) {
        print("receive notification authorization status:\(status), info:\(String(describing: info))")
    }
}


extension UIWindow {
     open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NSLog("motionEnded========> \(motion)")
        }
     }
}
