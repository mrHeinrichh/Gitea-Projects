//
//  CustomShareViewController.swift
//  ImagePublish
//
//  Created by 吴文炜 on 2022/6/20.
//

import UIKit
import Social
import AVFoundation
import SVGKit
import SDWebImage
import SnapKit
import Intents

@available(iOSApplicationExtension 16.0, *)
class CustomShareViewController: UIViewController {
    
    let cellID: String = "ChatViewCell"
    
    //    @IBOutlet weak var headerView: UIView!
    //    @IBOutlet weak var titleLbl: UILabel!;
    @IBOutlet weak var containerTop: NSLayoutConstraint!
    
    @IBOutlet weak var containerBottom: NSLayoutConstraint!
    
    
    var topSpace = 0.0
    var bottomSpaceSearch = 0.0
    
    var arrData = NSMutableArray.init()
    
    var exportDatas = NSMutableArray.init()
    
    var chatDataArray: [ChatData] = []
    var chatDataArraySearch: [ChatData] = []
    var chatDataArraySelected: [ChatData] = []
    
    var searchText = ""
    var finalArray: [ChatData] {
        if (searchText.isEmpty){
            return self.chatDataArray
        }else{
            return self.chatDataArraySearch
        }
    }
    
    private let itemSpace:CGFloat = 8.0
    private let lineSpace:CGFloat = 12.0
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var cancelBtn: UIButton!
        
    @IBOutlet weak var headView:ShareHeadView!
    var inputSendView:ShareInputSendView!
    
    let cancelError = NSError(domain: "com.im.imagepulish", code: 1, userInfo: [NSLocalizedDescriptionKey : "User cancelled the request"])

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let v = UIView()
//        view.addSubview(v)
//        v.backgroundColor = .red
//        v.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
                
        let isChatDataEmpty = !self.loadChatData()
        self.collectionView.isHidden = isChatDataEmpty
        self.cancelBtn.isHidden = isChatDataEmpty
        self.cancelBtn.setTitleColor(globalConfig.themeBlackColor, for: .normal)
        self.cancelBtn.setTitleColor(globalConfig.themeBlackColor, for: .highlighted)
        
        if isChatDataEmpty {
            headView.isHidden = true
            /// Alert dialog will appear if user is not logged in
            if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
                let alertTitle = NSLocalizedString("loginTitle", comment: "Title")
                let alertMessage = String(format: NSLocalizedString("loginContent", comment: "content"), appName)
                let okTitle = NSLocalizedString("loginButton", comment: "button")
                let okAction = UIAlertAction(title: okTitle, style: .default, handler: { _ in
                    self.extensionContext!.cancelRequest(withError: self.cancelError)
                })
                let cancelTitle = NSLocalizedString("cancel", comment: "cancel")
                let cancelAction = UIAlertAction(title: cancelTitle, style: .default, handler: { _ in
                    self.extensionContext!.cancelRequest(withError: self.cancelError)
                })
                let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                alertController.view.tintColor = globalConfig.themeMainColor
                
                if let backgroundView = alertController.view.subviews.first?.subviews.first?.subviews.first {
                    backgroundView.backgroundColor = UIColor.white
                }
                alertController.setValue(NSAttributedString(string: alertTitle, attributes: [NSAttributedString.Key.foregroundColor : UIColor.black]), forKey: "attributedTitle")
                alertController.setValue(NSAttributedString(string: alertMessage, attributes: [NSAttributedString.Key.foregroundColor : UIColor.black]), forKey: "attributedMessage")
                
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            self.view.backgroundColor = UIColor.init(hex: "121212",alpha: 0.54)
            self.collectionView.layer.cornerRadius = 12
            self.collectionView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            self.cancelBtn.layer.cornerRadius = 12
            self.cancelBtn.setTitle(NSLocalizedString("cancel", comment: "Cancel"), for: .normal)
            let layout: UICollectionViewFlowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: view.bounds.size.height, right: 16)
            layout.minimumLineSpacing = lineSpace
            layout.minimumInteritemSpacing = itemSpace
            
            collectionView.register(ShareHeadView.self,
                                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                    withReuseIdentifier: ShareHeadView.reuseIdentifier)
            layout.sectionHeadersPinToVisibleBounds = true
            self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
            headView.layer.cornerRadius = 12
            headView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            headView.delegate = self
            headView.searchBar.delegate = self
            headView.backgroundColor = .white
            self.collectionView.backgroundColor = .white
            self.collectionView.bounces = false
            self.collectionView.alwaysBounceVertical = false
            self.collectionView.showsVerticalScrollIndicator = false
            
            let topSpace:CGFloat = view.bounds.size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom - self.cancelBtn.bounds.size.height - 8 - 390 - 60
            self.topSpace = topSpace
            containerTop.constant = topSpace
            self.bottomSpaceSearch = -216 - 125.0 - view.safeAreaInsets.bottom 
            
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(UINib.init(nibName: self.cellID, bundle: nil), forCellWithReuseIdentifier: cellID)
            collectionView.bounces = true
            
            //底部操作栏
            inputSendView = ShareInputSendView()
            inputSendView.textInputView.delegate = self
            inputSendView.sendBtn.addTarget(self, action: #selector(sendTap), for: .touchUpInside)
            self.collectionView.superview!.addSubview(inputSendView)
            inputSendView.snp.makeConstraints { make in
                make.left.bottom.right.equalTo(self.collectionView)
                make.height.greaterThanOrEqualTo(106)
            }
            inputSendView.isHidden = true
            
            self.initData()
            
            KiwiManager.shared.initKiwi { ip, port in
                self.refreshCollectionView()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        //        if traitCollection.userInterfaceStyle == .dark {
        //            self.cancelBtn.backgroundColor = UIColor.systemBackground
        //        }
    }
    
    func initData() {
        exportDatas.removeAllObjects()
        arrData.removeAllObjects()
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            return
        }
        
        if (extensionItem.attachments != nil) {
            exportDatas.addObjects(from: extensionItem.attachments!)
        }
        
        if (exportDatas.count > 0) {
            self.loadItemForTypeIdentifier()
        } else {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }
        
        SDWebImageManager.shared.cacheKeyFilter = SDWebImageCacheKeyFilter.init { (url) -> String? in
            if let queryParam = url.query() {
                return queryParam
            }
            return url.absoluteString
        }
    }
    
    @objc func dismissAlert() {
        // Dismiss the alert dialog here
    }
    
    func loadChatData() -> Bool {
        if  let bundleID = Bundle.main.bundleIdentifier,
            let groupDefaults = UserDefaults(suiteName: "group.\(bundleID)"),
            let data = groupDefaults.string(forKey: "chatList") {
            if let decodedChatData = ChatDataDecoder.decodeArray(from: data) {
                self.chatDataArray = decodedChatData
                
                if let extensionContext = self.extensionContext {
                    if  let intent1 = extensionContext.intent {
                        let rec = intent1 as? INSendMessageIntent
                        let array = rec?.recipients
                        if let person = array?.first as? INPerson ,let customIentifer = person.customIdentifier{
                            if let chat = self.chatDataArray.first(where: { chatdata in
                                return "\(chatdata.chatId)" == customIentifer
                            }){
                                self.chatDataArraySelected.append(chat)
                            }
                        }
                    }
                     
                }
                
                self.refreshCollectionView()
                return !self.chatDataArray.isEmpty // Return false if chat data array is empty
            } else {
                NSLog("Failed to decode ChatData array from JSON string")
            }
        } else {
            NSLog("No value found for encodedChatListKey in UserDefaults")
        }
        return false // Return false if any condition fails
    }
    
    func refreshCollectionView(){
        DispatchQueue.main.async {
            self.inputSendView.updateSendTitle(num: self.chatDataArraySelected.count)
            self.inputSendView.isHidden = self.chatDataArraySelected.count == 0
            self.collectionView.reloadData()
        }
    }
    
    func loadItemForTypeIdentifier() {
        for (_, item) in exportDatas.enumerated() {
            let provider: NSItemProvider = item as! NSItemProvider
            if (provider.hasItemConformingToTypeIdentifier("public.file-url")) {
                NSLog("jxim======> public.file-url")
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil){[weak self] (item, error)  in
                    if error != nil{
                        print(error!)
                        return;
                    }
                    if item is URL{
                        NSLog("jxim======> process as file url")
                        let data = try? Data(contentsOf: item as! URL)
                        if (data != nil) {
                            let fileName = (item as! URL).lastPathComponent
                            let suffix = (item as! URL).pathExtension
                            if (suffix == "mp4" || suffix == "MP4" || suffix == "MOV") {
                                NSLog("jxim======> get suffix = \(suffix)")
                                NSLog("jxim======> get item = \(item.debugDescription)")
                                let videoAsset = AVURLAsset(url: item as! URL)
                                guard let track = videoAsset.tracks(withMediaType: AVMediaType.video).first else { return }
                                let naturalSize = track.naturalSize.applying(track.preferredTransform)
                                let size = CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))
                                let dict = [
                                    "video_nomal_path" : (item as! URL).absoluteString,
                                    "video_to_path" : "",
                                    "video_width": size.width,
                                    "video_height": size.height,
                                    "video_size": videoAsset.fileSize ?? 0,
                                    "video_duration": videoAsset.duration.seconds
                                ]
                                self?.arrData.add(dict)
                            } else {
                                let dict = [
                                    "file_name" : fileName,
                                    "suffix": suffix,
                                    "length": data!.count,
                                    "file_nomal_path" : (item as! URL).absoluteString,
                                    "file_to_path" : "",
                                ] as [String : Any]
                                self?.arrData.add(dict)
                            }
                        }
                    }
                }
            } else if (provider.hasItemConformingToTypeIdentifier("public.image")) {
                NSLog("jxim======> public.image")
                provider.loadItem(forTypeIdentifier: "public.image", options: nil, completionHandler: { item, error in
                    if error != nil{
                        print(error!)
                        return;
                    }
                    
                    if item is URL{
                        let data = try? Data(contentsOf: item as! URL)
                        if (data != nil) {
                            let image: UIImage? = UIImage.init(data: data!)
                            let dict = [
                                "width" : image?.size.width as Any,
                                "height" : image?.size.height as Any,
                                "image_nomal_path" : (item as! URL).absoluteString,
                                "image_to_path" : "",
                            ]
                            self.arrData.add(dict)
                        }
                    } else if (item is UIImage) {
                        NSLog("jxim======> public.image UIImage")
                        let image: UIImage = (item as! UIImage)
                        if let imageUrl: URL = self.saveImageToDocumentDirectory(image) {
                            let dict = [
                                "width" : image.size.width as Any,
                                "height" : image.size.height as Any,
                                "image_nomal_path" : imageUrl.absoluteString,
                                "image_to_path" : "",
                            ]
                            self.arrData.add(dict)
                        }
                    }
                })
            } else if (provider.hasItemConformingToTypeIdentifier("public.movie")) {
                NSLog("jxim======> public.movie")
                provider.loadItem(forTypeIdentifier: "public.movie", options: nil){[weak self] (item,error)  in
                    if error != nil{
                        print(error!)
                        return;
                    }
                    
                    if item is URL{
                        let data = try? Data(contentsOf: item as! URL)
                        if (data != nil) {
                            let videoAsset = AVURLAsset(url: item as! URL)
                            guard let track = videoAsset.tracks(withMediaType: AVMediaType.video).first else { return }
                            let size = track.naturalSize.applying(track.preferredTransform)
                            let dict = [
                                "video_nomal_path" : (item as! URL).absoluteString,
                                "video_to_path" : "",
                                "video_width": size.width,
                                "video_height": size.height,
                                "video_size": videoAsset.fileSize ?? 0,
                                "video_duration": videoAsset.duration.seconds
                            ]
                            self?.arrData.add(dict)
                        }
                    }
                }
            } else if (provider.hasItemConformingToTypeIdentifier("public.url")) {
                NSLog("jxim======> public.url")
                provider.loadItem(forTypeIdentifier: "public.url", options: nil){[weak self] (item, error)  in
                    if error != nil{
                        print(error!)
                        return;
                    }
                    
                    let url = item as? URL
                    if url != nil {
                        let dict = [
                            "web_link" : (item as! URL).absoluteString,
                        ]
                        self?.arrData.add(dict)
                    }
                }
            } else if (provider.hasItemConformingToTypeIdentifier("public.text")) {
                NSLog("jxim======> public.text")
                provider.loadItem(forTypeIdentifier: "public.text", options: nil){[weak self] (item, error)  in
                    if error != nil{
                        print(error!)
                        return;
                    }
                    
                    let text = item as? String
                    if text != nil {
                        let dict = [
                            "text" : text,
                        ]
                        self?.arrData.add(dict)
                    }
                }
            } else {
                NSLog("jxim======> public.data")
                provider.loadItem(forTypeIdentifier: "public.data", options: nil){[weak self] (item,error)  in
                    if error != nil{
                        print(error!)
                        return
                    }
                    
                    NSLog("jxim======> \(type(of: item))|\(item is UIImage)|\(item is NSData)")
                    if item is URL{
                        let data = try? Data(contentsOf: item as! URL)
                        if (data != nil) {
                            let fileName = (item as! URL).lastPathComponent
                            let suffix = (item as! URL).pathExtension
                            let dict = [
                                "file_name" : fileName,
                                "suffix": suffix,
                                "length": data!.count,
                                "file_nomal_path" : (item as! URL).absoluteString,
                                "file_to_path" : "",
                            ] as [String : Any]
                            self?.arrData.add(dict)
                        }
                    }
                }
            }
        }
    }
    
    @objc func sendTap(){
        guard chatDataArraySelected.count > 0 else {
            return
        }
        
        var dicArray:[[String : Any]] = []
        for (_, item) in chatDataArraySelected.enumerated() {
            let dic = dicFromChatData(chat: item)
            dicArray.append(dic)
            
        }
        //倒序添加到推荐联系人 但是实际上没作用 ，推荐联系人的排序是系统决定的
        for (_, item) in chatDataArraySelected.reversed().enumerated() {
            self.addSuggestContact(chat: item)
        }
        
        takeImageToMainApp(dicArray: dicArray)
    }
    
    func dicFromChatData(chat:ChatData) -> [String : Any] {
        let assetArr: NSMutableArray = NSMutableArray.init()
        for (_, item) in self.arrData.enumerated() {
            let itemDict: NSDictionary = item as! NSDictionary
            
            if (itemDict["text"] != nil) {
                assetArr.add([
                    "text": itemDict["text"],
                ])
            } else if(itemDict["web_link"] != nil){
                assetArr.add([
                    "web_link": itemDict["web_link"],
                ])
            }else{
                var pathKey = "image_nomal_path"
                if(itemDict["suffix"] != nil){
                    NSLog("jxim======> image_nomal_path")
                    NSLog("jxim======> \(itemDict["suffix"] ?? "nothing")")
                    pathKey = "file_nomal_path"
                }else if(itemDict["video_nomal_path"] != nil){
                    NSLog("jxim======> video_nomal_path")
                    pathKey = "video_nomal_path"
                }
                
                let rootBundleID = getRootBundle()
                let groupURL: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.\(rootBundleID)")!
                let fileURL: URL = groupURL.appendingPathComponent((itemDict[pathKey] as! NSString).lastPathComponent.removingPercentEncoding!)
                if (FileManager.default.fileExists(atPath: fileURL.path)) { /// must use path instead of absoluteString
                    NSLog("jxim======> existing file removing")
                    do {
                        try FileManager.default.removeItem(atPath: fileURL.path)
                    } catch {
                        NSLog("Error removing existing file: \(error)")
                    }
                }
                let fromRange: NSRange = (itemDict[pathKey] as! NSString).range(of: "/var")
                let fromPath: String = (itemDict[pathKey] as! String).dropFirst(fromRange.location).removingPercentEncoding!
                let toRange: NSRange = (fileURL.absoluteString as NSString).range(of: "/var")
                let toPath: String = fileURL.absoluteString.dropFirst(toRange.location).removingPercentEncoding!
                try? FileManager.default.copyItem(atPath: fromPath, toPath: toPath)
                
                if(itemDict["suffix"] != nil){
                    assetArr.add([
                        "file_name" : itemDict["file_name"],
                        "suffix": itemDict["suffix"],
                        "length": itemDict["length"],
                        "file_nomal_path" : itemDict["file_nomal_path"],
                        "file_to_path" : "/private" + toPath,
                    ])
                }else if(itemDict["video_nomal_path"] != nil){
                    NSLog("jxim======> video file path \(fileURL.absoluteString) and nomal path \(itemDict["video_nomal_path"])")
                    assetArr.add([
                        "video_nomal_path" : itemDict["video_nomal_path"],
                        "video_to_path" : fileURL.absoluteString,
                        "video_width": itemDict["video_width"],
                        "video_height": itemDict["video_height"],
                        "video_size": itemDict["video_size"],
                        "video_duration": itemDict["video_duration"]
                    ])
                }else{
                    assetArr.add([
                        "width" :  itemDict["width"],
                        "height" : itemDict["height"],
                        "image_nomal_path" : itemDict["image_nomal_path"],
                        "image_to_path" : fileURL.absoluteString,
                    ])
                }
            }
        }
        
        let dict = [
            "asset": assetArr,
            "chatId": chat.chatId,
            "caption" : inputSendView.textInputView.textView.text ?? "",
        ] as [String : Any]
        
        return dict
    }
    
    func takeImageToMainApp(dicArray:[[String : Any]]) {
        let bundleID = Bundle.main.bundleIdentifier
        let defaults = UserDefaults.init(suiteName: "group.\(bundleID ?? "")")
        defaults?.setValue(dicArray, forKey: "share_image")
        
        // 跳转到主app
        var responder = self.next
        while responder != nil{
            let sel = Selector("openURL:")
            if responder!.responds(to: sel){
                let rootBundleID = getRootBundle()
                responder!.perform(sel, with: URL(string:"\(rootBundleID)://"))
                break
            }
            responder = responder?.next
        }
        
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    func getRootBundle() -> String {
        let bundleID = Bundle.main.bundleIdentifier
        var keys = bundleID?.components(separatedBy: ".")
        keys?.removeLast()
        let rootBundleID = keys?.joined(separator: ".")
        return rootBundleID ?? ""
    }
    
    func download(url: URL, toFile file: URL, completion: @escaping (Error?) -> Void) {
        // Download the remote URL to a file
        let task = URLSession.shared.downloadTask(with: url) {
            (tempURL, response, error) in
            // Early exit on error
            guard let tempURL = tempURL else {
                completion(error)
                return
            }
            
            do {
                // Remove any existing document at file
                if FileManager.default.fileExists(atPath: file.path) {
                    try FileManager.default.removeItem(at: file)
                }
                
                // Copy the tempURL to file
                try FileManager.default.copyItem(
                    at: tempURL,
                    to: file
                )
                
                completion(nil)
            }
            
            // Handle potential file system errors
            catch let fileError {
                completion(fileError)
            }
        }
        
        // Start the download
        task.resume()
    }
    
    func compressImage(image: UIImage ,maxLength: Int) -> Data {
        // let tempMaxLength: Int = maxLength / 8
        let tempMaxLength: Int = maxLength
        var compression: CGFloat = 1
        guard var data = image.jpegData(compressionQuality: compression), data.count > tempMaxLength else { return image.jpegData(compressionQuality: compression)! }
        
        // 压缩大小
        var max: CGFloat = 1
        var min: CGFloat = 0
        for _ in 0..<6 {
            compression = (max + min) / 2
            data = image.jpegData(compressionQuality: compression)!
            if CGFloat(data.count) < CGFloat(tempMaxLength) * 0.9 {
                min = compression
            } else if data.count > tempMaxLength {
                max = compression
            } else {
                break
            }
        }
        var resultImage: UIImage = UIImage(data: data)!
        if data.count < tempMaxLength { return data }
        
        // 压缩大小
        var lastDataLength: Int = 0
        while data.count > tempMaxLength && data.count != lastDataLength {
            lastDataLength = data.count
            let ratio: CGFloat = CGFloat(tempMaxLength) / CGFloat(data.count)
            print("Ratio =", ratio)
            let size: CGSize = CGSize(width: resultImage.size.width * ratio, height: resultImage.size.height * ratio)
            UIGraphicsBeginImageContext(size)
            resultImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            resultImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            data = resultImage.jpegData(compressionQuality: 0.1)!
        }
        return data
    }
    
    func saveImageToDocumentDirectory(_ chosenImage: UIImage) -> URL? {
        let directoryPath = NSHomeDirectory().appending("/Documents/download/")
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }
        
        let uuid = UUID().uuidString
        let filename = uuid.appending(".jpg")
        let filepath = directoryPath.appending(filename)
        let url = NSURL.fileURL(withPath: filepath)
        do {
            try chosenImage.jpegData(compressionQuality: 1.0)?.write(to: url, options: .atomic)
            return url
        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
        }
        return nil
    }
    
    func thumbnailImageForVideo(videoURL: URL) -> UIImage? {
        let aset = AVURLAsset(url: videoURL, options: nil)
        let assetImg = AVAssetImageGenerator(asset: aset)
        assetImg.appliesPreferredTrackTransform = true
        assetImg.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
        do{
            let cgimgref = try assetImg.copyCGImage(at: CMTime(seconds: 10, preferredTimescale: 50), actualTime: nil)
            return UIImage(cgImage: cgimgref)
        }catch{
            return nil
        }
    }
    
    @IBAction func cancelBtnClicked(_ sender: Any) {
        self.extensionContext!.cancelRequest(withError: cancelError)
    }
    
    func updateUIForKeyboard(show:Bool){
        if (show){
            containerTop.constant = 0
            containerBottom.constant = self.bottomSpaceSearch
            self.view.layoutIfNeeded()
        }else{
            self.containerTop.constant = self.topSpace
            self.containerBottom.constant = 0
            self.view.layoutIfNeeded()
        }
        headView.updateUIForKeyboard()
    }
    
    func getBaseBundleIdentifier() -> String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let components = bundleIdentifier.split(separator: ".")
        guard components.count >= 3 else { return "" }
        return components.prefix(3).joined(separator: ".")
    }
    func addSuggestContact(chat:ChatData){
        let bundleIdentifier = getBaseBundleIdentifier()
        let name = chat.name
        let groupName = INSpeakableString(spokenPhrase: name)
        let recipient = INPerson(personHandle: INPersonHandle(value: name, type: .unknown), nameComponents: nil, displayName: name, image: nil, contactIdentifier: nil, customIdentifier: "\(chat.chatId)")
        let sendMessageIntent = INSendMessageIntent(recipients: [recipient],
                                                    outgoingMessageType: .outgoingMessageText,
                                                    content: "Message content",
                                                    speakableGroupName: groupName,
                                                    conversationIdentifier: "\(bundleIdentifier)_conversation.id_\(chat.chatId)",
                                                    serviceName: nil,
                                                    sender: nil,
                                                    attachments: nil)
        var image = INImage(named: "saved")
        if (chat.icon ?? "").isEmpty {
            if chat.typ == 2 {
                if let imageGen =  AvatarGen(chatId: chat.chatId, name: chat.shortName).imageFromChat() {
                    image = INImage(imageData: imageGen.pngData()!)
                }
            }else if chat.typ == 1 {
                if let imageGen =  AvatarGen(chatId: chat.uid, name: chat.shortName).imageFromChat() {
                    image = INImage(imageData: imageGen.pngData()!)
                }
            }
            sendMessageIntent.setImage(image, forParameterNamed: \.speakableGroupName)

            let interaction = INInteraction(intent: sendMessageIntent, response: nil)
            interaction.direction = .outgoing
            interaction.groupIdentifier = "\(bundleIdentifier)_ImagePublish.suggestContact_\(chat.chatId)"
            interaction.donate(completion: { error in
              DispatchQueue.main.async {
                if error != nil {
                  print("Interaction donate Failure with error: \(error as Any)")
                } else {
                    // Do something, e.g. send the content to a contact.
                  print("Successfully donated interaction")
                }
              }
            })
        }else {
            let iconUrl = chat.icon ?? ""
            let iconLink = String(format: "http://127.0.0.1:%d/app/api/file-download/download/v2?path=%@&size=128&encrypt=1", KiwiManager.shared.port, iconUrl)
            if let avatarURL = URL(string: iconLink) {
                SDWebImageManager.shared.loadImage(with: avatarURL, options:SDWebImageOptions.retryFailed) { (receivedSize, expectedSize, targetURL)in
                } completed: { (imageDownLoad, data, error, cacheType, finished, imageURL)in
                    if finished == true {
                        if let data = imageDownLoad?.pngData() {
                            image = INImage(imageData: data)
                            sendMessageIntent.setImage(image, forParameterNamed: \.speakableGroupName)
                            
                            let interaction = INInteraction(intent: sendMessageIntent, response: nil)
                            interaction.direction = .outgoing
                            interaction.groupIdentifier = "\(bundleIdentifier)_ImagePublish.suggestContact_\(chat.chatId)"
                            interaction.donate(completion: { error in
                                DispatchQueue.main.async {
                                    if error != nil {
                                        print("Interaction donate Failure with error: \(error as Any)")
                                    } else {
                                        // Do something, e.g. send the content to a contact.
                                        print("Successfully donated interaction")
                                    }
                                }
                            })
                        }
                    }
                }
            }
            
        }
        
    }
}


@available(iOSApplicationExtension 16.0, *)
extension CustomShareViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! ChatViewCell
        
        let chatData = finalArray[indexPath.item]
        cell.updateUI(chat: chatData)
        cell.setSelectUI(select: chatDataArraySelected.contains(where: {$0.chatId == chatData.chatId}))
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return finalArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let chatData = finalArray[indexPath.item]
        if let index = chatDataArraySelected.firstIndex(where: {$0.chatId == chatData.chatId}) {
            chatDataArraySelected.remove(at: index)
        }else{
            chatDataArraySelected.append(chatData)
        }
        inputSendView.updateSendTitle(num: chatDataArraySelected.count)
        
        collectionView.reloadData()
        inputSendView.isHidden = chatDataArraySelected.count == 0
        if (inputSendView.isHidden) {
            inputSendView.resignFirstResponder()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsPerRow:CGFloat = 4
        let spacingBetweenCells:CGFloat = 8
        
        let totalSpacing = 16 + 16 + ((numberOfItemsPerRow - 1) * spacingBetweenCells) //Amount of total spacing in a row
        
        if let collection = self.collectionView{
            //            let ratioCellHW = 94.0 / 73.5
            let width = (collection.bounds.width - totalSpacing)/numberOfItemsPerRow
            return CGSize(width: width, height: 90)
        }else{
            return CGSize(width: 0, height: 0)
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
extension CustomShareViewController : ShareHeadViewDelegate {
    func didTapSearchBtn(headView: ShareHeadView) {
        updateUIForKeyboard(show: true)
    }
}

@available(iOSApplicationExtension 16.0, *)
extension CustomShareViewController:UISearchBarDelegate {
    // Called when the search button is clicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    }
    
    // Called when the cancel button is clicked
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("Cancel button clicked")
        
        // 清空搜索文本
        searchBar.text = ""
        
        // 收起键盘
        searchBar.resignFirstResponder()
        updateUIForKeyboard(show: false)
        
        searchText = ""
        collectionView.reloadData()
    }
    
    // Called when the text changes
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        
        let section = 0
        let itemCount = collectionView.numberOfItems(inSection: section)
        var indexPathsToReload = [IndexPath]()
        for item in 0..<itemCount {
            indexPathsToReload.append(IndexPath(item: item, section: section))
        }
        
        if (!searchText.isEmpty){
            self.chatDataArraySearch.removeAll()
            let array = self.chatDataArray.filter({ item in
                return item.name.lowercased().contains(searchText.lowercased())
            })
            self.chatDataArraySearch.append(contentsOf:array)
        }
        
        collectionView.reloadData()
    }
}

@available(iOSApplicationExtension 16.0, *)
extension CustomShareViewController:AutoResizingTextViewDelegate{
    func autoResizingTextViewDidBegin() {
        updateUIForKeyboard(show: true)
    }
    func autoResizingTextViewDidEnd() {
        updateUIForKeyboard(show: false)
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        hexFormatted = hexFormatted.replacingOccurrences(of: "#", with: "")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

