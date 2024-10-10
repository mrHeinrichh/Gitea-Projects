//
//  UIImageView+cache.swift
//  ImagePublish
//
//  Created by Venus Heng on 27/3/24.
//

import Foundation
import UIKit
import SDWebImage

extension UIImageView {

//    func or_setImageWithURL(url: URL) {
//
//        // Set a coloured background while it loads
//        if (image == nil) {
//            image = UIImage()
//        }
//
//        // Pass directly to SDWebImage if not in testing environment
//        guard NSClassFromString("XCTest") != nil else {
//            sd_setImage(with: url)
//            return
//        }
//
//        // Look inside the SD Image Cache to see if our URL has already been stored
//        let imageManager = SDWebImageManager.shared
//        let key = imageManager.cacheKey(for: url)
//
//        // If not, provide a useful error message, or optionally raise an exception
//        guard let cachedImage = imageManager.imageCache.queryImage?(forKey: key, context: nil, cacheType: SDImageCacheType.disk) else {
//            print("Detected a un-stubbed image request for URL: \(url)")
//            sd_setImage(with: url)
//            return
//        }
//
//        // Synchronously set the cached image
//        image = cachedImage.
//    }
}
