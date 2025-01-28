//
//  File.swift
//  Runner
//
//  Created by ekoo on 13/10/23.
//

import Foundation

import UIKit
import CallKit

final class CallHelper: NSObject {
    
    enum CallState: String {
        case start = "startCall"
        case end = "endCall"
        case hold = "holdCall"
    }

    let callController = CXCallController()

    // MARK: Actions

    func startCall(handle: String, video: Bool = false) {
        let handle = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)

        startCallAction.isVideo = video

        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        
        requestTransaction(transaction, action: CallState.start.rawValue)
    }

    func end(uuid: UUID) {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)

        requestTransaction(transaction, action: CallState.end.rawValue)
    }

    func setHeld(uuid: UUID, onHold: Bool) {
        let setHeldCallAction = CXSetHeldCallAction(call: uuid, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)

        requestTransaction(transaction, action: CallState.hold.rawValue)
    }

    private func requestTransaction(_ transaction: CXTransaction, action: String = "") {
        callController.request(transaction) { error in
            if let error = error {
                print("Error requesting transaction: \(error)")
            } else {
                print("Requested transaction \(action) successfully")
            }
        }
    }
    
    private(set) var calls = [String: Call]()
    
    func getCallByKey(key: String) -> Call? {
        guard let call = calls[key] else {
            return nil
        }
        
        return call
    }

    func callWithUUID(uuid: UUID) -> Call? {
        guard let call = calls.values.first(where: { $0.uuid == uuid }) else {
            return nil
        }
        return call
    }

    func addCall(_ callKey: String, _ call: Call) {
        calls[callKey] = call

        call.stateDidChange = { [weak self] in
            
        }
    }

    func removeCall(_ callKey: String) {
        calls.removeValue(forKey: callKey)
    }

    func removeAllCalls() {
        calls.removeAll()
    }
}

struct JVoIP: Decodable {
    let extras: Extra
}

struct Aps: Decodable {
    let extra: Extra
}

struct Extra: Decodable {
    let caller: String?
    let chat_id: Int
    let rtc_channel_id: String
    let icon: String?
    let notification_type: Int?
    let video_call: Int
    let sender_id: Int?
    
    init(chat_id: Int, rtc_channel_id: String, video_call: Int = 0) {
        self.chat_id = chat_id
        self.rtc_channel_id = rtc_channel_id
        self.caller = nil
        self.icon = nil
        self.notification_type = nil
        self.video_call = video_call
        self.sender_id = nil
    }
}
