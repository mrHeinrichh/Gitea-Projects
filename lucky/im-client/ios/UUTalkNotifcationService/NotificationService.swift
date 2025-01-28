//
//  NotificationService.swift
//  UUTalkNotifcationService
//
//  Created by Venus Heng on 1/3/24.
//

import UserNotifications
import Intents


@available(iOSApplicationExtension 13.0, *)
class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    var defaults = UserDefaults(suiteName: "group.com.uutalk.im")
    let center = UNUserNotificationCenter.current()
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        var icon : URL?
        
        if let encryptedData = bestAttemptContent?.userInfo["cipher_data"] as? String {
            
            if let decryptedData = DecryptUtils.decryptData(encryptedData: encryptedData) {
                print("Decrypted Data: \(decryptedData)")
                let title = decryptedData["title"] as? String ?? ""
                let body = decryptedData["body"] as? String ?? ""
                icon = URL(string: (decryptedData["icon"] as? String ?? "")) ?? nil
                let notificationType = decryptedData["notification_type"] as? String ?? "0"
                let chatID = decryptedData["chat_id"] as? String ?? "0"
                let transactionID = decryptedData["transaction_id"] as? String ?? ""
                let rtcChannelID = decryptedData["rtc_channel_id"] as? String ?? ""
                let isMissedCall = decryptedData["is_missed_call"] as? String ?? "0"
                let isStopCall = decryptedData["stop_call"] as? String ?? "0"
                let isCancelCall = decryptedData["is_cancel_call"] as? String ?? "0"
                
                bestAttemptContent?.title = title
                bestAttemptContent?.body = body
                bestAttemptContent?.userInfo["notification_type"] = Int(notificationType)
                bestAttemptContent?.userInfo["chat_id"] = Int(chatID)
                bestAttemptContent?.userInfo["transaction_id"] = transactionID
                bestAttemptContent?.userInfo["rtc_channel_id"] = rtcChannelID
                bestAttemptContent?.userInfo["is_missed_call"] = Int(isMissedCall)
                bestAttemptContent?.userInfo["stop_call"] = Int(isStopCall)
                bestAttemptContent?.userInfo["is_cancel_call"] = Int(isCancelCall)
            } else {
                print("Decryption failed")
            }
        } else {
            icon = URL(string: (bestAttemptContent?.userInfo["icon"]) as? String ?? "")
        }
        
            let fromUsername = request.content.title as String
            
            if let iconURL = icon {
                let avatar = INImage(url: iconURL)
                let sender = INPerson(
                    personHandle: .init(value:fromUsername, type: .unknown), nameComponents: nil, displayName: fromUsername, image: avatar, contactIdentifier: nil, customIdentifier: ""
                )
                
                if #available(iOSApplicationExtension 15.0, *) {
                    let intent = INSendMessageIntent(
                        recipients: nil, outgoingMessageType: .outgoingMessageText, content: "tong zhi de nei long", speakableGroupName: nil, conversationIdentifier: "xxxxx", serviceName: nil, sender: sender, attachments: nil
                    )
                    let interaction = INInteraction(intent: intent, response: nil)
                    
                    interaction.direction = .incoming
                    interaction.donate { error in
                        if error != nil {
                            return
                        }
                        
//                        let content = request.content
                        
                        do {
                            let updatedContent =  try self.bestAttemptContent?.updating(from: intent)
                            contentHandler(updatedContent!)
                        } catch {
                        }
                    }
                    
                } else {
                }
            } else {
                return
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
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}
