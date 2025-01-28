//
//  HeaderCollectionReusableView.swift
//  ImagePublish
//
//  Created by griffin on 15/6/24.
//

import Foundation
import UIKit
import SnapKit

protocol ShareHeadViewDelegate {
    func didTapSearchBtn(headView:ShareHeadView) -> ()
}

class ShareHeadView: UIView {
    static let reuseIdentifier = "HeaderCollectionReusableView"
    
    var delegate:ShareHeadViewDelegate?
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.text = NSLocalizedString("share", comment: "Share")
        return label
    }()
    
    private let searchBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "share_search"), for: .normal)
        return btn
    }()
    
    var searchBar:UISearchBar!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        addSubview(titleLabel)
        titleLabel.textColor = globalConfig.themeBlackColor
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        addSubview(searchBtn)
        searchBtn.addTarget(self, action: #selector(searchTap), for: .touchUpInside)
        searchBtn.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(56)
        }
        
        searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.showsCancelButton = true
        addSubview(searchBar)
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = globalConfig.themeBlackColor
            textField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("search", comment: "search"),
                                                                 attributes: [NSAttributedString.Key.foregroundColor:globalConfig.themeBlackColor.withAlphaComponent(0.2)])
            textField.leftView = UIImageView(image: UIImage(named: "searchBar"))
            if let clearButton = textField.value(forKey: "clearButton") as? UIButton {
                if let image = clearButton.image(for: .normal) {
                    let tintedImage = image.withRenderingMode(.alwaysTemplate)
                    clearButton.setImage(tintedImage, for: .normal)
                    clearButton.tintColor = globalConfig.themeBlackColor.withAlphaComponent(0.2)
                }
            }
        }
        if let cancelButton = searchBar.value(forKey: "cancelButton") as? UIButton {
            cancelButton.setTitleColor(globalConfig.themeMainColor, for: .normal)
        }
        searchBar.snp.makeConstraints { make in
            make.centerY.left.right.equalToSuperview()
        }
        searchBar.isHidden = true
    }
    
    func configure(text: String) {
        titleLabel.text = text
    }
    func updateUIForKeyboard(){
        searchBtn.isHidden = searchBar.isFirstResponder
        titleLabel.isHidden = searchBar.isFirstResponder
        searchBar.isHidden = !searchBar.isFirstResponder
    }
    @objc func searchTap(){
        self.searchBar.becomeFirstResponder()
        delegate?.didTapSearchBtn(headView: self)
    }
}

