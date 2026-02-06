//
//  CameraService.swift
//  DartsPro
//
//  Created by Gazmir Cani on 05/02/2026.
//

import AVFoundation
import SwiftUI

/// Protocol for receiving camera frame updates
protocol CameraServiceDelegate: AnyObject {
    func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer)
}

/// Manages camera capture session for live preview and frame processing
@Observable
final class CameraService: NSObject {
    
    // MARK: - Properties
    
    private let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.dartspro.camera.session")
    private let videoOutputQueue = DispatchQueue(label: "com.dartspro.camera.videoOutput")
    
    weak var delegate: CameraServiceDelegate?
    
    /// Additional frame handler for recording (called in addition to delegate)
    var onFrameOutput: ((CMSampleBuffer) -> Void)?
    
    var isSessionRunning = false
    var cameraPermissionGranted = false
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Camera Position
    
    private var currentCameraPosition: AVCaptureDevice.Position = .front
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupPreviewLayer()
    }
    
    // MARK: - Setup
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
    }
    
    /// Check and request camera permission
    func checkPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            await setupCaptureSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraPermissionGranted = granted
            if granted {
                await setupCaptureSession()
            }
        case .denied, .restricted:
            cameraPermissionGranted = false
        @unknown default:
            cameraPermissionGranted = false
        }
    }
    
    /// Configure the capture session
    private func setupCaptureSession() async {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .hd1280x720 // Optimized for performance
            
            // Add video input
            guard let videoDevice = self.getCamera(for: self.currentCameraPosition),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.captureSession.canAddInput(videoInput) else {
                self.captureSession.commitConfiguration()
                return
            }
            
            self.captureSession.addInput(videoInput)
            
            // Add video output for frame processing
            self.videoOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
                
                // Set video orientation
                if let connection = self.videoOutput.connection(with: .video) {
                    connection.videoRotationAngle = 90 // Portrait
                    if self.currentCameraPosition == .front {
                        connection.isVideoMirrored = true
                    }
                }
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    /// Get camera device for specified position
    private func getCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: position
        )
        return discoverySession.devices.first
    }
    
    // MARK: - Session Control
    
    /// Start the capture session
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        }
    }
    
    /// Stop the capture session
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }
    
    /// Switch between front and back camera
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            // Remove existing input
            if let currentInput = self.captureSession.inputs.first as? AVCaptureDeviceInput {
                self.captureSession.removeInput(currentInput)
            }
            
            // Toggle camera position
            self.currentCameraPosition = self.currentCameraPosition == .front ? .back : .front
            
            // Add new input
            guard let newDevice = self.getCamera(for: self.currentCameraPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice),
                  self.captureSession.canAddInput(newInput) else {
                self.captureSession.commitConfiguration()
                return
            }
            
            self.captureSession.addInput(newInput)
            
            // Update video orientation and mirroring
            if let connection = self.videoOutput.connection(with: .video) {
                connection.videoRotationAngle = 90
                connection.isVideoMirrored = self.currentCameraPosition == .front
            }
            
            self.captureSession.commitConfiguration()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.cameraService(self, didOutput: sampleBuffer)
        onFrameOutput?(sampleBuffer)
    }
}
