//
//  Bundle+views.swift
//  Runner
//
//  Created by Venus Heng on 4/4/24.
//

import Foundation
import AVFoundation

extension Bundle {
    static func loadView<T>(fromNib name: String, withType type: T.Type) -> T {
        if let view = Bundle.main.loadNibNamed(name, owner: nil, options: nil)?.first as? T {
            return view
        }
        fatalError("Could not load view with type " + String(describing: type))
    }
}
