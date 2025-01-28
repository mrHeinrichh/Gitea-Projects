//
//  CaptchaManager.swift
//  test_verify_ios
//
//  Created by YUN WAH LEE on 1/2/23.
//

import UIKit
import GT3Captcha

class CaptchaManager : NSObject {
    let api1 = "http://im-user.jxtest.net/app/api/auth/geetest/register"
    let api2 = "http://im-user.jxtest.net/app/api/auth/geetest/validate"

    var verifyAsyncTask: VerifyAsyncTask?

    fileprivate lazy var gt3CaptchaManager: GT3CaptchaManager = {
        let manager = GT3CaptchaManager(api1: nil, api2: nil, timeout: 5.0)
        manager.delegate = self as GT3CaptchaManagerDelegate

        return manager
    }()

    override init() {
        super.init()
        let verifyAsyncTask = VerifyAsyncTask()
        verifyAsyncTask.api1 = self.api1
        verifyAsyncTask.api2 = self.api2
        // 为验证管理器注册自定义的异步任务
        // 此步骤不建议放到管理器的懒加载中
        // 保障内部注册动作，在调用开启验证之前完成
        gt3CaptchaManager.registerCaptcha(withCustomAsyncTask: verifyAsyncTask, completion: nil);
        self.verifyAsyncTask = verifyAsyncTask // 在 manager 内是弱引用，为避免在后续使用时 asyncTask 不会已被提前释放，建议在外部将其保持到全局
    }

    func startVerify() {
        gt3CaptchaManager.startGTCaptchaWith(animated: true )

    }
}

extension CaptchaManager: GT3CaptchaManagerDelegate, GT3CaptchaManagerViewDelegate {

    func gtCaptcha(_ manager: GT3CaptchaManager, errorHandler error: GT3Error) {
        print("error code: \(error.code)")
        print("error desc: \(error.error_code) - \(error.gtDescription)")

        // 处理验证中返回的错误
        if (error.code == -999) {
            // 请求被意外中断, 一般由用户进行取消操作导致
        }
        else if (error.code == -10) {
            // 预判断时被封禁, 不会再进行图形验证
        }
        else if (error.code == -20) {
            // 尝试过多
        }
        else {
            // 网络问题或解析失败, 更多错误码参考开发文档
        }
    }

    func gtCaptcha(_ manager: GT3CaptchaManager, didReceiveSecondaryCaptchaData data: Data?, response: URLResponse?, error: GT3Error?, decisionHandler: ((GT3SecondaryCaptchaPolicy) -> Void)) {
        if let error = error {
            print("API2 error: \(error.code) - \(error.error_code) - \(error.gtDescription)")
            decisionHandler(.forbidden)
            return
        }

        if let data = data {
            print("API2 repsonse: \(String(data: data, encoding: .utf8) ?? "")")
            decisionHandler(.allow)
            return
        }
        else {
            print("API2 repsonse: nil")
            decisionHandler(.forbidden)
        }
        decisionHandler(.forbidden)
    }

    // MARK: GT3CaptchaManagerViewDelegate

    func gtCaptchaWillShowGTView(_ manager: GT3CaptchaManager) {
        print("gtcaptcha will show gtview")
    }
}
