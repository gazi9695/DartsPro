//
//  LiveTrackingView.swift
//  DartsPro
//
//  Created by Gazmir Cani on 05/02/2026.
//

import SwiftUI
import SwiftData
import CoreMedia

/// Live camera view with pose tracking overlay and real-time metrics
struct LiveTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var cameraService = CameraService()
    @State private var visionService = VisionService()
    @State private var recordingService = RecordingService()
    
    @State private var viewSize: CGSize = .zero
    @State private var isRightHanded = true
    @State private var showingSettings = false
    @State private var elapsedTime: TimeInterval = 0
    
    // Recording metrics
    @State private var throwCount = 0
    @State private var totalElbowAngle: Double = 0
    @State private var angleReadings = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.dartsBackground
                .ignoresSafeArea()
            
            // Camera preview
            GeometryReader { geometry in
                ZStack {
                    CameraPreviewRepresentable(previewLayer: cameraService.previewLayer)
                        .ignoresSafeArea()
                        .onAppear {
                            viewSize = geometry.size
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            viewSize = newSize
                        }
                    
                    // Pose overlay
                    PoseOverlayView(
                        pose: visionService.currentPose,
                        viewSize: viewSize,
                        isRightHanded: isRightHanded
                    )
                    .ignoresSafeArea()
                }
            }
            
            // Metrics overlay
            VStack {
                // Top bar
                topBar
                
                Spacer()
                
                // Record button and metrics
                bottomControls
            }
        }
        .onAppear {
            setupCamera()
            setupRecordingCallbacks()
        }
        .onDisappear {
            if recordingService.isRecording {
                recordingService.stopRecording()
            }
            cameraService.stopSession()
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Close button
            Button(action: { 
                if recordingService.isRecording {
                    recordingService.stopRecording()
                }
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Recording indicator & timer
            if recordingService.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.dartsRed)
                        .frame(width: 10, height: 10)
                    
                    Text(formatDuration(elapsedTime))
                        .font(.dartsBody)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
            } else {
                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(visionService.currentPose != nil ? Color.dartsGreen : Color.dartsWarning)
                        .frame(width: 8, height: 8)
                    
                    Text(visionService.currentPose != nil ? "Ready" : "Position yourself")
                        .font(.dartsCaption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // Switch camera
            Button(action: { cameraService.switchCamera() }) {
                Image(systemName: "camera.rotate")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Metrics
            HStack(spacing: 20) {
                MetricPill(
                    title: "Elbow Angle",
                    value: elbowAngleString,
                    color: elbowAngleColor
                )
                
                if recordingService.isRecording {
                    MetricPill(
                        title: "Throws",
                        value: "\(throwCount)",
                        color: .dartsRed
                    )
                } else {
                    MetricPill(
                        title: "Confidence",
                        value: confidenceString,
                        color: .dartsGreen
                    )
                }
            }
            
            // Record button
            recordButton
            
            // Hand toggle
            if !recordingService.isRecording {
                HStack {
                    Text("Throwing Hand:")
                        .font(.dartsCaption)
                        .foregroundColor(.dartsTextSecondary)
                    
                    Picker("Hand", selection: $isRightHanded) {
                        Text("Right").tag(true)
                        Text("Left").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Record Button
    
    private var recordButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                // Inner button
                if recordingService.isRecording {
                    // Stop (square)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.dartsRed)
                        .frame(width: 32, height: 32)
                } else {
                    // Record (circle)
                    Circle()
                        .fill(Color.dartsRed)
                        .frame(width: 64, height: 64)
                }
            }
        }
        .glow(color: recordingService.isRecording ? .dartsRed : .clear, radius: 20)
    }
    
    // MARK: - Recording Actions
    
    private func toggleRecording() {
        if recordingService.isRecording {
            recordingService.stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        do {
            try recordingService.startRecording()
            throwCount = 0
            totalElbowAngle = 0
            angleReadings = 0
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    private func setupRecordingCallbacks() {
        recordingService.onDurationUpdate = { duration in
            elapsedTime = duration
        }
        
        recordingService.onRecordingFinished = { url in
            saveSession(videoURL: url)
        }
        
        recordingService.onRecordingFailed = { error in
            print("Recording failed: \(error.localizedDescription)")
        }
    }
    
    private func saveSession(videoURL: URL) {
        Task {
            let averageAngle = angleReadings > 0 ? totalElbowAngle / Double(angleReadings) : nil
            let thumbnailData = await RecordingService.generateThumbnail(from: videoURL)
            
            let session = RecordedSession(
                recordedAt: Date(),
                duration: elapsedTime,
                videoFileName: videoURL.lastPathComponent,
                throwCount: throwCount,
                averageElbowAngle: averageAngle,
                thumbnailData: thumbnailData
            )
            
            await MainActor.run {
                modelContext.insert(session)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var elbowAngleString: String {
        if let pose = visionService.currentPose,
           let angle = pose.calculateElbowAngle(isRightHanded: isRightHanded) {
            // Track angle when recording
            if recordingService.isRecording {
                totalElbowAngle += angle
                angleReadings += 1
            }
            return "\(Int(angle))°"
        }
        return "--°"
    }
    
    private var elbowAngleColor: Color {
        if let pose = visionService.currentPose,
           let angle = pose.calculateElbowAngle(isRightHanded: isRightHanded) {
            if angle >= 85 && angle <= 115 {
                return .dartsGreen
            } else if angle >= 70 && angle <= 130 {
                return .dartsWarning
            } else {
                return .dartsRed
            }
        }
        return .dartsTextSecondary
    }
    
    private var confidenceString: String {
        if let pose = visionService.currentPose {
            return "\(Int(pose.confidence * 100))%"
        }
        return "--%"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Setup
    
    private func setupCamera() {
        Task {
            await cameraService.checkPermission()
            cameraService.delegate = visionService
            cameraService.startSession()
        }
    }
}

// MARK: - VisionService as CameraDelegate

extension VisionService: CameraServiceDelegate {
    func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer) {
        processFrame(sampleBuffer)
    }
}

// MARK: - Metric Pill Component

struct MetricPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.dartsCaption)
                .foregroundColor(.dartsTextSecondary)
            
            Text(value)
                .font(.dartsMetric)
                .foregroundColor(color)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    LiveTrackingView()
}
