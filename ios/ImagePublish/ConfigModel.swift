//
//  ConfigModel.swift
//  ImagePublish
//
//  Created by griffin on 20/6/24.
//

import Foundation
import UIKit

let globalConfig = Config.init(themeMain: Config.defaultThemeMain, themeBlack: Config.defaultThemeBlack)


struct Config: Codable {
    
    private var themeMain: String
    private var themeBlack: String
    
    init(themeMain: String, themeBlack: String) {
        self.themeMain = themeMain
        self.themeBlack = themeBlack
        self.loadConfig()
    }
    
    static let defaultThemeMain = "007AFF"
    static let defaultThemeBlack = "121212"
    var themeMainColor:UIColor {
        get {
            return UIColor.init(hex: themeMain)
        }
    }
    var themeBlackColor:UIColor {
        get {
            return UIColor.init(hex: themeBlack)
        }
    }
    
    mutating func loadConfig() {
        if let url = Bundle.main.url(forResource: "config", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let config = try decoder.decode(Config.self, from: data)
                print("themeMain: \(config.themeMain)")
                print("themeBlack: \(config.themeBlack)")
                self.themeMain = config.themeMain
                self.themeBlack = config.themeBlack
            } catch {
                print("Failed to load: \(error.localizedDescription)")
            }
        }
    }
}

