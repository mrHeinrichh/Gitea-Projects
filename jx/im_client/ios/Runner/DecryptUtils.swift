//
//  DecryptUtils.swift
//  Runner
//
//  Created by YUN WAH LEE on 6/12/23.
//

import Foundation
import CryptoKit
import Sentry
import CryptoSwift

@available(iOSApplicationExtension 13.0, *)
class DecryptUtils {
    
    public static func decryptData(encryptedData: String?) -> [String: Any]? {
        var dataMap: [String: Any]? = nil
        
        if let encryptedData = encryptedData,
           let decodedData = Data(base64Encoded: encryptedData) {
            do {
                if let decryptedData = try aesDecryption(encryptedData: decodedData) {
                    if let decryptedString = String(data: decryptedData, encoding: .utf8),
                       let jsonData = decryptedString.data(using: .utf8),
                       let jsonMap = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                        dataMap = jsonMap
                    }
                }
            } catch {
                print("DecryptUtils Error: \(error)")
                SentrySDK.capture(error: error)
            }
        }
        
        return dataMap
    }
    
    public static func decryptDataWithKey(encryptedData: String?, key : String) -> [String: Any]? {
        if let encryptedData = encryptedData,
           let decodedData = Data(base64Encoded: encryptedData) {
            do {
                if let decryptedData = try aesDecryption(encryptedData: decodedData, key: key) {
                    if let decryptedString = String(data: decryptedData, encoding: .utf8), let jsonData = decryptedString.data(using: .utf8), let jsonMap = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]{
                        return jsonMap
                    }
                }
            } catch {
                print("DecryptUtils Error: \(error)")
            }
        }
        
        return nil
    }

    private static func aesDecryption(encryptedData: Data) throws -> Data? {
        let secretKey = "468171c825c02408cc99935447c785a5"
        print("Secret :: \(secretKey)")
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: SymmetricKey(data: secretKey.data(using: .utf8)!))
            
            return Data(decryptedData)
        } catch {
            print("AES decryption error: \(error)")
            SentrySDK.capture(error: error)
            throw error
        }
    }
    
    private static func aesDecryption(encryptedData: Data, key: String) throws -> Data? {
        let secretKey = key
        print("Secret :: \(secretKey)")
        do {
            
            let zeroArray = [UInt8](repeating: 0, count: 16)
            let k = key.data(using: .utf8)!
            
            let uint8Array: [UInt8] = Array(encryptedData)
            
            let ctr = CTR(iv: zeroArray, counter: 0)
            let aes = try AES(key: k.bytes, blockMode: ctr)
            let decryptedData = try aes.decrypt(uint8Array)
            return Data(decryptedData)
        } catch {
            print("AES decryption error: \(error)")
            SentrySDK.capture(error: error)
            throw error
        }
    }
}


enum AESDecryptionError: Error {
    case keySizeError
    case ivSizeError
    case decryptionFailed
}
