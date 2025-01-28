//
//  SendNumButton.swift
//  ImagePublish
//
//  Created by griffin on 17/6/24.
//

import Foundation
import UIKit

class SendNumButton: UIButton {
    
    private var textPart: String = ""
    private var numPart: Int = 0
    
    // 初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    // 设置按钮的基本属性
    private func setupButton() {
        setTitleColor(.black, for: .normal)
        backgroundColor = .clear
        contentHorizontalAlignment = .center
        contentVerticalAlignment = .center
        updateTitle()
    }
    
    // 更新按钮标题的方法
    func updateTextAndNumber(text: String, number: Int) {
        self.textPart = text
        self.numPart = number
        updateTitle()
    }
    
    // 创建带圆形背景数字的富文本标题
    private func updateTitle() {
        let attributedTitle = NSMutableAttributedString(string: textPart,attributes: [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: globalConfig.themeMainColor,
            .baselineOffset:3])
        
        if numPart > 0 {
            let numberString = "\(numPart)"
            
            // 创建带圆形背景的数字
            let numberAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.white,
                .backgroundColor: UIColor.red,
                .baselineOffset: 0, // 偏移量，用于调整数字的垂直位置
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .center
                    return style
                }()
            ]
            
            // 计算数字背景的大小
            let numberSize = numberString.size(withAttributes: numberAttributes)
            var backgroundWidth = max(18, numberSize.width + 12)
            if (numberString.count==1){
                backgroundWidth = 18
            }
            let backgroundSize = CGSize(width: backgroundWidth, height: 18)
            
            let circleLayer = CALayer()
            circleLayer.frame = CGRect(origin: .zero, size: backgroundSize)
            circleLayer.backgroundColor = globalConfig.themeMainColor.cgColor
            circleLayer.cornerRadius = backgroundSize.height / 2
            circleLayer.masksToBounds = true
            
            let numberLabel = UILabel(frame: circleLayer.bounds)
            numberLabel.textAlignment = .center
            numberLabel.textColor = .white
            numberLabel.font = UIFont.systemFont(ofSize: 13)
            numberLabel.text = numberString
            
            // 居中显示数字
            let yOffset = (backgroundSize.height - numberSize.height) / 2 - 1
            numberLabel.frame.origin.y += yOffset
            
            circleLayer.addSublayer(numberLabel.layer)
            circleLayer.frame.origin.y += 10
            
            let image = UIGraphicsImageRenderer(size: backgroundSize).image { context in
                circleLayer.render(in: context.cgContext)
            }
            
            let attachment = NSTextAttachment()
            attachment.image = image
            attributedTitle.append(NSAttributedString(attachment: attachment))
        }
        
        // 设置按钮标题
        setAttributedTitle(attributedTitle, for: .normal)
    }
}
