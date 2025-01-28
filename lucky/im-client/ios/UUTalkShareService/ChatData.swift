//
//  ChatData.swift
//  ImagePublish
//
//  Created by Venus Heng on 9/1/24.
//

import Foundation

struct ChatData: Decodable {
    let chatId: Int
    let icon: String?
    let name: String
    let isSingle: Bool
}

struct ChatDataDecoder {
    static func decodeArray(from jsonString: String) -> [ChatData]? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }

        do {
            let chatDataArray = try JSONDecoder().decode([ChatData].self, from: jsonData)
            return chatDataArray
        } catch {
            NSLog("error decoding \(error)")
            return nil
        }
    }
}
