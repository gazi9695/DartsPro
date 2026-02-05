//
//  VideoLibraryView.swift
//  DartsPro
//
//  Created by Gazmir Cani on 05/02/2026.
//

import SwiftUI
import SwiftData
import AVKit

struct VideoLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecordedSession.recordedAt, order: .reverse) private var sessions: [RecordedSession]
    
    @State private var selectedSession: RecordedSession?
    @State private var showingPlayer = false
    
    var body: some View {
        ZStack {
            Color.dartsBackground.ignoresSafeArea()
            
            if sessions.isEmpty {
                emptyState
            } else {
                sessionsList
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.dartsGreen.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.dartsGreen)
            }
            
            Text("No Recordings Yet")
                .font(.dartsHeadline)
                .foregroundColor(.dartsTextPrimary)
            
            Text("Start a practice session to record\nyour throws and track progress")
                .font(.dartsBody)
                .foregroundColor(.dartsTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Sessions List
    
    private var sessionsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Your Sessions")
                        .font(.dartsTitle)
                        .foregroundColor(.dartsTextPrimary)
                    
                    Spacer()
                    
                    Text("\(sessions.count) videos")
                        .font(.dartsCaption)
                        .foregroundColor(.dartsTextSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Sessions grid
                LazyVStack(spacing: 12) {
                    ForEach(sessions) { session in
                        SessionCard(session: session)
                            .onTapGesture {
                                selectedSession = session
                                showingPlayer = true
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteSession(session)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 120)
            }
        }
        .fullScreenCover(isPresented: $showingPlayer) {
            if let session = selectedSession {
                VideoPlayerView(session: session)
            }
        }
    }
    
    // MARK: - Actions
    
    private func deleteSession(_ session: RecordedSession) {
        // Delete video file
        if let url = session.videoURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        // Delete from database
        modelContext.delete(session)
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: RecordedSession
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            thumbnailView
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(session.title)
                    .font(.dartsSubheadline)
                    .foregroundColor(.dartsTextPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    // Date
                    Label(session.formattedDate, systemImage: "calendar")
                        .font(.dartsCaption)
                        .foregroundColor(.dartsTextSecondary)
                    
                    // Duration
                    Label(session.formattedDuration, systemImage: "clock")
                        .font(.dartsCaption)
                        .foregroundColor(.dartsTextSecondary)
                }
                
                // Metrics
                if session.throwCount > 0 {
                    HStack(spacing: 12) {
                        Label("\(session.throwCount) throws", systemImage: "arrow.up.right")
                            .font(.dartsCaption)
                            .foregroundColor(.dartsRed)
                        
                        if let angle = session.averageElbowAngle {
                            Label("\(Int(angle))° avg", systemImage: "angle")
                                .font(.dartsCaption)
                                .foregroundColor(.dartsGreen)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Play indicator
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.dartsGreen)
        }
        .padding(16)
        .glassCard()
    }
    
    private var thumbnailView: some View {
        ZStack {
            if let data = session.thumbnailData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.dartsCardBackground)
                    .frame(width: 80, height: 60)
                    .overlay(
                        Image(systemName: "video.fill")
                            .foregroundColor(.dartsTextTertiary)
                    )
            }
        }
    }
}

// MARK: - Video Player View

struct VideoPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let session: RecordedSession
    
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }
            
            // Close button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .onAppear {
            if let url = session.videoURL {
                player = AVPlayer(url: url)
                player?.play()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

// MARK: - Preview

#Preview {
    VideoLibraryView()
        .modelContainer(for: RecordedSession.self, inMemory: true)
}
