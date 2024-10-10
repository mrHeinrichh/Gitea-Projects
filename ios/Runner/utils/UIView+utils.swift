//
//  UIView+utils.swift
//  Runner
//
//  Created by Venus Heng on 15/5/24.
//

import Foundation

extension UIView {
    func addGradientLayer(with colors: [CGColor], startPoint: CGPoint, endPoint: CGPoint, locations: [NSNumber] = [0.0, 1.0], frame: CGRect = CGRect.zero) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.edgeAntialiasingMask = [.layerLeftEdge, .layerRightEdge, .layerBottomEdge, .layerTopEdge]
        gradientLayer.allowsEdgeAntialiasing = true
        gradientLayer.shouldRasterize = true
        gradientLayer.rasterizationScale = UIScreen.main.scale * 2
        gradientLayer.colors = colors
        gradientLayer.contentsScale = UIScreen.main.scale * 2
        gradientLayer.type = .axial

        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint

        gradientLayer.locations = locations
        gradientLayer.frame = frame

        gradientLayer.cornerRadius = self.layer.cornerRadius
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func asImage() -> UIImage? {
        guard self.frame.size != .zero else {
            return nil
        }

        UIGraphicsBeginImageContext(self.frame.size)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let cgImage = image?.cgImage {
            return UIImage(cgImage: cgImage)
        } else {
            return nil
        }
    }
}
