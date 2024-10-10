import Foundation
import UserNotifications

class LocalCallNotificationManager {
    
    static let shared = LocalCallNotificationManager()
    
    private var notificationQueue: DispatchQueue?
    private var autoStopWorkItem: DispatchWorkItem?
    private var notificationIdentifier: String?
    private var shouldStopNotifications = false
    
    var userInfo: [AnyHashable: Any] = [:]
    
    private init() {
        notificationQueue = DispatchQueue(label: "com.example.notificationQueue")
    }
    
    /// 开始响铃
    func startNotification() {
        /*
        let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Unknown"
        print(appName)
        
        stopNotifications()  // 先停止之前的通知和计时器
        shouldStopNotifications = false
        startRepeatingNotifications()
        autoCancel()
         */
    }

    /// 停止所有的
    func stopNotifications() {
        /*
        shouldStopNotifications = true
        
        // 取消正在进行的通知
        if let identifier = notificationIdentifier {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            notificationIdentifier = nil
            print("Notification with identifier \(identifier) cancelled.")
        }
        
        // 取消正在进行的自动停止任务
        autoStopWorkItem?.cancel()
        autoStopWorkItem = nil
        
        // 取消所有通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        print("All notifications and timers stopped.")
         */
    }
    
    private func startRepeatingNotifications() {
        notificationQueue?.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            guard let self = self else { return }
            if self.shouldStopNotifications { return } // 检查是否应该停止
            self.triggerLocalNotification()
            self.startRepeatingNotifications() // 重新启动任务
        }
    }

    private func triggerLocalNotification() {
        
        
            var icon : URL?
            var useAvatarGen = false
            var chatIdInt = 0
            var titleLater = ""
            var uidInt:Int?
            
            if let encryptedData = userInfo["cipher_data"] as? String {
                NSLog("FCMService:======> didReceive 2")
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

                    
                    
                } else {
                    print("Decryption failed")
                }
            } else {
                icon = URL(string: (userInfo["icon"]) as? String ?? "")
            }
            
            
            if let icon = icon {
                if (icon.absoluteString.contains("GroupImg.png") || icon.absoluteString.contains("person.png")){
                    useAvatarGen = true
                }
            }else{
                useAvatarGen = true
            }
            
            
        
        
        // 取消上一次通知
        if let identifier = notificationIdentifier {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        
        // 从 UserDefaults 获取数据
           let title = UserDefaults.standard.string(forKey: "notification-title") ?? "Default Title"
           let body = UserDefaults.standard.string(forKey: "notification-body") ?? "Default Body"
           let iconUrlString = UserDefaults.standard.string(forKey: "notification-icon-url")
           
           let content = UNMutableNotificationContent()
           content.title = title
           content.body = body
//        content.body = "☎️Incoming Call"
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName("callShort.caf"))
    
        // 如果有头像 URL，则添加附件
        if let iconUrlString = iconUrlString, let iconUrl = URL(string: iconUrlString) {
            downloadImage(from: iconUrl) {image in
                if let image = image, let imageData = image.pngData() {
                    do {
                        let attachment = try UNNotificationAttachment(identifier: UUID().uuidString, url: self.saveImageToTemporaryDirectory(imageData: imageData), options: nil)
                        content.attachments = [attachment]
                    } catch {
                        print("Error creating notification attachment: \(error)")
                    }
                }
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error adding notification: \(error)")
                    }
                }
            }
        } else {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error adding notification: \(error)")
                }
            }
        }

        notificationIdentifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: notificationIdentifier!, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error)")
            }
        }
    }
    
    private func autoCancel() {
        // 启动一个60秒的后台任务来取消通知
        autoStopWorkItem?.cancel() // 取消之前的后台任务（如果有的话）
        autoStopWorkItem = DispatchWorkItem { [weak self] in
            self?.stopNotifications()
        }
        if let workItem = autoStopWorkItem {
            DispatchQueue.global().asyncAfter(deadline: .now() + 60.0, execute: workItem)
        }
    }
    
    func saveImageToTemporaryDirectory(imageData: Data) -> URL {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        do {
            try imageData.write(to: fileURL)
        } catch {
            print("Error saving image: \(error)")
        }
        return fileURL
    }

    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
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
