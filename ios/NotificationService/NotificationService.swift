//
//  NotificationService.swift
//  NotificationService
//k
//  Created by fang on 2022/4/11.
//

import UserNotifications
import Intents
import UIKit


@available(iOSApplicationExtension 13.0, *)
class NotificationService: UNNotificationServiceExtension {
    private let channelIDKey = "channelIDKey"
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    let center = UNUserNotificationCenter.current()
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        NSLog("FCMService======> didReceive 1")
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        var icon : URL?
        var useAvatarGen = false
        var chatIdInt = 0
        var titleLater = ""
        var uidInt:Int?
        
        if let encryptedData = bestAttemptContent?.userInfo["cipher_data"] as? String {
            NSLog("FCMService======> didReceive 2")
            if let decryptedData = DecryptUtils.decryptData(encryptedData: encryptedData) {
                let title = decryptedData["title"] as? String ?? "Hey"
                let body = decryptedData["body"] as? String ?? "Hey"
                
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
                
                bestAttemptContent?.title = title
                bestAttemptContent?.body = body
                bestAttemptContent?.userInfo["notification_type"] = Int(notificationType)
                bestAttemptContent?.userInfo["chat_id"] = Int(chatID)
                bestAttemptContent?.userInfo["transaction_id"] = transactionID
                bestAttemptContent?.userInfo["rtc_channel_id"] = rtcChannelID
                bestAttemptContent?.userInfo["is_missed_call"] = Int(isMissedCall)
                bestAttemptContent?.userInfo["stop_call"] = Int(isStopCall)
                bestAttemptContent?.userInfo["is_cancel_call"] = Int(isCancelCall)
                bestAttemptContent?.userInfo["delete_id"] = deleteID
                
                let url = URL(fileURLWithPath: sound)
                sound = url.lastPathComponent
                
                if (sound.contains("empty.mp3")){
                    bestAttemptContent?.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "empty.mp3"))
                } else {
                    bestAttemptContent?.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "noti_"+sound))
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
                        
                        bestAttemptContent?.body = replacedString
                    }
                }
                
                titleLater = title
            } else {
                print("Decryption failed")
            }
        } else {
            icon = URL(string: (bestAttemptContent?.userInfo["icon"]) as? String ?? "")
            if let userInfo = bestAttemptContent?.userInfo,
               let aps = userInfo["aps"] as? [String: Any],
               let alert = aps["alert"] as? [String: Any],
               let title = alert["title"] as? String {
                titleLater = title
            }
            uidInt = bestAttemptContent?.userInfo["sender_id"] as? Int
            chatIdInt = bestAttemptContent?.userInfo["chat_id"] as? Int ?? 0
            
            // 取消那些不支持CallKit的地区的通话通知
            if let userInfo = bestAttemptContent?.userInfo,
               let rtcChannelId = userInfo["rtc_channel_id"] as? String,
               let notificationType = bestAttemptContent?.userInfo["notification_type"] as? Int{
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
                    self.bestAttemptContent?.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "u_call.mp3"))
                    let cancelChannelIds = self.loadChannelIDList()
                    
                    // 当对方取消通话时的通知快于来电通知时
                    if(cancelChannelIds.contains(rtcChannelId)){
                        if let bestAttemptContent = self.bestAttemptContent {
                            contentHandler(bestAttemptContent)
                            
                            if let channelId = bestAttemptContent.userInfo["rtc_channel_id"] as? String {
                                self.removeActiveCallNotifications(rtcChannelId: channelId)
                            }
                        }
                        
                        return
                    }
                }
            }
        }
        
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
        DispatchQueue.main.async {
            let imageGen = useAvatarGen ? AvatarGen(chatId: uidInt ?? chatIdInt, name: titleLater).imageFromChat() : nil
            let pngDataGen = imageGen?.pngData()
            DispatchQueue.global().async {//异步线程
                if #available(iOSApplicationExtension 15.0, *) {
                    let sender = INPerson(
                        personHandle: .init(value: fromUsername, type: .unknown), nameComponents: nil, displayName: fromUsername, image: nil, contactIdentifier: nil, customIdentifier: ""
                    )
                    
                    let intent = INSendMessageIntent(
                        recipients: nil, outgoingMessageType: .outgoingMessageText, content: "tong zhi de nei long", speakableGroupName: nil, conversationIdentifier: "xxxxx", serviceName: nil, sender: sender, attachments: nil
                    )
                    let interaction = INInteraction(intent: intent, response: nil)
                    
                    interaction.direction = .incoming
                    interaction.donate { error in
                        if let error = error {
                            print("Donation failed: \(error.localizedDescription)")
                            return
                        }
                        
                        if (useAvatarGen && pngDataGen != nil){
                            let updatedSender = INPerson(
                                personHandle: .init(value: fromUsername, type: .unknown), nameComponents: nil, displayName: fromUsername, image: INImage(imageData: pngDataGen!), contactIdentifier: nil, customIdentifier: ""
                            )
                            let updatedIntent = INSendMessageIntent(
                                recipients: intent.recipients,
                                outgoingMessageType: intent.outgoingMessageType,
                                content: intent.content,
                                speakableGroupName: intent.speakableGroupName,
                                conversationIdentifier: intent.conversationIdentifier,
                                serviceName: intent.serviceName,
                                sender: updatedSender,
                                attachments: intent.attachments
                            )
                            
                            do {
                                let updatedContent = try self.bestAttemptContent?.updating(from: updatedIntent)
                                contentHandler(updatedContent!)
                            } catch {
                                print("Failed to update content: \(error.localizedDescription)")
                            }
                            return
                        }
                        
                        if let iconURL = icon {
                            self.downloadImage(from: iconURL) { image in
                                if let image = image {
                                    let updatedSender = INPerson(
                                        personHandle: .init(value: fromUsername, type: .unknown), nameComponents: nil, displayName: fromUsername, image: INImage(imageData: image.pngData()!), contactIdentifier: nil, customIdentifier: ""
                                    )
                                    let updatedIntent = INSendMessageIntent(
                                        recipients: intent.recipients,
                                        outgoingMessageType: intent.outgoingMessageType,
                                        content: intent.content,
                                        speakableGroupName: intent.speakableGroupName,
                                        conversationIdentifier: intent.conversationIdentifier,
                                        serviceName: intent.serviceName,
                                        sender: updatedSender,
                                        attachments: intent.attachments
                                    )
                                    
                                    do {
                                        let updatedContent = try self.bestAttemptContent?.updating(from: updatedIntent)
                                        contentHandler(updatedContent!)
                                    } catch {
                                        print("Failed to update content: \(error.localizedDescription)")
                                    }
                                } else {
                                    if let bestAttemptContent = self.bestAttemptContent {
                                        contentHandler(bestAttemptContent)
                                    }
                                }
                            }
                        } else {
                            if let bestAttemptContent = self.bestAttemptContent {
                                contentHandler(bestAttemptContent)
                            }
                        }
                    }
                } else {
                    if let bestAttemptContent = self.bestAttemptContent {
                        contentHandler(bestAttemptContent)
                    }
                }
            }
        }
    }
    
    func saveChannelIDList(_ channelIDList: [String]) {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(channelIDList)
            UserDefaults.standard.set(encodedData, forKey: channelIDKey)
            UserDefaults.standard.synchronize()
        } catch {
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
            contentHandler(bestAttemptContent)
            
            if let channelId = bestAttemptContent.userInfo["rtc_channel_id"] as? String {
                self.removeActiveCallNotifications(rtcChannelId: channelId)
            }
        }
    }
    
    func saveFileToTemporaryDirectory(imageData: Data, savePath: String) {
        // 获取临时目录路径
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        
        // 生成要保存的文件URL
        let fileURL = temporaryDirectoryURL.appendingPathComponent(savePath)
        
        do {
            try imageData.write(to: fileURL)
        } catch {
        }
    }
    
    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Image download failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("No valid data to store for image")
                completion(nil)
                return
            }
            completion(image)
        }
        task.resume()
    }
}

