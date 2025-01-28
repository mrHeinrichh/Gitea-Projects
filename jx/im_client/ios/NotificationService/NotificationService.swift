//
//  NotificationService.swift
//  NotificationService
//k
//  Created by fang on 2022/4/11.
//

import UserNotifications
import Foundation
import Intents
import UIKit
import Sentry
import CryptoKit



@available(iOSApplicationExtension 13.0, *)
class NotificationService: UNNotificationServiceExtension {
    private let channelIDKey = "channelIDKey"
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    let center = UNUserNotificationCenter.current()
    private let notiRepeatNumKey = "NOTI_REPEAT_NUM"
    var registeredSentry = false
    
    private func registerSentry(){
        if registeredSentry { return }
        initSentry()
    }
    
    private let trackingKey = "NotificationTracking"
    var notificationItem = [String : [String]]()
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        NSLog("FCMService======> didReceive 1")
        self.registerSentry()
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        var icon : URL?
        var useAvatarGen = false
        var chatIdInt = 0
        var titleLater = ""
        var uidInt:Int?
        guard let bestAttemptContent = self.bestAttemptContent else {
            return
        }
        
        var userInfo = bestAttemptContent.userInfo
        guard let aps = userInfo["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let normalTitle = alert["title"] as? String, let normalBody = alert["body"] as? String, let jMsgId = userInfo["_j_msgid"] as? Int else {
            return
        }
        
        let jPushMsgID = String(describing: jMsgId)
        self.syncNotificationStep(jPushMsgID, "开始")
        
        if let encryptedData = userInfo["cipher_data"] as? String {
            NSLog("FCMService======> didReceive 2")
            if let decryptedData = DecryptUtils.decryptData(encryptedData: encryptedData) {
                self.syncNotificationStep(jPushMsgID, "第一段AES解析成功")
                if let chatID = decryptedData["chat_id"] as? String, let chatIdx = decryptedData["chat_idx"] as? String {
                    modifyBadge(bestAttemptContent, chatID, chatIdx)
                }
                
                let title = decryptedData["title"] as? String ?? "Hey"
                var body:String = ""
                
                if let b = decryptedData["body"] as? String {
                    //普通解密先赋值，后续端到端解密出来才替换掉
                    body = b
                    self.syncNotificationStep(jPushMsgID, "AES后取body")
                    
                    if let json = decryptedData["e2e"] as? String, let chatId = decryptedData["chat_id"] as? String {
                        do {
                            //e2e加密信息存在，chat id存在
                            if let jsonData = json.data(using: .utf8), let jsonMap = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                              //e2e json成功格式化
                                var userName = decryptedData["sender_name"] as? String
                                var aMap:[String:String] = [String:String]()
                                if let a = decryptedData["at_user"] as? String, let atJson = a.data(using: .utf8), let atMap = try JSONSerialization.jsonObject(with: atJson, options: []) as? [String: String] {
                                    aMap = atMap
                                }
                                //decryptedData["userName"] as? String
                                if let refType = decryptedData["ref_typ"] as? String, let rt = Int(refType), rt == 1, let messageRound = jsonMap["round"] as? Int, let encrypted = jsonMap["data"] as? String   {
                                    //普通消息传递，探查 ref_typ == 1，json结构带round、data加密信息
                                    let (key, textKeys, isSingle) = self.getCurrentChatKey(chatId: chatId, messageRound: messageRound)
                                    if let singleChat = isSingle, singleChat == true {
                                        userName = nil
                                    }
                                    if let k = key, let decrypted = DecryptUtils.decryptDataWithKey(encryptedData: encrypted, key:k), let tk = textKeys, let msgTyp = decryptedData["msg_typ"] as? String, let mTyp = Int(msgTyp), let processedText = self.processText(mTyp, decrypted, tk, userName, aMap) {
                                        //获取chat key后解析成功，并按照msg typ或者text参数获取到需展示文本后进行展示
                                        self.syncNotificationStep(jPushMsgID, "端到端解析成功")
                                        body = processedText
                                    }
                                } else if let content = jsonMap["content"] as? String, let refType = jsonMap["ref_typ"] as? Int, refType == 1, let jData = content.data(using: .utf8), let jContent = try JSONSerialization.jsonObject(with: jData, options: []) as? [String: Any], let messageRound = jContent["round"] as? Int, let encrypted = jContent["data"] as? String {
                                    //若有带content并带上内置ref type == 1，则表明是编辑的加密消息, 同时也尝试格式化content，推算出round 和data信息。
                                    let (key, textKeys, isSingle) = self.getCurrentChatKey(chatId: chatId, messageRound: messageRound)
                                    
                                    if let singleChat = isSingle, singleChat == true {
                                        userName = nil
                                    }
                                    
                                    if let k = key, let decrypted = DecryptUtils.decryptDataWithKey(encryptedData: encrypted, key:k), let tk = textKeys, let msgTyp = decryptedData["msg_typ"] as? String, let mTyp = Int(msgTyp), let processedText = self.processText(mTyp, decrypted, tk, userName, aMap) {
                                        //获取chat key后解析成功，并按照msg typ或者text参数获取到需展示文本后进行展示
                                        self.syncNotificationStep(jPushMsgID, "端到端解析成功")
                                        body = processedText
                                    }
                                    
                                }
                            }
                        } catch {
                            print("离线推送解密 - json serialization error")
                            self.syncNotificationStep(jPushMsgID, "离线推送解密失败")
                        }
                    }
                } else {
                    body = normalBody
                    self.syncNotificationStep(jPushMsgID, "使用普通文本")
                }
                
                var decryptedIcon: String
                if (decryptedData["icon"] != nil) {
                    decryptedIcon = (decryptedData["icon"] as! String) + "?image_size=64&encrypt=1"
                } else {
                    decryptedIcon = ""
                }
                icon = URL(string: decryptedIcon) ?? nil
                let notificationType = decryptedData["notification_type"] as? String ?? "0"
                let chatID = decryptedData["chat_id"] as? String ?? "0"
                let transactionID = decryptedData["transaction_id"] as? String ?? ""
                let rtcChannelID = decryptedData["rtc_channel_id"] as? String ?? ""
                let isMissedCall = decryptedData["is_missed_call"] as? String ?? "0"
                let isStopCall = decryptedData["stop_call"] as? String ?? "0"
                let isCancelCall = decryptedData["is_cancel_call"] as? String ?? "0"
                let deleteID = decryptedData["delete_id"] as? String ?? "0"
                let uid = decryptedData["sender_id"] as? String
                var sound = decryptedData["sound"] as? String ?? ""
                let groupExpiry = decryptedData["group_expiry"] as? String ?? ""
                
                bestAttemptContent.title = title
                bestAttemptContent.body = body
                userInfo["notification_type"] = Int(notificationType)
                userInfo["chat_id"] = Int(chatID)
                userInfo["transaction_id"] = transactionID
                userInfo["rtc_channel_id"] = rtcChannelID
                userInfo["is_missed_call"] = Int(isMissedCall)
                userInfo["stop_call"] = Int(isStopCall)
                userInfo["is_cancel_call"] = Int(isCancelCall)
                userInfo["delete_id"] = deleteID
                
                let url = URL(fileURLWithPath: sound)
                sound = url.lastPathComponent
                
                if (sound.contains("empty.mp3")){
                    bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "empty.mp3"))
                } else {
                    bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "noti_"+sound))
                }
                
                if let num = Int(chatID) {
                    chatIdInt = num
                }
                if let uid = uid, let uidIntPhrase = Int(uid){
                    uidInt = uidIntPhrase
                }
                
                if groupExpiry != "" {
                    if let groupExpiryDouble = Double(groupExpiry) {
                        let date = Date(timeIntervalSince1970: groupExpiryDouble)
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
                        let dateString = dateFormatter.string(from: date)
                        let replacedString = body.replacingOccurrences(of: "_s", with: dateString)
                        
                        bestAttemptContent.body = replacedString
                    }
                }
                
                titleLater = title
                self.syncNotificationStep(jPushMsgID, "解析后赋予其他参数")
            } else {
                self.syncNotificationStep(jPushMsgID, "使用普通文本")
            }
        } else {
            if let chatID = userInfo["chat_id"] as? Int {
                modifyBadge(bestAttemptContent, String(chatID), "")
            }
            icon = URL(string: (userInfo["icon"]) as? String ?? "")
            titleLater = normalTitle
            uidInt = userInfo["sender_id"] as? Int
            chatIdInt = userInfo["chat_id"] as? Int ?? 0
            
            // 取消那些不支持CallKit的地区的通话通知
            if let rtcChannelId = userInfo["rtc_channel_id"] as? String,
               let notificationType = userInfo["notification_type"] as? Int{
                if(notificationType == 1){
                    var cancelChannelIds: [String] = self.loadChannelIDList()
                    if(cancelChannelIds.count > 10){
                        cancelChannelIds.removeLast()
                    }
                    cancelChannelIds.insert(rtcChannelId, at: 0)
                    self.saveChannelIDList(cancelChannelIds)
                    if let isCancelCall = userInfo["is_cancel_call"] as? Int {
                        if isCancelCall == 1 {
                            self.removeCallNotification(rtcChannelId: rtcChannelId)
                        }
                    }
                }else if(notificationType == 5){
                    bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "u_call.mp3"))
                    let cancelChannelIds = self.loadChannelIDList()
                    
                    // 当对方取消通话时的通知快于来电通知时
                    if(cancelChannelIds.contains(rtcChannelId)){
                        self.syncNotificationStep(jPushMsgID, "完成/END")
                        contentHandler(bestAttemptContent)
                        
                        if let channelId = userInfo["rtc_channel_id"] as? String {
                            self.removeActiveCallNotifications(rtcChannelId: channelId)
                        }
                        
                        return
                    }
                }
            }
            self.syncNotificationStep(jPushMsgID, "没Cipher Data流程")
        }
        
        bestAttemptContent.userInfo = userInfo
        let fromUsername: String = request.content.title as String
        
        if let icon = icon {
            if (icon.absoluteString.contains("GroupImg.png")){
                useAvatarGen = true
                //如果是群组 不使用sender_id 来生成头像
                uidInt = nil
            }
            if (icon.absoluteString.contains("person.png")){
                useAvatarGen = true
            }
        }else{
            useAvatarGen = true
        }
        
        self.syncNotificationStep(jPushMsgID, "开始头像下载流程")
        
        DispatchQueue.main.async {
            let imageGen = useAvatarGen ? AvatarGen(chatId: uidInt ?? chatIdInt, name: titleLater).imageFromChat() : nil
            let pngDataGen = imageGen?.pngData()
            DispatchQueue.global().async {//异步线程
                if #available(iOSApplicationExtension 15.0, *) {
                    self.syncNotificationStep(jPushMsgID, "赋予默认头像")
                    var sender = INPerson(
                        personHandle: .init(value: fromUsername, type: .unknown), nameComponents: nil, displayName: fromUsername, image: nil, contactIdentifier: nil, customIdentifier: ""
                    )
                    
                    var intent = INSendMessageIntent(
                        recipients: nil, outgoingMessageType: .outgoingMessageText, content: "tong zhi de nei long", speakableGroupName: nil, conversationIdentifier: "xxxxx", serviceName: nil, sender: sender, attachments: nil
                    )
                    
                    
                    if useAvatarGen, let png = pngDataGen {
                        self.syncNotificationStep(jPushMsgID, "赋予名称生成的头像")
                        sender = INPerson(
                            personHandle: .init(value: fromUsername, type: .unknown), nameComponents: nil, displayName: fromUsername, image: INImage(imageData: png), contactIdentifier: nil, customIdentifier: ""
                        )
                        intent = INSendMessageIntent(
                            recipients: intent.recipients,
                            outgoingMessageType: intent.outgoingMessageType,
                            content: intent.content,
                            speakableGroupName: intent.speakableGroupName,
                            conversationIdentifier: intent.conversationIdentifier,
                            serviceName: intent.serviceName,
                            sender: sender,
                            attachments: intent.attachments
                        )
                        self.interactionDonateHandler(intent, contentHandler, bestAttemptContent, jPushMsgID)
                        return
                    }
                    
                    if let iconURL = icon {
                        func dealWithAvatar(image:UIImage?){
                            if let image = image, let pngData = image.pngData() {
                                self.syncNotificationStep(jPushMsgID, "赋予下载/缓存好的头像")
                                sender = INPerson(
                                    personHandle: .init(value: fromUsername, type: .unknown), nameComponents: nil, displayName: fromUsername, image: INImage(imageData: pngData), contactIdentifier: nil, customIdentifier: ""
                                )
                                intent = INSendMessageIntent(
                                    recipients: intent.recipients,
                                    outgoingMessageType: intent.outgoingMessageType,
                                    content: intent.content,
                                    speakableGroupName: intent.speakableGroupName,
                                    conversationIdentifier: intent.conversationIdentifier,
                                    serviceName: intent.serviceName,
                                    sender: sender,
                                    attachments: intent.attachments
                                )
                                
                                do {
                                    let updatedContent = try bestAttemptContent.updating(from: intent)
                                    //回调 （主线程）
                                    self.interactionDonateHandler(intent, contentHandler, updatedContent, jPushMsgID)
                                } catch {
                                    SentrySDK.capture(error: error)
                                    NSLog("Failed to update content: \(error.localizedDescription)")
                                    self.interactionDonateHandler(intent, contentHandler, bestAttemptContent, jPushMsgID)
                                }
                            } else {
                                //回调 （主线程）
                                self.interactionDonateHandler(intent, contentHandler, bestAttemptContent, jPushMsgID)
                            }
                        }
                        
                        
                        let urlHash = iconURL.absoluteString.sha256()
                        if let cachedAvatar = self.getCachedImage(for: urlHash) {
                            dealWithAvatar(image: cachedAvatar)
                        }else{
                            self.downloadImage(from: iconURL) { image in
                                if let image = image {
                                    self.saveImageToDisk(image: image, urlHash: urlHash)
                                }
                                dealWithAvatar(image: image)
                            }
                        }
                        
                    } else {
                        //回调 （主线程）
                        self.interactionDonateHandler(intent, contentHandler, bestAttemptContent, jPushMsgID)
                    }
                } else {
                    DispatchQueue.main.async{
                        self.syncNotificationStep(jPushMsgID, "完成/END")
                        contentHandler(bestAttemptContent) //需在主线程赋值
                    }
                }
            }
        }
    }
    
    @available(iOS 15.0, *)
    private func interactionDonateHandler(_ intent : INSendMessageIntent, _ contentHandler: @escaping (UNNotificationContent) -> Void, _ bestAttemptContent : UNNotificationContent, _ jPushMsgID : String) -> Void {
        let interaction = INInteraction(intent: intent, response: nil)
        
        interaction.direction = .incoming
        interaction.donate { error in
            if let error = error {
                NSLog("Donation failed: \(error.localizedDescription)")
            }
            self.syncNotificationStep(jPushMsgID, "完成/END")
            DispatchQueue.main.async{
                //需在主线程赋值
                do {
                    let updatedContent = try bestAttemptContent.updating(from: intent)
                    contentHandler(updatedContent)
                } catch {
                    SentrySDK.capture(error: error)
                    contentHandler(bestAttemptContent)
                }
            }
        }
    }
    
    func modifyBadge(_ bestAttemptContent: UNMutableNotificationContent, _ chatID: String, _ chatIdx: String) {
        guard let groupDefaults = getNotiGroupDefaults() else {
            return
        }
        guard let keys = groupDefaults.object(forKey: "REAL_MESSAGE_KEYS") as? [String] else {
            NSLog("[noti] REAL_MESSAGE_KEYS value not found")
            return
        }
        
        guard
            let badge = bestAttemptContent.badge
        else {
            return
        }
        
        var difBadge = 0
        let messageKey = chatID + "_" + chatIdx
        if keys.contains(messageKey) {
            incRepeatNum()
        }
        difBadge = difBadge - getRepeatNum()
        var newBadge = badge.intValue + difBadge
        if (newBadge < 0) {
            newBadge = 0
        }
        
        bestAttemptContent.badge = NSNumber(value: newBadge)
        NSLog("[noti] modify badge, \(bestAttemptContent.badge ?? 0)")
    }

    func incRepeatNum() {
        guard let groupDefaults = getNotiGroupDefaults() else {
            return
        }
        
        let reapeatNum = groupDefaults.integer(forKey: notiRepeatNumKey)
        groupDefaults.setValue(reapeatNum + 1, forKey: notiRepeatNumKey)
        NSLog("[noti] set repeat num, \(reapeatNum + 1)")
    }
    
    func getRepeatNum () -> Int {
        guard let groupDefaults = getNotiGroupDefaults() else {
            return 0
        }
        
        return groupDefaults.integer(forKey: notiRepeatNumKey)
    }
    
    private func initSentry() {
        let dnsKey = "SENTRY_DNS"
        let releaseNameKey = "SENTRY_NAME"
        let releaseBundleKey = "SENTRY_BUNDLE"
        
        guard let groupDefaults = getNotiGroupDefaults(), let dns = groupDefaults.string(forKey: dnsKey), let releaseName = groupDefaults.string(forKey: releaseNameKey), let releaseBundle = groupDefaults.string(forKey: releaseBundleKey) else {
            return
        }
        
        SentrySDK.start { options in
            options.dsn = dns
            
            options.releaseName = releaseName
            options.environment = releaseBundle
            options.debug = false
            
            options.beforeSend = { event in
                NSLog("registerSentry  \(String(describing:event.message))")
                return event
            }
        }
    }
    
    private func getNotiGroupDefaults() -> UserDefaults? {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            NSLog("[noti] bundleID not found")
            return nil
        }
        
        guard let groupDefauls = UserDefaults(suiteName: "group.\(bundleID)") else {
            NSLog("[noti] userDefaults not found, \(bundleID)")
            return nil
        }
        
        return groupDefauls
    }
    
    func saveChannelIDList(_ channelIDList: [String]) {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(channelIDList)
            UserDefaults.standard.set(encodedData, forKey: channelIDKey)
            UserDefaults.standard.synchronize()
        } catch {
            SentrySDK.capture(error: error)
            print("Error encoding items: \(error)")
        }
    }
    
    func loadChannelIDList() -> [String] {
        if let encodedData = UserDefaults.standard.data(forKey: channelIDKey) {
            do {
                let decoder = JSONDecoder()
                let data = try decoder.decode([String].self, from: encodedData)
                return data
            } catch {
                SentrySDK.capture(error: error)
                print("Error decoding items: \(error)")
            }
        }
        return []
    }
    
    private func removeActiveCallNotifications(rtcChannelId: String){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let cancelChannelIds: [String] = self.loadChannelIDList()
            if(cancelChannelIds.contains(rtcChannelId)){
                self.removeCallNotification(allPrevCalls: true)
            }
        }
    }
    
    private func removeCallNotification(rtcChannelId: String = "", allPrevCalls: Bool = false){
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            for notification in notifications {
                if let channelId = notification.request.content.userInfo["rtc_channel_id"] as? String {
                    if(channelId == rtcChannelId || allPrevCalls){
                        let notificationIdentifier = notification.request.identifier
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
                    }
                }
            }
        }
    }
    
    func getExtValue(userInfo: [AnyHashable : Any]?, key:String) -> Any?{
        let ext = userInfo?["ext"] as? [String: Any]
        return ext?[key]
    }
    
    override func serviceExtensionTimeWillExpire() {
        NSLog("NotificationService 接收到远程通知-〈5〉")
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            if let jMsgId = bestAttemptContent.userInfo["_j_msgid"] as? Int {
                let jPushMsgID = String(describing: jMsgId)
                self.syncNotificationStep(jPushMsgID, "离线通知超时最终处理")
            }
            contentHandler(bestAttemptContent)
            
            if let channelId = bestAttemptContent.userInfo["rtc_channel_id"] as? String {
                self.removeActiveCallNotifications(rtcChannelId: channelId)
            }
        }
    }
    
    func getCachedImage(for urlHash: String) -> UIImage? {
        let fileManager = FileManager.default
        let cacheDirectory = getAppGroupCacheDirectory()
        let fileURL = cacheDirectory.appendingPathComponent("\(urlHash).png")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            return UIImage(contentsOfFile: fileURL.path)
        }
        return nil
    }
    func downloadImage(from url: URL?, completion: @escaping (UIImage?) -> Void) {
        guard let url = url else {
            completion(nil)
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            if let d = data {
                var finalData = d
                if url.absoluteString.contains("secret/"), let decodeKey = self.getDecodeKey(from: url.absoluteString) {
                    let uInt8 = [UInt8](finalData)
                    finalData = self.xorDecode(inputBytes: uInt8, key: decodeKey)
                }
                completion(UIImage(data: finalData))
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
    func saveImageToDisk(image: UIImage, urlHash: String){
        let cacheDirectory = getAppGroupCacheDirectory()
        let fileURL = cacheDirectory.appendingPathComponent("\(urlHash).png")
        
        if let imageData = image.pngData() {
            do {
                try imageData.write(to: fileURL)
            } catch {
                SentrySDK.capture(error: error)
                print("Failed to save image: \(error)")
            }
        }
    }
    func getAppGroupCacheDirectory() -> URL {
        let fileManager = FileManager.default
        let cacheDirectory: URL
        
        //            // 使用 App Group 目录
        //            if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.your.app") {
        //                cacheDirectory = groupURL
        //            } else {
        // 如果没有配置 App Group，默认使用临时目录
        cacheDirectory = fileManager.temporaryDirectory
        //            }
        
        // 确保目录存在
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return cacheDirectory
    }


    
    private func getCurrentChatKey(chatId:String, messageRound: Int) -> (String?, [String : String]?, isSingle : Bool?) {
        let key = "CHAT_ENCRYPTION_MAP"
        guard let groupDefaults = self.getNotiGroupDefaults(), let data = groupDefaults.dictionary(forKey: key) as? [String:[String:Any]], let chatMap = data[chatId], let activeKeyRound = chatMap["activeRound"] as? Int, var activeKey = chatMap["activeKey"] as? String, let isSingle = chatMap["isSingle"] as? Bool else {
            return (nil, nil, nil)
        }
        
        guard let textKeys = data["encryption_language"] as? [String : String] else {
            return (nil, nil, isSingle)
        }
        
        if activeKeyRound > messageRound {
            return (nil, textKeys, isSingle);
        }
        
        if (messageRound > activeKeyRound) {
            let numberOfTimes = messageRound - activeKeyRound;
            for _ in 0..<numberOfTimes {
                activeKey = activeKey.MD5
            }
        }
        
        return (activeKey, textKeys, isSingle);
    }
    
    private func processText(_ msgTyp: Int, _ decrypted:[String: Any], _ textKeys: [String: String], _ userName: String?, _ atUsers: [String: String]) -> String? {
        var userNameText = "";
        if let user = userName {
            userNameText = user + ": "
        }
        
        let patternA = "⅏⦃"
        let patternB = "@jx❦⦄" // Match digits between ⅏⦃ and @jx❦⦄
        let searchAllText = "⅏⦃0@jx❦⦄"
        
        if (textKeys.isEmpty) {
            guard let text = decrypted["text"] as? String else{
                return nil
            }
            var updatedText = text
            for uid in atUsers.keys {
                let pattern = patternA + uid + patternB
                if let name = atUsers[uid] {
                    updatedText = updatedText.replacingOccurrences(of: pattern, with: "@"+name)
                }
            }
            
            return userNameText + updatedText
        }
        
        switch (msgTyp) {
        case 2:
            guard let image = textKeys["image"] else {
                return nil
            }
            return userNameText + image
        case 4, 24:
            guard let video = textKeys["video"] else {
                return nil
            }
            return userNameText + video
        case 8:
            guard let album = textKeys["album"], let onlyVideo = textKeys["album_onlyVideo"], let onlyImage = textKeys["album_onlyImage"] else {
                return nil
            }
            
            
            if let count = decrypted["count"] as? Int, let fType = decrypted["type"] as? Int {
                var finalText = fType == 0 ? album : (fType == 1 ? onlyImage : onlyVideo)
                if (fType != 0) {
                    finalText = finalText.replacingOccurrences(of: "%1", with: String(count))
                }
                return userNameText + finalText
            }
            
            guard let list = decrypted["albumList"] as? [[String: Any]] else {
                return nil
            }
            
            
            var type:String?
            var finalText = album
            var hasDiffType = false
            
            for dict in list {
                if let t = dict["mimeType"] as? String {
                    if (type != nil && type != t) {
                        hasDiffType = true
                        break
                    }
                    type = t
                }
            }
            
            if (!hasDiffType) {
                finalText = type == "image" ? onlyImage : onlyVideo
                finalText = finalText.replacingOccurrences(of: "%1", with: String(list.count))
            }
            
            return userNameText + finalText
        case 3:
            guard let voice = textKeys["voice"] else {
                return nil
            }
            return voice
        case 6:
            guard let icon = textKeys["file"], let fileName = decrypted["file_name"] as? String else {
                return nil
            }
            return userNameText + icon+fileName
        case 25:
            guard let gif = textKeys["gif"] else {
                return nil
            }
            return userNameText + gif
        case 5:
            guard let sticker = textKeys["sticker"] else {
                return nil
            }
            return userNameText + sticker
        case 7:
            guard let location = textKeys["location"] else {
                return nil
            }
            return location
        case 15:
            guard let icon = textKeys["recommendFriend"], let nickname = decrypted["nick_name"] as? String else {
                return nil
            }
            return userNameText + icon+nickname
        default:
            guard let text = decrypted["text"] as? String, let all = textKeys["all"] else{
                return nil
            }
            
            var updatedText = text
            if (text.contains(searchAllText)) {
                updatedText = updatedText.replacingOccurrences(of: searchAllText, with: "@"+all)
            }
            
            for uid in atUsers.keys {
                let pattern = patternA + uid + patternB
                if let name = atUsers[uid] {
                    updatedText = updatedText.replacingOccurrences(of: pattern, with: "@"+name)
                }
            }
            
            return userNameText + updatedText
        }
    }
    
    private func getAssertList() -> [String]?{
        let key = "ASSERT_LIST"
        guard let bundleID = Bundle.main.bundleIdentifier, let groupDefaults = UserDefaults(suiteName: "group.\(bundleID)"), let assertList = groupDefaults.array(forKey: key) as? [String] else {
            return nil
        }

        return assertList;
    }
    
    func getDecodeKey(from url: String) -> String? {
        guard !url.isEmpty, url.contains("secret/"), let assertList = self.getAssertList() else {
            return nil
        }
        
        var decodeStr:String?
        
        let pattern = "secret/[^/]+/(\\d+)/"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsRange = NSRange(url.startIndex..., in: url)
            if let match = regex.firstMatch(in: url, options: [], range: nsRange) {
                if let range = Range(match.range(at: 1), in: url) {
                    let result = String(url[range])
                    if let codeIndex = Int(result), codeIndex >= 0 {
                        if assertList.count > codeIndex {
                            decodeStr = assertList[codeIndex]
                            print("decodeStr 下载地址 \(url) 解密密钥位置：\(codeIndex) decodeStr:\(decodeStr ?? "")")
                        }
                    }
                }
            }
        }
        
        return decodeStr
    }
    
    private func xorDecode(inputBytes: [UInt8], key: String) -> Data {
        let keyLen = key.count
        var decodedBytes = [UInt8](repeating: 0, count: inputBytes.count)

        for i in 0..<inputBytes.count {
            decodedBytes[i] = inputBytes[i] ^ key[key.index(key.startIndex, offsetBy: i % keyLen)].utf8.first!
        }
        
        return Data(decodedBytes)
    }
    
    private func syncNotificationStep(_ jpushID: String, _ message : String) {
        guard let groupDefaults = getNotiGroupDefaults() else {
            return
        }
        
        var jPushList = [String]()
        if let list = notificationItem[jpushID] {
            jPushList = list
        }
        
        jPushList.append(message)
        
        var keys =  notificationItem
        if let k = groupDefaults.object(forKey: trackingKey) as? [String: [String]] {
            keys = k
        }
        
        if message.contains("END") {
            keys.removeValue(forKey: jpushID)
        }
        
        keys[jpushID] = jPushList
        notificationItem = keys
        groupDefaults.set(keys, forKey: trackingKey)
    }
    
}


extension String {
    func sha256() -> String {
        let inputData = Data(self.utf8)
        if #available(iOSApplicationExtension 13.0, *) {
            let hashed = SHA256.hash(data: inputData)
            return hashed.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            // Fallback on earlier versions
        }
        return self
    }
    
    var MD5: String {
        let computed = Insecure.MD5.hash(data: self.data(using: .utf8)!)
        return computed.map { String(format: "%02hhx", $0) }.joined()
    }
}

func printAllFiles(at url: URL) {
    let fileManager = FileManager.default
    
    do {
        // 获取指定路径下的所有文件和文件夹
        let items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        
        // 打印每个文件或文件夹的路径
        for item in items {
            print("Found item: \(item.path)")
        }
    } catch {
        SentrySDK.capture(error: error)
        print("Error reading contents of directory: \(error)")
    }
}
