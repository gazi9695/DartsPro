//
//  CameraPreviewRepresentable.swift
//  DartsPro
//
//  Created by Gazmir Cani on 05/02/2026.
//

import SwiftUI
import AVFoundation

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer
struct CameraPreviewRepresentable: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            previewLayer?.frame = uiView.bounds
        }
    }
}
