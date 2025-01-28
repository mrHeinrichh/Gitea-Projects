//
//  GradientView.swift
//  Runner
//
//  Created by Venus Heng on 15/5/24.
//

import Foundation

class GradientView : UIView {
    private var colors: [CGColor] = []

    required init(frame: CGRect, colors: [CGColor]) {
        super.init(frame: frame)
        self.colors = colors
    }

    required override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        let colors = colors as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 1.0]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: colorLocations)!

        let startPoint = CGPoint.zero
        let endPoint = CGPoint(x: 0, y: self.bounds.height)
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
    }
    
}
