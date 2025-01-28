//
//  CustomAPIParam.swift
//  test_verify_ios
//
//  Created by YUN WAH LEE on 3/2/23.
//

import Foundation

struct API1ResponseData: Codable {
    var gt: String
    var challenge: String
    var success: Int
    var new_captcha: Bool?
}

struct API1Response: Codable {
    let code: Int
    let message: String
    let data: API1ResponseData
}

struct API2ResponseData: Codable {
    let result: String
    let version: String
    let msg: String
}

struct API2Response: Codable {
    let code: Int
    let message: String
    let data: API2ResponseData
}

