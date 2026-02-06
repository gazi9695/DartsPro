//
//  SessionReviewView.swift
//  DartsPro
//
//  Created by Gazmir Cani on 06/02/2026.
//

import SwiftUI
import AVKit

/// View shown after recording is saved, allowing user to review the session
struct SessionReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let session: RecordedSession
    let onDone: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            Color.dartsBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Video player
                videoPlayerSection
                
                // Session info & actions
                sessionInfoSection
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    // MARK: - Video Player
    
    private var videoPlayerSection: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(9/16, contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color.dartsCardBackground)
                    .overlay(
                        ProgressView()
                            .tint(.dartsTextPrimary)
                    )
            }
            
            // Top bar overlay
            VStack {
                HStack {
                    Button(action: { 
                        onDone()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Session badge
                    Text("Session Saved ✓")
                        .font(.dartsCaption)
                        .foregroundColor(.dartsGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Session Info
    
    @State private var showingPosePlayback = false
    
    private var sessionInfoSection: some View {
        VStack(spacing: 16) {
            // Title
            Text(session.title)
                .font(.dartsHeadline)
                .foregroundColor(.dartsTextPrimary)
            
            // Metrics row
            HStack(spacing: 24) {
                metricItem(
                    icon: "clock",
                    value: session.formattedDuration,
                    label: "Duration"
                )
                
                if session.throwCount > 0 {
                    metricItem(
                        icon: "arrow.up.right",
                        value: "\(session.throwCount)",
                        label: "Throws"
                    )
                }
                
                if let angle = session.averageElbowAngle {
                    metricItem(
                        icon: "angle",
                        value: "\(Int(angle))°",
                        label: "Avg Angle"
                    )
                }
            }
            
            // Actions
            VStack(spacing: 12) {
                // View with Pose Overlay
                Button(action: { showingPosePlayback = true }) {
                    HStack {
                        Image(systemName: "figure.stand")
                        Text("View with Pose Overlay")
                    }
                    .font(.dartsSubheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dartsRed)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                HStack(spacing: 16) {
                    // Record Another
                    Button(action: { onDone() }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Record Another")
                        }
                        .font(.dartsSubheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dartsCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Done
                    Button(action: { onDone() }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Done")
                        }
                        .font(.dartsSubheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dartsGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .background(Color.dartsCardBackground)
        .fullScreenCover(isPresented: $showingPosePlayback) {
            VideoPlaybackView(session: session)
        }
    }
    
    // MARK: - Helpers
    
    private func metricItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(value)
                    .font(.dartsMetric)
            }
            .foregroundColor(.dartsTextPrimary)
            
            Text(label)
                .font(.dartsCaption)
                .foregroundColor(.dartsTextSecondary)
        }
    }
    
    private func setupPlayer() {
        if let url = session.videoURL {
            player = AVPlayer(url: url)
            player?.play()
        }
    }
}

// MARK: - Preview

#Preview {
    SessionReviewView(
        session: RecordedSession(
            title: "Practice Session",
            duration: 45,
            videoFileName: "test.mp4",
            throwCount: 12,
            averageElbowAngle: 95.5
        ),
        onDone: {}
    )
}
