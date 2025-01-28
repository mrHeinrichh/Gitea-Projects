//
//  String+utils.swift
//  ImagePublish
//
//  Created by Venus Heng on 18/1/24.
//

import Foundation
import CryptoKit

extension String {
    var MD5: String {
            let computed = Insecure.MD5.hash(data: self.data(using: .utf8)!)
            return computed.map { String(format: "%02hhx", $0) }.joined()
        }
    
    var localized: String {
            return NSLocalizedString(self, comment: "")
        }
    
    var firstCharacterIsEmoji: Bool {
        guard let firstCharacter = self.first else { return false }
        return firstCharacter.isEmoji
    }
    
}

extension Character {
    var isEmoji: Bool {
        let scalarValues = self.unicodeScalars
        return scalarValues.contains { $0.properties.isEmoji }
    }
}
