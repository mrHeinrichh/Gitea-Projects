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
    
    var chat: ChatData?
    
    let colors:[[String]] = [
        ["ff8d8d", "ff3838"],
        ["FFB98D", "FF863A"],
        ["FFE0A3)", "FFC453"],
        ["D9FFBC", "7CCB76"],
        ["89ABF9", "6968F6"],
        ["99D8F9", "55A2EC"],
        ["D6A2EE", "C974E6"],
    ]
    
    override func awakeFromNib() {
        super.awakeFromNib()
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

        if let iconUrl = chat.icon {
            if !iconUrl.isEmpty {
                let iconLink = String(format: "http://127.0.0.1:%d/app/api/file-download/download/v2?path=%@&size=128&encrypt=1", KiwiManager.shared.port, iconUrl)
                if let avatarURL = URL(string: iconLink) {
                    maskV.isHidden = true
                    avatarIv.sd_setImage(with: avatarURL)
                    return
                }
            }
        }
        
        maskV.isHidden = false
        wordLbl.text = String(chat.name.prefix(1).uppercased())
    }
    
    func setGradientBorderWidthColor(circularView: UIView){
        let index: Int = colorThemeFromName(name: self.chat?.name ?? "a")
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
        NSLog("jxim======> colorThemeFromName \(index) -- \(String(describing: name.MD5.first?.asciiValue))")
        return index
    }
    
}
