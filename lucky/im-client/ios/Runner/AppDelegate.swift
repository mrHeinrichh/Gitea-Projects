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
    var mainVC: FlutterViewController?

    var shareExtentToolsChannel: FlutterMethodChannel?
    
    var pushNotificationChannel : FlutterMethodChannel?
    
    var generalChannel : FlutterMethodChannel?

    var imageDict: NSDictionary?
    
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

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        mainVC = controller
        
        shareExtentToolsChannel = FlutterMethodChannel.init(name: "jxim/share.extent", binaryMessenger: controller as! FlutterBinaryMessenger)
        pushNotificationChannel = FlutterMethodChannel.init(name: "jxim/notification", binaryMessenger: controller as! FlutterBinaryMessenger)
        rtcChannel = FlutterMethodChannel.init(name: "jxim/rtc", binaryMessenger: controller as! FlutterBinaryMessenger)
        generalChannel = FlutterMethodChannel.init(name: "jxim/general", binaryMessenger: controller as! FlutterBinaryMessenger)
        
        generalChannel?.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if (call.method == "isBackgroundAudioPlaying") {
                self.isBackgroundAudioPlaying(result: result)
            }
        })
        
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
            }
          })
        
        rtcChannel?.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch(call.method) {
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
                    self.agoraCallManager?.joinBroadcastStream(args["channelId"] as! String,token: args["token"] as? String,uid: args["uid"] as! UInt)
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
                self.agoraCallManager?.releaseEngine()
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
                UIDevice.current.isProximityMonitoringEnabled = false
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
                UIDevice.current.isProximityMonitoringEnabled = true
                break;
            case "callViewDismiss":
                if let args = call.arguments as? Dictionary<String, Any> {
                    self.agoraCallManager?.onExitCallView(isExit: args["isExit"] as? Bool ?? false)
                }
                break
            case "isInForeground":
                result(self.appInForeground)
                break
            case "restoreAudioCategory":
                self.restoreAudioCategory()
                break;
            default:
                break
            }
        })
        
        registerJPushNotification()
        voipRegistration()
        
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange(notification:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    @objc func handleAudioRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        NSLog("handleAudioRouteChange======> \(reason), \(reasonValue), \(userInfo)")
//        switch reason {
//        case .categoryChange:
//            providerDelegate?.setSpeaker(enabled: false)
//            break
//        case .override:
//            providerDelegate?.setSpeaker(enabled: true)
//            break
//        case .newDeviceAvailable, .oldDeviceUnavailable:
//            providerDelegate?.updateAudioOutputToSpeaker()
//        default:
//            break
//        }
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
        return true
    }

    private func voipRegistration() {
        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            // 1. Check to see if permission is granted
            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
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
    
    private func isBackgroundAudioPlaying(result: FlutterResult) {
        let audioSession = AVAudioSession.sharedInstance()
            do {
//                try audioSession.setCategory(.ambient, options: .mixWithOthers)
//                try audioSession.setActive(true)
                result(audioSession.isOtherAudioPlaying)
            } catch {
                print("Failed to check background audio: \(error)")
                result(false)
            }
    }
    
    private func restoreAudioCategory() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, options: .defaultToSpeaker)
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
    }

    private func getShareFilePath(result: FlutterResult) {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let defaults = UserDefaults.init(suiteName: "group.\(bundleID).ImagePublish")
        if let dict = defaults?.object(forKey: "share_image") {
            defaults?.setValue(nil, forKey: "share_image")
            imageDict = dict as? NSDictionary
            result(dict)
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
            } else {
                // Handle the case where isMissedCall and isCancelCall are not 1.
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

    
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
//        JPUSHService.handleRemoteNotification(userInfo)
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
        
        print("iOS7及以上系统，收到通知:\(userInfo)")
        NSLog("vvvv iOS7及以上系统，收到通知:\(userInfo)")
        if let isMissedCall = userInfo["is_missed_call"] as? Int,
           let isCancelCall = userInfo["is_cancel_call"] as? Int,
           let isStopCall = userInfo["stop_call"] as? Int,
           let isVideoCall = userInfo["video_call"] as? Int,
           let rtcChannelId = userInfo["rtc_channel_id"] as? String {
            if isMissedCall == 1 || isCancelCall == 1 || isStopCall == 1 {
                var payload = Extra(chat_id: -1, rtc_channel_id: rtcChannelId, video_call: isVideoCall)
                providerDelegate?.cancelCallKit(payload: payload)
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
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
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

                JPUSHService.setBadge(0)
                UIApplication.shared.applicationIconBadgeNumber = 0
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
//        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        JPUSHService.setBadge(0)
        application.applicationIconBadgeNumber = 0
        application.cancelAllLocalNotifications()
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        appInForeground = true
        JPUSHService.setBadge(0)
        UIApplication.shared.applicationIconBadgeNumber = 0
        agoraCallManager?.stopPiPMode()
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
}

extension AppDelegate : PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        self.voipToken = deviceToken
        print("VOIP Token -> \(deviceToken)")

        JPUSHService.registerVoipToken(credentials.token)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        NSLog("pushRegistry -> isEnableCallKit : \(isEnableCallkit)")
        if(isEnableCallkit){
            NSLog("pushRegistry -> payload : \(payload.dictionaryPayload)")
            do {
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
                    NSLog("channelIDList ::\(channelIDList.contains(apsObj.extras.rtc_channel_id))")
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

                JPUSHService.setBadge(0)
                UIApplication.shared.applicationIconBadgeNumber = 0
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
