//
//  AVURLAsset+Size.swift
//  ImagePublish
//
//  Created by Venus Heng on 11/1/24.
//

import Foundation
import AVFoundation

extension AVURLAsset {
    var fileSize: Int? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)

        return resourceValues?.fileSize ?? resourceValues?.totalFileSize
    }
}
