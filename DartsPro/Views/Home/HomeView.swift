//
//  HomeView.swift
//  DartsPro
//
//  Created by Gazmir Cani on 05/02/2026.
//

import SwiftUI

struct HomeView: View {
    @State private var showingLiveTracking = false
    @State private var showingAIAnalysis = false
    @State private var showingProgress = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.dartsBackground
                    .ignoresSafeArea()
                
                // Dartboard pattern overlay (subtle)
                DartboardBackgroundPattern()
                    .opacity(0.05)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Main CTA - Start Practice
                        startPracticeCard
                        
                        // Secondary Actions
                        HStack(spacing: 16) {
                            aiAnalysisCard
                            progressCard
                        }
                        
                        // Recent Sessions
                        recentSessionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingLiveTracking) {
                LiveTrackingView()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.dartsRed)
                    
                    Text("DartsPro")
                        .font(.dartsTitle)
                        .foregroundColor(.dartsTextPrimary)
                }
                
                HStack(spacing: 6) {
                    Text("Hey, Player")
                        .font(.dartsSubheadline)
                        .foregroundColor(.dartsTextSecondary)
                    
                    AISparkle(size: 14)
                }
            }
            
            Spacer()
            
            // Settings button
            Button(action: {}) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.dartsTextSecondary)
                    .padding(12)
                    .background(Color.dartsCardBackground)
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Start Practice Card
    private var startPracticeCard: some View {
        Button(action: { showingLiveTracking = true }) {
            VStack(spacing: 16) {
                // Camera icon with glow
                ZStack {
                    Circle()
                        .fill(Color.dartsRed.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.dartsRed)
                }
                .glow(color: .dartsRed, radius: 25)
                
                VStack(spacing: 6) {
                    Text("Start Practice")
                        .font(.dartsHeadline)
                        .foregroundColor(.dartsTextPrimary)
                    
                    Text("Improve your aim with AI feedback")
                        .font(.dartsCaption)
                        .foregroundColor(.dartsTextSecondary)
                }
                
                Text("START")
                    .font(.dartsSubheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.dartsGreen)
                    )
                    .glow(color: .dartsGreen, radius: 12)
            }
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
            .glassCard()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.dartsRed.opacity(0.5), Color.dartsRed.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - AI Analysis Card
    private var aiAnalysisCard: some View {
        Button(action: { showingAIAnalysis = true }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.dartsGreen.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.dartsGreen)
                }
                
                VStack(spacing: 4) {
                    Text("AI Analysis")
                        .font(.dartsSubheadline)
                        .foregroundColor(.dartsTextPrimary)
                    
                    Text("Get personalized\nthrow insights")
                        .font(.dartsCaption)
                        .foregroundColor(.dartsTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .glassCard()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.dartsGreen.opacity(0.3), Color.dartsGreen.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Progress Card
    private var progressCard: some View {
        Button(action: { showingProgress = true }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.dartsRed.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.dartsRed)
                }
                
                VStack(spacing: 4) {
                    Text("Your Progress")
                        .font(.dartsSubheadline)
                        .foregroundColor(.dartsTextPrimary)
                    
                    Text("Track your accuracy\nand stats")
                        .font(.dartsCaption)
                        .foregroundColor(.dartsTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Recent Sessions Section
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(.dartsHeadline)
                .foregroundColor(.dartsTextPrimary)
            
            // Placeholder sessions
            VStack(spacing: 12) {
                SessionRowPlaceholder(date: "Today", throwCount: 120, accuracy: 85)
                SessionRowPlaceholder(date: "Yesterday", throwCount: 80, accuracy: 78)
                SessionRowPlaceholder(date: "Feb 3", throwCount: 100, accuracy: 82)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Session Row Placeholder
struct SessionRowPlaceholder: View {
    let date: String
    let throwCount: Int
    let accuracy: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Dartboard icon
            Image(systemName: "target")
                .font(.system(size: 18))
                .foregroundColor(.dartsRed)
                .frame(width: 40, height: 40)
                .background(Color.dartsCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Date
            Text(date)
                .font(.dartsBody)
                .foregroundColor(.dartsTextPrimary)
                .frame(width: 70, alignment: .leading)
            
            Spacer()
            
            // Throws
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(.dartsRed)
                Text("\(throwCount) Throws")
                    .font(.dartsCaption)
                    .foregroundColor(.dartsTextSecondary)
            }
            
            // Accuracy
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(accuracy >= 80 ? .dartsGreen : .dartsWarning)
                Text("\(accuracy)%")
                    .font(.dartsCaption)
                    .foregroundColor(.dartsTextSecondary)
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 12)
    }
}

// MARK: - Dartboard Background Pattern
struct DartboardBackgroundPattern: View {
    var body: some View {
        GeometryReader { geometry in
            Circle()
                .stroke(Color.white, lineWidth: 1)
                .frame(width: geometry.size.width * 1.5, height: geometry.size.width * 1.5)
                .position(x: geometry.size.width, y: geometry.size.height * 0.3)
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
