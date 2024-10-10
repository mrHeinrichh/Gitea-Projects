//
//  ChatViewCell.swift
//  ImagePublish
//
//  Created by Venus Heng on 9/1/24.
//

import UIKit
import SDWebImage

class ChatViewCell: UICollectionViewCell {

    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var avatarIv: UIImageView!
    @IBOutlet weak var maskV: UIView!
    @IBOutlet weak var wordLbl: UILabel!
    
    @IBOutlet weak var selectMask: UIView!
    
    var chat: ChatData?
    
    let colors:[[String]] = [
        ["ffFE9D7F", "ffF44545"],
        ["ffFFAE7B", "ffF07F38"],
        ["ffFBC87B", "ffFFA800"],
        ["ffAAF490", "ff52D05E"],
        ["ff85A3F9", "ff5D60F6"],
        ["ff7EC2F4", "ff3B90E1"],
        ["ff6BF0F9", "ff1EAECD"],
        ["ffD784FC", "ffB35AD1"],
    ]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        nameLbl.textColor = globalConfig.themeBlackColor
        wordLbl.textColor = .white
        wordLbl.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        if let circle = self.selectMask.viewWithTag(99) {
            //蓝圈
            circle.layer.cornerRadius = 30
            circle.layer.masksToBounds = true
            circle.layer.borderWidth = 2
            circle.layer.borderColor = globalConfig.themeMainColor.cgColor
            //白圈
            if let whiteCircle = circle.viewWithTag(88) {
                whiteCircle.layer.cornerRadius = 28
                whiteCircle.layer.masksToBounds = true
                whiteCircle.layer.borderWidth = 1
                whiteCircle.layer.borderColor = UIColor.white.cgColor
            }
        }
        self.selectMask.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        adjustUI()
    }
    
    func adjustUI() {
        avatarIv.layer.cornerRadius = avatarIv.bounds.width / 2
        avatarIv.clipsToBounds = true
        maskV.layer.cornerRadius = maskV.bounds.width / 2
        if(!maskV.isHidden){
            setGradientBorderWidthColor(circularView: maskV)
        }
    }
    
    func updateUI(chat: ChatData) {
        self.chat = chat
        
        nameLbl.text = chat.name
        
        if chat.typ == 3 {
            avatarIv.image=UIImage(named: "saved.png")
            maskV.isHidden = true
            wordLbl.text = ""
        }else{
            if let iconUrl = chat.icon {
                if !iconUrl.isEmpty {
                    let iconLink = String(format: "http://127.0.0.1:%d/app/api/file-download/download/v2?path=%@&size=128&encrypt=1", KiwiManager.shared.port, iconUrl)
                    if let avatarURL = URL(string: iconLink) {
                        maskV.isHidden = true
                        avatarIv.sd_imageIndicator = SDWebImageActivityIndicator.gray
                        avatarIv.sd_imageIndicator?.startAnimatingIndicator()
                        avatarIv.sd_setImage(with: avatarURL) { image, error, cacheType, url in
                            NSLog("sd_setImage=========> \(cacheType)")
                        }
                        return
                    }
                }
            }
            maskV.isHidden = false
            wordLbl.text = chat.shortName
        }    
    }
    
    func setSelectUI(select:Bool){
        self.selectMask.isHidden = !select
    }
    
    func setGradientBorderWidthColor(circularView: UIView){
        let index: Int = colorThemeFromChatId(chatId: self.chat?.uid ?? 0)
        let colors: [String] = colors[index]
            
        let shape = CAShapeLayer()
        shape.frame = self.bounds
        shape.fillColor = UIColor.red.cgColor
        shape.strokeColor = UIColor.clear.cgColor
    
        let path = UIBezierPath(roundedRect: circularView.bounds, cornerRadius: circularView.bounds.width / 2)
        shape.path = path.cgPath
    
        let gradient = CAGradientLayer()
        gradient.frame = path.bounds
        gradient.colors = [UIColor(hexString: colors[0]).cgColor, UIColor(hexString: colors[1]).cgColor]
        gradient.mask = shape
        
        if(circularView.layer.sublayers?.first is CAGradientLayer){
            circularView.layer.sublayers?.remove(at: 0)
        }
        
        circularView.layer.insertSublayer(gradient, at: 0)
    }
    
    func colorThemeFromName(name: String) -> Int{
        let index: Int = Int(name.MD5.first?.asciiValue ?? 0) % 7
        return index
    }
    
    func colorThemeFromChatId(chatId: Int) -> Int{
        let index: Int = chatId % 8
        return index
    }
}
