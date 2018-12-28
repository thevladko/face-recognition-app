//
//  PreviewView.swift
//  EmotionRecognizer
//
//  Created by Vladislav Kobyakov on 11/23/18.
//  Copyright © 2018 Vladislav Kobyakov. All rights reserved.
//

import UIKit
import Vision
import AVKit

class PreviewView: UIView {
    
    private var maskLayer = [CAShapeLayer]()
    
    // MARK: AV capture properties
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    private func createLayer(in rect: CGRect) -> CAShapeLayer{
        let mask = CAShapeLayer()
        mask.frame = rect
        mask.cornerRadius = 10
        mask.opacity = 0.75
        mask.borderColor = UIColor.yellow.cgColor
        mask.borderWidth = 2.0
        
        maskLayer.append(mask)
        layer.insertSublayer(mask, at: 1)
        
        return mask
    }
    
    func drawFaceboundingBox(face : VNFaceObservation) {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -frame.height)
        
        let translate = CGAffineTransform.identity.scaledBy(x: frame.width, y: frame.height)
        
        let facebounds = face.boundingBox.applying(translate).applying(transform)
        
        _ = createLayer(in: facebounds)
        
    }
    
    func removeMask() {
        for mask in maskLayer {
            mask.removeFromSuperlayer()
        }
        maskLayer.removeAll()
    }
    
}

