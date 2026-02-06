//
//  RecordingService.swift
//  DartsPro
//
//  Created by Gazmir Cani on 05/02/2026.
//

import AVFoundation
import UIKit

/// Handles video recording using AVAssetWriter
@Observable
final class RecordingService {
    
    // MARK: - Properties
    
    var isRecording = false
    var recordingDuration: TimeInterval = 0
    
    // Closure-based callbacks (SwiftUI friendly)
    var onDurationUpdate: ((TimeInterval) -> Void)?
    var onRecordingFinished: ((URL) -> Void)?
    var onRecordingFailed: ((Error) -> Void)?
    
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var recordingStartTime: CMTime?
    private var lastSampleTime: CMTime?
    private var outputURL: URL?
    
    private let recordingQueue = DispatchQueue(label: "com.dartspro.recording")
    private var durationTimer: Timer?
    private var recordingStartDate: Date?
    
    // MARK: - Recording Control
    
    /// Start recording video
    func startRecording() throws {
        guard !isRecording else { return }
        
        // Create unique filename
        let fileName = "session_\(UUID().uuidString).mp4"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        outputURL = documentsPath.appendingPathComponent(fileName)
        
        guard let url = outputURL else {
            throw RecordingError.invalidURL
        }
        
        // Remove existing file if needed
        try? FileManager.default.removeItem(at: url)
        
        // Create asset writer
        assetWriter = try AVAssetWriter(outputURL: url, fileType: .mp4)
        
        // Video settings - optimized for performance (720p)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 720,
            AVVideoHeightKey: 1280,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 2_500_000, // 2.5 Mbps
                AVVideoProfileLevelKey: AVVideoProfileLevelH264Main31,
                AVVideoExpectedSourceFrameRateKey: 30
            ]
        ]
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true
        
        // Pixel buffer adaptor for efficient writing (720p)
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: 720,
            kCVPixelBufferHeightKey as String: 1280
        ]
        
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput!,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )
        
        if assetWriter!.canAdd(videoInput!) {
            assetWriter!.add(videoInput!)
        }
        
        // Start writing
        assetWriter?.startWriting()
        
        isRecording = true
        recordingDuration = 0
        recordingStartTime = nil
        recordingStartDate = Date()
        
        // Start duration timer
        startDurationTimer()
    }
    
    /// Stop recording and save video
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        stopDurationTimer()
        
        recordingQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.videoInput?.markAsFinished()
            self.audioInput?.markAsFinished()
            
            self.assetWriter?.finishWriting { [weak self] in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = self.assetWriter?.error {
                        self.onRecordingFailed?(error)
                    } else if let url = self.outputURL {
                        self.onRecordingFinished?(url)
                    }
                    
                    // Cleanup
                    self.assetWriter = nil
                    self.videoInput = nil
                    self.audioInput = nil
                    self.pixelBufferAdaptor = nil
                    self.recordingStartTime = nil
                    self.outputURL = nil
                }
            }
        }
    }
    
    /// Process video frame for recording
    func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard isRecording,
              let assetWriter = assetWriter,
              let videoInput = videoInput,
              videoInput.isReadyForMoreMediaData else {
            return
        }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Start session on first frame
        if recordingStartTime == nil {
            recordingStartTime = timestamp
            assetWriter.startSession(atSourceTime: timestamp)
        }
        
        // Append sample buffer
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            pixelBufferAdaptor?.append(pixelBuffer, withPresentationTime: timestamp)
        }
        
        lastSampleTime = timestamp
    }
    
    // MARK: - Duration Timer
    
    private func startDurationTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let startDate = self.recordingStartDate else { return }
                self.recordingDuration = Date().timeIntervalSince(startDate)
                self.onDurationUpdate?(self.recordingDuration)
            }
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    // MARK: - Thumbnail Generation
    
    /// Generate thumbnail from recorded video
    static func generateThumbnail(from url: URL) async -> Data? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 300, height: 300)
        
        do {
            let cgImage = try await imageGenerator.image(at: .zero).image
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: 0.7)
        } catch {
            return nil
        }
    }
    
    /// Get video file name from URL
    var currentVideoFileName: String? {
        outputURL?.lastPathComponent
    }
}

// MARK: - Recording Errors

enum RecordingError: LocalizedError {
    case invalidURL
    case writerNotReady
    case writingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Could not create recording file"
        case .writerNotReady: return "Recording system not ready"
        case .writingFailed: return "Failed to save recording"
        }
    }
}
