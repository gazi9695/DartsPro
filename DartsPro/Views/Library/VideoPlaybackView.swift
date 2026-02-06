//
//  VideoPlaybackView.swift
//  DartsPro
//
//  Created by Gazmir Cani on 06/02/2026.
//

import SwiftUI
import AVFoundation
import Vision

/// Enhanced video player with real-time pose overlay
struct VideoPlaybackView: View {
    @Environment(\.dismiss) private var dismiss
    let session: RecordedSession
    var onDelete: (() -> Void)? = nil
    
    @State private var player: AVPlayer?
    @State private var playerTime: CMTime = .zero
    @State private var duration: CMTime = .zero
    @State private var isPlaying = false
    @State private var currentPose: DetectedPose?
    @State private var showPoseOverlay = true
    @State private var isRightHanded = true
    @State private var viewSize: CGSize = .zero
    @State private var showDeleteConfirmation = false
    
    // Vision processing
    @State private var videoOutput: AVPlayerItemVideoOutput?
    @State private var displayLink: CADisplayLink?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Video layer with pose overlay
                ZStack {
                    // Video player
                    if let player = player {
                        VideoPlayerLayer(player: player)
                            .ignoresSafeArea()
                    }
                    
                    // Pose overlay
                    if showPoseOverlay {
                        PoseOverlayView(
                            pose: currentPose,
                            viewSize: viewSize,
                            isRightHanded: isRightHanded
                        )
                        .ignoresSafeArea()
                    }
                }
                .onAppear {
                    viewSize = geometry.size
                }
                .onChange(of: geometry.size) { _, newSize in
                    viewSize = newSize
                }
                
                // Controls overlay
                VStack {
                    topControls
                    
                    Spacer()
                    
                    bottomControls
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    // MARK: - Top Controls
    
    private var topControls: some View {
        HStack {
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Pose overlay toggle
            Button(action: { showPoseOverlay.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: showPoseOverlay ? "figure.stand" : "figure.stand.line.dotted.figure.stand")
                    Text(showPoseOverlay ? "Pose On" : "Pose Off")
                }
                .font(.dartsCaption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
            }
            
            // Handedness toggle
            Button(action: { isRightHanded.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: isRightHanded ? "hand.point.right" : "hand.point.left")
                    Text(isRightHanded ? "Right" : "Left")
                }
                .font(.dartsCaption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
            }
            
            // Delete button
            if onDelete != nil {
                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.dartsRed)
                        .padding(12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .alert("Delete Session?", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        onDelete?()
                    }
                } message: {
                    Text("This will permanently delete this recording.")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Progress bar
            progressBar
            
            // Playback controls
            HStack(spacing: 40) {
                // Rewind 10s
                Button(action: { seek(by: -10) }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Play/Pause
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                }
                
                // Forward 10s
                Button(action: { seek(by: 10) }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            
            // Session info
            HStack(spacing: 20) {
                if session.throwCount > 0 {
                    Label("\(session.throwCount) throws", systemImage: "arrow.up.right")
                }
                
                if let angle = session.averageElbowAngle {
                    Label("\(Int(angle))° avg", systemImage: "angle")
                }
            }
            .font(.dartsCaption)
            .foregroundColor(.dartsTextSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            .allowsHitTesting(false),
            alignment: .bottom
        )
    }
    
    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress
                    Capsule()
                        .fill(Color.dartsRed)
                        .frame(width: progressWidth(in: geo.size.width), height: 4)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            seekToProgress(value.location.x / geo.size.width)
                        }
                )
            }
            .frame(height: 4)
            
            HStack {
                Text(formatTime(playerTime))
                Spacer()
                Text(formatTime(duration))
            }
            .font(.dartsCaption)
            .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Helpers
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard duration.seconds > 0 else { return 0 }
        let progress = playerTime.seconds / duration.seconds
        return min(max(totalWidth * progress, 0), totalWidth)
    }
    
    private func formatTime(_ time: CMTime) -> String {
        let seconds = Int(time.seconds)
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func seek(by seconds: Double) {
        guard let player = player else { return }
        let newTime = CMTimeAdd(playerTime, CMTimeMakeWithSeconds(seconds, preferredTimescale: 600))
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    private func seekToProgress(_ progress: Double) {
        guard let player = player, duration.seconds > 0 else { return }
        let targetTime = CMTimeMakeWithSeconds(duration.seconds * progress, preferredTimescale: 600)
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    // MARK: - Setup
    
    private func setupPlayer() {
        guard let url = session.videoURL else { return }
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Setup video output for pose detection
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: outputSettings)
        playerItem.add(output)
        videoOutput = output
        
        let avPlayer = AVPlayer(playerItem: playerItem)
        player = avPlayer
        
        // Get duration
        Task {
            if let durationValue = try? await asset.load(.duration) {
                await MainActor.run {
                    duration = durationValue
                }
            }
        }
        
        // Setup time observer - process every 3rd frame for performance
        var frameCounter = 0
        avPlayer.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 30), queue: .main) { [weak output] time in
            playerTime = time
            
            // Process frame for pose detection (throttled)
            frameCounter += 1
            if showPoseOverlay, let output = output, frameCounter % 3 == 0 {
                processCurrentFrameAsync(output: output, at: time)
            }
        }
        
        // Start playing
        avPlayer.play()
        isPlaying = true
    }
    
    // Background queue for Vision processing
    private static let visionQueue = DispatchQueue(label: "com.dartspro.vision.playback", qos: .userInitiated)
    @State private var isProcessingFrame = false
    
    private func processCurrentFrameAsync(output: AVPlayerItemVideoOutput, at time: CMTime) {
        // Skip if already processing
        guard !isProcessingFrame else { return }
        
        guard output.hasNewPixelBuffer(forItemTime: time),
              let pixelBuffer = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else {
            return
        }
        
        isProcessingFrame = true
        
        // Run pose detection on background thread
        Self.visionQueue.async {
            let request = VNDetectHumanBodyPoseRequest()
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            
            do {
                try handler.perform([request])
                
                if let results = request.results,
                   let observation = results.first {
                    let pose = DetectedPose(from: observation)
                    DispatchQueue.main.async {
                        self.currentPose = pose
                        self.isProcessingFrame = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.currentPose = nil
                        self.isProcessingFrame = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessingFrame = false
                }
            }
        }
    }
    
    private func cleanup() {
        player?.pause()
        player = nil
        displayLink?.invalidate()
        displayLink = nil
    }
}

// MARK: - Video Player Layer (UIViewRepresentable)

struct VideoPlayerLayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView()
        view.player = player
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerView = uiView as? PlayerUIView {
            playerView.player = player
        }
    }
}

class PlayerUIView: UIView {
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    private var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.videoGravity = .resizeAspectFill
    }
}

// MARK: - Preview

#Preview {
    VideoPlaybackView(
        session: RecordedSession(
            title: "Practice Session",
            duration: 45,
            videoFileName: "test.mp4",
            throwCount: 12,
            averageElbowAngle: 95.5
        ),
        onDelete: {}
    )
}
