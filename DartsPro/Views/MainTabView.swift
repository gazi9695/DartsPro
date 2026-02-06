//
//  MainTabView.swift
//  DartsPro
//
//  Created by Gazmir Cani on 05/02/2026.
//

import SwiftUI

/// Main tab navigation for the app
struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case library = "Library"
        case practice = "Practice"
        case progress = "Progress"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .library: return "play.rectangle.fill"
            case .practice: return "camera.fill"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .home: return .dartsTextPrimary
            case .library: return .dartsGreen
            case .practice: return .dartsRed
            case .progress: return .dartsRed
            case .settings: return .dartsTextPrimary
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .practice:
                    LiveTrackingView(onClose: {
                        selectedTab = .home
                    })
                case .library:
                    VideoLibraryView()
                case .progress:
                    DartsProgressView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom tab bar - hide during practice
            if selectedTab != .practice {
                customTabBar
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 17)
        .frame(maxWidth: .infinity)
        .background(
            Color.dartsCardBackground
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.05), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 1),
                    alignment: .top
                )
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
    }
    
    private func tabButton(for tab: Tab) -> some View {
        Button(action: { 
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab 
            }
        }) {
            VStack(spacing: 4) {
                // Special styling for Practice tab (center, larger)
                if tab == .practice {
                    ZStack {
                        Circle()
                            .fill(Color.dartsRed)
                            .frame(width: 52, height: 52)
                            .glow(color: .dartsRed, radius: 15)
                        
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .offset(y: -10)
                } else {
                    Image(systemName: tab.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(selectedTab == tab ? tab.color : .dartsTextTertiary)
                    
                    Text(tab.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(selectedTab == tab ? tab.color : .dartsTextTertiary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Views

// VideoLibraryView is now in Views/Library/VideoLibraryView.swift

struct DartsProgressView: View {
    var body: some View {
        ZStack {
            Color.dartsBackground.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundColor(.dartsRed)
                
                Text("Your Progress")
                    .font(.dartsHeadline)
                    .foregroundColor(.dartsTextPrimary)
                
                Text("Track your improvement over time")
                    .font(.dartsBody)
                    .foregroundColor(.dartsTextSecondary)
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        ZStack {
            Color.dartsBackground.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.dartsTextSecondary)
                
                Text("Settings")
                    .font(.dartsHeadline)
                    .foregroundColor(.dartsTextPrimary)
                
                Text("Configure your preferences")
                    .font(.dartsBody)
                    .foregroundColor(.dartsTextSecondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
