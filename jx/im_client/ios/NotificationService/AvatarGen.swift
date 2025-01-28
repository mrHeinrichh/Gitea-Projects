import Foundation
import UIKit

struct AvatarGen {
    var chatId: Int
    var name: String
    
    let colors: [[String]] = [
        ["ffFE9D7F", "ffF44545"],
        ["ffFFAE7B", "ffF07F38"],
        ["ffFBC87B", "ffFFA800"],
        ["ffAAF490", "ff52D05E"],
        ["ff85A3F9", "ff5D60F6"],
        ["ff7EC2F4", "ff3B90E1"],
        ["ff6BF0F9", "ff1EAECD"],
        ["ffD784FC", "ffB35AD1"],
    ]
    
    func imageFromChat() -> UIImage? {
        let size = CGSize(width: 64, height: 64)
        let scale: CGFloat = 3.0  // 超采样比例 提高画面精度
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let maskV = UIView(frame: CGRect(origin: .zero, size: scaledSize))
//        maskV.layer.cornerRadius = scaledSize.width / 2
//        maskV.layer.masksToBounds = true
        
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 25 * scale, weight: .bold)
        label.text = generateName(from: name)
        label.textAlignment = .center
        label.frame = maskV.bounds
        maskV.addSubview(label)
        
        setGradientBorderWidthColor(circularView: maskV)
        
        if let image = convertViewToImage(view: maskV, scale: scale) {
            return image
        }
        return nil
    }
    
    func colorThemeFromChatId(chatId: Int) -> Int {
        let index: Int = chatId % 8
        return index
    }
    
    func setGradientBorderWidthColor(circularView: UIView) {
        let index: Int = colorThemeFromChatId(chatId: chatId)
        let colors: [String] = self.colors[index]
        
        let shape = CAShapeLayer()
        shape.frame = circularView.bounds
        shape.fillColor = UIColor.red.cgColor
        shape.strokeColor = UIColor.clear.cgColor
        
        let path = UIBezierPath(rect: circularView.bounds)
        shape.path = path.cgPath
        
        let gradient = CAGradientLayer()
        gradient.frame = path.bounds
        gradient.colors = [UIColor(genHexString: colors[0]).cgColor, UIColor(genHexString: colors[1]).cgColor]
        gradient.mask = shape
        
        if circularView.layer.sublayers?.first is CAGradientLayer {
            circularView.layer.sublayers?.remove(at: 0)
        }
        
        circularView.layer.insertSublayer(gradient, at: 0)
    }
    
    func convertViewToImage(view: UIView, scale: CGFloat) -> UIImage? {
        // Create a graphics context with the target size
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, scale)
        defer { UIGraphicsEndImageContext() }
        
        // Render the view's layer to the graphics context
        if let context = UIGraphicsGetCurrentContext() {
            view.layer.render(in: context)
        }
        
        // Retrieve the UIImage from the current context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        return image
    }
    
    func generateName(from nickName: String) -> String {
        // 将nickName按空格拆分成数组
        let parts = nickName.split(separator: " ").map(String.init)
        
        // 取前两个非空部分的首字母，如果某部分为空，则取nickName的首字母
        let initials = parts.prefix(2).map { part in
            return part.isEmpty ? nickName.prefix(1) : part.prefix(1)
        }
        
        // 将所有首字母连接成字符串并转换为大写
        let name = initials.joined().uppercased()
        
        return name
    }
}

extension UIColor {
    convenience init(genHexString: String) {
        let hex = genHexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
