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

@available(iOSApplicationExtension 16.0, *)
class CustomShareViewController: UIViewController {

    let cellID: String = "ChatViewCell"
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleLbl: UILabel!;

    var arrData = NSMutableArray.init()
    
    var exportDatas = NSMutableArray.init()
    
    var chatDataArray: [ChatData] = []
    
    private let spacing:CGFloat = 8.0
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var cancelBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let isChatDataEmpty = !self.loadChatData()
        self.collectionView.isHidden = isChatDataEmpty
        self.cancelBtn.isHidden = isChatDataEmpty
        self.headerView.isHidden = isChatDataEmpty
        self.titleLbl.isHidden = isChatDataEmpty

        if isChatDataEmpty {
            /// Alert dialog will appear if user is not logged in
            if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
                let alertTitle = NSLocalizedString("loginTitle", comment: "Title")
                let alertMessage = String(format: NSLocalizedString("loginContent", comment: "content"), appName)
                let alertButton = NSLocalizedString("loginButton", comment: "button")
                let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: alertButton, style: .default, handler: { _ in
                    self.extensionContext!.cancelRequest(withError: NSError())
                }))
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.1)
            self.headerView.layer.cornerRadius = 10
            self.headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            self.collectionView.layer.cornerRadius = 10
            self.collectionView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            self.cancelBtn.layer.cornerRadius = 10
            self.cancelBtn.setTitle(NSLocalizedString("cancel", comment: "Cancel"), for: .normal)
            self.titleLbl.text = NSLocalizedString("share", comment: "Share")
            let layout: UICollectionViewFlowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.sectionInset = UIEdgeInsets(top: 12, left: spacing, bottom: 12, right: spacing)
            layout.minimumLineSpacing = spacing * 2
            layout.minimumInteritemSpacing = spacing

            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(UINib.init(nibName: self.cellID, bundle: nil), forCellWithReuseIdentifier: cellID)
            collectionView.bounces = true

            self.initData()

            KiwiManager.shared.initKiwi { ip, port in
                self.refreshCollectionView()
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.userInterfaceStyle == .dark {
            self.cancelBtn.backgroundColor = UIColor.systemBackground
        }
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
                                var size = CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))
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
    
    
    func takeImageToMainApp(chat: ChatData) {
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
        ] as [String : Any]
        
        let bundleID = Bundle.main.bundleIdentifier
        let defaults = UserDefaults.init(suiteName: "group.\(bundleID ?? "")")
        defaults?.setValue(dict, forKey: "share_image")
        
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
        self.extensionContext!.cancelRequest(withError: NSError())
    }
}


@available(iOSApplicationExtension 16.0, *)
extension CustomShareViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! ChatViewCell
        
        let chatData = chatDataArray[indexPath.item]
        cell.updateUI(chat: chatData)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.chatDataArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let chatData = chatDataArray[indexPath.item]
        self.takeImageToMainApp(chat: chatData)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsPerRow:CGFloat = 4
        let spacingBetweenCells:CGFloat = 8
        
        let totalSpacing = (2 * self.spacing) + ((numberOfItemsPerRow - 1) * spacingBetweenCells) //Amount of total spacing in a row
        
        if let collection = self.collectionView{
            let ratioCellHW = 94.0 / 73.5
            let width = (collection.bounds.width - totalSpacing)/numberOfItemsPerRow
            return CGSize(width: width, height: width * ratioCellHW)
        }else{
            return CGSize(width: 0, height: 0)
        }
    }
}

