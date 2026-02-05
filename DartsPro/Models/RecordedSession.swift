//
//  RecordedSession.swift
//  DartsPro
//
//  Created by Gazmir Cani on 05/02/2026.
//

import Foundation
import SwiftData

/// Represents a recorded practice session
@Model
final class RecordedSession {
    /// Unique identifier
    var id: UUID
    
    /// Session title (auto-generated or user-defined)
    var title: String
    
    /// Date when the session was recorded
    var recordedAt: Date
    
    /// Duration of the session in seconds
    var duration: TimeInterval
    
    /// Path to the video file (relative to documents directory)
    var videoFileName: String
    
    /// Number of throws detected in this session
    var throwCount: Int
    
    /// Average elbow angle during throws (degrees)
    var averageElbowAngle: Double?
    
    /// Best throw score/accuracy
    var bestAccuracy: Double?
    
    /// User's notes about the session
    var notes: String?
    
    /// Thumbnail image data
    @Attribute(.externalStorage)
    var thumbnailData: Data?
    
    /// Whether this session has been analyzed by AI
    var isAnalyzed: Bool
    
    /// AI analysis summary
    var aiAnalysisSummary: String?
    
    init(
        title: String? = nil,
        recordedAt: Date = Date(),
        duration: TimeInterval = 0,
        videoFileName: String,
        throwCount: Int = 0,
        averageElbowAngle: Double? = nil,
        bestAccuracy: Double? = nil,
        notes: String? = nil,
        thumbnailData: Data? = nil
    ) {
        self.id = UUID()
        self.title = title ?? Self.generateTitle(for: recordedAt)
        self.recordedAt = recordedAt
        self.duration = duration
        self.videoFileName = videoFileName
        self.throwCount = throwCount
        self.averageElbowAngle = averageElbowAngle
        self.bestAccuracy = bestAccuracy
        self.notes = notes
        self.thumbnailData = thumbnailData
        self.isAnalyzed = false
        self.aiAnalysisSummary = nil
    }
    
    // MARK: - Computed Properties
    
    /// Full URL to the video file
    var videoURL: URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsPath?.appendingPathComponent(videoFileName)
    }
    
    /// Formatted duration string (MM:SS)
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formatted date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(recordedAt) {
            return "Today"
        } else if calendar.isDateInYesterday(recordedAt) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: recordedAt)
        }
    }
    
    // MARK: - Helper Methods
    
    private static func generateTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return "Practice - \(formatter.string(from: date))"
    }
}
