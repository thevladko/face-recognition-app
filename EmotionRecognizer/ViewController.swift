//
//  ViewController.swift
//  EmotionRecognizer
//
//  Created by Vladislav Kobyakov on 11/22/18.
//  Copyright © 2018 Vladislav Kobyakov. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController {
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        return tv
    }()
    
    private var requests = [VNRequest]()
    var faceDetectionRequest: VNRequest!
    var previewView: PreviewView!
    private var devicePosition: AVCaptureDevice.Position = .back
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice?
    var dataOutput: AVCaptureVideoDataOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        prepareUI()
        configureCaptureSessinon()
        configurePreviewLayer()
        configureCaptureDevice()
        configureDataOutput()
        startCaptureSession()
        configureViewForFaceDetection()
        configureFetchDetectionRequest()
    }
    
    private func exifOrientationFromDeviceOrientation() -> UInt32 {
        enum DeviceOrientation: UInt32 {
            case top0ColLeft = 1
            case top0ColRight = 2
            case bottom0ColRight = 3
            case bottom0ColLeft = 4
            case left0ColTop = 5
            case right0ColTop = 6
            case right0ColBottom = 7
            case left0ColBottom = 8
        }
        var exifOrientation: DeviceOrientation
        
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left0ColBottom
        case .landscapeLeft:
            exifOrientation = devicePosition == .front ? .bottom0ColRight : .top0ColLeft
        case .landscapeRight:
            exifOrientation = devicePosition == .front ? .top0ColLeft : .bottom0ColRight
        default:
            exifOrientation = .right0ColTop
        }
        return exifOrientation.rawValue
    }
    
    private func configureCaptureSessinon() {
        captureSession = AVCaptureSession()
//        captureSession.sessionPreset = .photo
    }
    
    private func configurePreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
    }
    
    private func configureCaptureDevice() {
        captureDevice = AVCaptureDevice.default(for: .video)
        if let device = captureDevice {
            guard let input = try? AVCaptureDeviceInput(device: device) else { return }
            captureSession.addInput(input)
        }
    }
    
    private func configureDataOutput() {
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    private func startCaptureSession() {
        captureSession.startRunning()
    }
    
    private func configureViewForFaceDetection() {
        previewView = PreviewView()
        previewView.frame = view.frame
        view.addSubview(previewView)
        previewView.session = captureSession
    }
    
    private func configureFetchDetectionRequest() {
        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: handleFaces)
        requests = [faceDetectionRequest]
    }
    
    func handleFaces(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results as? [VNFaceObservation] else { return }
            
            self.previewView.removeMask()
            
            for face in results {
                self.previewView.drawFaceboundingBox(face: face)
            }
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let exifOrientation = CGImagePropertyOrientation(rawValue: exifOrientationFromDeviceOrientation()) else { return }
        
        var requestOptions: [VNImageOption : Any] = [:]
        
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics : cameraIntrinsicData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
        }
            
        catch {
            print(error)
        }
        
        
//        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//        guard let model = try? VNCoreMLModel(for: CNNEmotions().model) else { return }
//        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
//            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
//            guard let firstObservation = results.first else { return }
//            print(firstObservation.identifier, firstObservation.confidence)
//            DispatchQueue.main.async {
//                self.textView.attributedText = NSMutableAttributedString(string: "\(firstObservation.identifier), \(firstObservation.confidence)", attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16), NSAttributedStringKey.foregroundColor : UIColor.white])
//            }
//        }
//        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

//UI
extension ViewController {
    private func prepareUI() {
        view.backgroundColor = .black
        setupViews()
    }
    
    private func setupViews() {
        view.addSubview(textView)
        
        textView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        view.addConstraint(NSLayoutConstraint(item: textView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: -40))
        view.addConstraint(NSLayoutConstraint(item: textView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 10))
        view.addConstraint(NSLayoutConstraint(item: textView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: -10))
    }
}
