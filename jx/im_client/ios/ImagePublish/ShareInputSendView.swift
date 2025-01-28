//
//  ShareInputSendView.swift
//  ImagePublish
//
//  Created by griffin on 15/6/24.
//

import Foundation
import UIKit
import SnapKit

class ShareInputSendView: UIView {
    
    let sendBtn = SendNumButton()
    let textInputView = AutoResizingTextView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 12
        self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        addSubview(sendBtn)
        sendBtn.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(54)
        }
        updateSendTitle(num: 0)
        
        let textBg = UIView()
        textBg.backgroundColor = globalConfig.themeBlackColor.withAlphaComponent(0.03)
        textBg.layer.cornerRadius = 10
        textBg.layer.masksToBounds = true
        addSubview(textBg)
        
        addSubview(textInputView)
        textInputView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalTo(sendBtn.snp.top)
        }
        
        textBg.snp.makeConstraints { make in
            make.edges.equalTo(textInputView)
        }
        
        let line = UIView()
        line.backgroundColor = globalConfig.themeBlackColor.withAlphaComponent(0.2)
        addSubview(line)
        line.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.3)
        }
    }
    
    func updateSendTitle(num:Int){
        let titleString = NSLocalizedString("send", comment: "send")
        sendBtn.updateTextAndNumber(text: titleString, number: num)
    }
}

protocol AutoResizingTextViewDelegate {
    func autoResizingTextViewDidBegin() -> ()
    func autoResizingTextViewDidEnd() -> ()
}

class AutoResizingTextView: UIView, UITextViewDelegate {
    
    private let maxHeight: CGFloat = 72
    private let minHeight: CGFloat = 44
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.textColor = globalConfig.themeBlackColor
        textView.returnKeyType = .done
        return textView
    }()
    
    let tipLabel = UILabel()
    let clearBtn = UIButton()
    var delegate:AutoResizingTextViewDelegate? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        tipLabel.font = UIFont.systemFont(ofSize: 16)
        tipLabel.textColor = globalConfig.themeBlackColor.withAlphaComponent(0.48)
        tipLabel.text = NSLocalizedString("comment", comment: "comment")
        self.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        self.addSubview(textView)
        textView.delegate = self
        
        textView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-42)
            make.height.equalTo(minHeight)
        }
        
        clearBtn.setImage(UIImage(named: "clear"), for: .normal)
        clearBtn.addTarget(self, action: #selector(clearTap), for: .touchUpInside)
        addSubview(clearBtn)
        clearBtn.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.width.height.equalTo(42)
        }
        clearBtn.isHidden = true
        
        self.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
    }
    @objc func clearTap(){
        textView.text = ""
        textView.isScrollEnabled = false
        adjustTextViewHeight()
        
        tipLabel.isHidden = false
        clearBtn.isHidden = true
    }
    func textViewDidChange(_ textView: UITextView) {
        adjustTextViewHeight()
        
        textView.isScrollEnabled = textView.frame.height == maxHeight
        tipLabel.isHidden = textView.text.count > 0
        clearBtn.isHidden = textView.text.count == 0
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.autoResizingTextViewDidBegin()
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" { // 检测到换行符
            textView.resignFirstResponder() // 隐藏键盘
            delegate?.autoResizingTextViewDidEnd()
            return false // 不插入换行符
        }
        return true
    }
    
    private func adjustTextViewHeight() {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = min(max(size.height, minHeight), maxHeight)
        
        if newHeight != textView.frame.height {
            textView.snp.remakeConstraints { make in
                make.left.top.bottom.equalToSuperview()
                make.right.equalToSuperview().offset(-42)
                make.height.equalTo(newHeight)
            }
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        }
    }
}
