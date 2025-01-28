//
//  VerifyAsynTask.swift
//  test_verify_ios
//
//  Created by YUN WAH LEE on 3/2/23.
//

import GT3Captcha

class VerifyAsyncTask: NSObject{

    var api1: String?
    var api2: String?

    private var validateTask: URLSessionDataTask?
    private var registerTask: URLSessionDataTask?

}

extension VerifyAsyncTask : GT3AsyncTaskProtocol {

    func executeRegisterTask(completion: @escaping (GT3RegisterParameter?, GT3Error?) -> Void) {
        /**
         *  解析和配置验证参数
         */
        guard let api1 = self.api1,
              let url = URL(string: "\(api1)?t=\(Date().timeIntervalSince1970)") else {
            print("invalid api1 address")
            let gt3Error = GT3Error(domainType: .extern, code: -9999, withGTDesciption: "Invalid API1 address.")
            completion(nil, gt3Error)
            return
        }


        let dataTask = URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in

            if let error = error {
                let gt3Error = GT3Error(domainType: .extern, originalError: error, withGTDesciption: "Request API2 fail.")
                completion(nil , gt3Error)
                return
            }

            guard let data = data,
                let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                let gt3Error = GT3Error(domainType: .extern, code: -9999, withGTDesciption: "Invalid API2 response.")
                completion(nil , gt3Error)
                return
            }

            do {
                      let decoder = JSONDecoder()
                      let api1Response = try decoder.decode(API1Response.self, from: data)
                      let registerParameter = GT3RegisterParameter()
                      registerParameter.gt = api1Response.data.gt
                      registerParameter.challenge = api1Response.data.challenge
                      registerParameter.success = NSNumber(value: api1Response.data.success)
                      completion(registerParameter, nil)
                  } catch {
                      let gt3Error = GT3Error(domainType: .extern, originalError: error, withGTDesciption: "Failed to parse API1 response JSON.")
                      completion(nil, gt3Error)
                  }
        }
        dataTask.resume()
        self.registerTask = dataTask
    }

    func executeValidationTask(withValidate param: GT3ValidationParam, completion: @escaping (Bool, GT3Error?) -> Void) {

        var indicatorStatus = false

        /**
         *  处理result数据, 进行二次校验
         */
        print("executeValidationTask param code: \(param.code), result: \(param.result ?? [:])")

        guard let api2 = self.api2,
            let url = URL(string: api2) else {
            print("invalid api2 address")
            let gt3Error = GT3Error(domainType: .extern, code: -9999, withGTDesciption: "Invalid API2 address.")
            completion(false, gt3Error)
            return
        }

        var mRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        mRequest.httpMethod = "POST"

        let headerFields = ["Content-Type" : "application/json"]
        mRequest.allHTTPHeaderFields = headerFields
        
        var updatedResult =  param.result ?? [:]
        updatedResult["contact"] = "878787878"
        updatedResult["country_code"] = "+65"
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: updatedResult, options: [])
            mRequest.httpBody = jsonData
        } catch {
            // Handle the error if JSON serialization fails
            print("Failed to convert dictionary to JSON data: \(error)")
        }

        let dataTask = URLSession.shared.dataTask(with: mRequest) { (data: Data?, response: URLResponse?, error: Error?) in

            if let error = error {
                let gt3Error = GT3Error(domainType: .extern, originalError: error, withGTDesciption: "Request API2 fail.")
                completion(false , gt3Error)
                return
            }

            guard let data = data,
                let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                let gt3Error = GT3Error(domainType: .extern, code: -9999, withGTDesciption: "Invalid API2 response.")
                completion(false , gt3Error)
                return
            }

            if let result = try? JSONDecoder().decode(API2Response.self, from: data) {
                if result.data.result == "success" {
                    completion(true, nil)
                    indicatorStatus = true
                } else {
                    completion(false, nil)
                }
            }
            else {
                let gt3Error = GT3Error(domainType: .extern, code: -9999, withGTDesciption: "Invalid API2 data.")
                completion(false , gt3Error)
            }

            DispatchQueue.main.async {
                if indicatorStatus {
                    print("Demo 提示: 校验成功")
                    SwiftFlutterCaptchaPlugin.channel?.invokeMethod("getResult", arguments: true)
                } else {
                    print("Demo 提示: 校验失败")
                    SwiftFlutterCaptchaPlugin.channel?.invokeMethod("getResult", arguments: false)
                }
            }
        }
        dataTask.resume()
        self.validateTask = dataTask
    }

    func cancel() {
        self.registerTask?.cancel()
        self.validateTask?.cancel()
    }
}


