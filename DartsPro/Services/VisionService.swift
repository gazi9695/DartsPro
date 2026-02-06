//
//  VisionService.swift
//  DartsPro
//
//  Created by Gazmir Cani on 05/02/2026.
//

import Vision
import CoreMedia
import SwiftUI

/// Represents detected body pose landmarks
struct DetectedPose: Sendable {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let confidence: Float
    
    // Key joints for darts analysis
    var rightWrist: CGPoint? { bodyPoints[.rightWrist] }
    var rightElbow: CGPoint? { bodyPoints[.rightElbow] }
    var rightShoulder: CGPoint? { bodyPoints[.rightShoulder] }
    var leftWrist: CGPoint? { bodyPoints[.leftWrist] }
    var leftElbow: CGPoint? { bodyPoints[.leftElbow] }
    var leftShoulder: CGPoint? { bodyPoints[.leftShoulder] }
    var nose: CGPoint? { bodyPoints[.nose] }
    var neck: CGPoint? { bodyPoints[.neck] }
    var root: CGPoint? { bodyPoints[.root] } // Hip center
    
    /// Initialize from VNHumanBodyPoseObservation
    init(from observation: VNHumanBodyPoseObservation) {
        var points: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        
        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .neck, .root,
            .rightShoulder, .rightElbow, .rightWrist,
            .leftShoulder, .leftElbow, .leftWrist,
            .rightHip, .rightKnee, .rightAnkle,
            .leftHip, .leftKnee, .leftAnkle,
            .rightEye, .leftEye, .rightEar, .leftEar
        ]
        
        for jointName in jointNames {
            if let point = try? observation.recognizedPoint(jointName),
               point.confidence > 0.3 {
                // Vision coordinates are normalized (0-1) with origin at bottom-left
                // Convert to top-left origin for display
                points[jointName] = CGPoint(x: point.location.x, y: 1 - point.location.y)
            }
        }
        
        self.bodyPoints = points
        self.confidence = observation.confidence
    }
    
    /// Standard initializer
    init(bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint], confidence: Float) {
        self.bodyPoints = bodyPoints
        self.confidence = confidence
    }
    
    /// Calculate elbow angle for the throwing arm (right by default)
    func calculateElbowAngle(isRightHanded: Bool = true) -> Double? {
        let shoulder = isRightHanded ? rightShoulder : leftShoulder
        let elbow = isRightHanded ? rightElbow : leftElbow
        let wrist = isRightHanded ? rightWrist : leftWrist
        
        guard let s = shoulder, let e = elbow, let w = wrist else { return nil }
        
        let v1 = CGVector(dx: s.x - e.x, dy: s.y - e.y)
        let v2 = CGVector(dx: w.x - e.x, dy: w.y - e.y)
        
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let mag1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy)
        let mag2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy)
        
        guard mag1 > 0, mag2 > 0 else { return nil }
        
        let cosAngle = dot / (mag1 * mag2)
        let clampedCos = max(-1, min(1, cosAngle))
        return acos(clampedCos) * 180.0 / Double.pi
    }
}

/// Protocol for receiving pose detection updates
protocol VisionServiceDelegate: AnyObject {
    func visionService(_ service: VisionService, didDetectPose pose: DetectedPose)
    func visionService(_ service: VisionService, didFailWithError error: Error)
}

/// Handles body pose detection using Apple Vision framework
@Observable
final class VisionService {
    
    // MARK: - Properties
    
    weak var delegate: VisionServiceDelegate?
    
    var currentPose: DetectedPose?
    var isProcessing = false
    
    @ObservationIgnored
    private let requestHandler = VNSequenceRequestHandler()
    @ObservationIgnored
    private var frameCount = 0
    @ObservationIgnored
    private let processEveryNthFrame = 4 // Process every 4th frame for performance (~7.5fps)
    
    // MARK: - Body Pose Request
    
    @ObservationIgnored
    private var _bodyPoseRequest: VNDetectHumanBodyPoseRequest?
    
    private var bodyPoseRequest: VNDetectHumanBodyPoseRequest {
        if let request = _bodyPoseRequest {
            return request
        }
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            self?.handleBodyPoseResults(request: request, error: error)
        }
        _bodyPoseRequest = request
        return request
    }
    
    // MARK: - Process Frame
    
    /// Process a video frame for pose detection
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        frameCount += 1
        
        // Skip frames for performance
        guard frameCount % processEveryNthFrame == 0 else { return }
        guard !isProcessing else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        isProcessing = true
        
        do {
            try requestHandler.perform([bodyPoseRequest], on: pixelBuffer, orientation: .up)
        } catch {
            isProcessing = false
            delegate?.visionService(self, didFailWithError: error)
        }
    }
    
    // MARK: - Handle Results
    
    private func handleBodyPoseResults(request: VNRequest, error: Error?) {
        defer { isProcessing = false }
        
        if let error = error {
            delegate?.visionService(self, didFailWithError: error)
            return
        }
        
        guard let observations = request.results as? [VNHumanBodyPoseObservation],
              let observation = observations.first else {
            currentPose = nil
            return
        }
        
        // Extract all recognized points
        let recognizedPoints = extractRecognizedPoints(from: observation)
        
        let pose = DetectedPose(
            bodyPoints: recognizedPoints,
            confidence: observation.confidence
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentPose = pose
            self.delegate?.visionService(self, didDetectPose: pose)
        }
    }
    
    /// Extract recognized body points from observation
    private func extractRecognizedPoints(from observation: VNHumanBodyPoseObservation) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        var points: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        
        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .neck, .root,
            .rightShoulder, .rightElbow, .rightWrist,
            .leftShoulder, .leftElbow, .leftWrist,
            .rightHip, .rightKnee, .rightAnkle,
            .leftHip, .leftKnee, .leftAnkle,
            .rightEye, .leftEye, .rightEar, .leftEar
        ]
        
        for jointName in jointNames {
            if let point = try? observation.recognizedPoint(jointName),
               point.confidence > 0.3 {
                // Vision coordinates are normalized (0-1) with origin at bottom-left
                // Convert to top-left origin for display
                points[jointName] = CGPoint(x: point.location.x, y: 1 - point.location.y)
            }
        }
        
        return points
    }
    
    // MARK: - Get Skeleton Connections
    
    /// Returns pairs of joint names that should be connected to draw the skeleton
    static var skeletonConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] {
        [
            // Torso
            (.neck, .root),
            (.neck, .rightShoulder),
            (.neck, .leftShoulder),
            
            // Right arm
            (.rightShoulder, .rightElbow),
            (.rightElbow, .rightWrist),
            
            // Left arm
            (.leftShoulder, .leftElbow),
            (.leftElbow, .leftWrist),
            
            // Right leg
            (.root, .rightHip),
            (.rightHip, .rightKnee),
            (.rightKnee, .rightAnkle),
            
            // Left leg
            (.root, .leftHip),
            (.leftHip, .leftKnee),
            (.leftKnee, .leftAnkle),
            
            // Head
            (.nose, .neck),
            (.nose, .rightEye),
            (.nose, .leftEye),
            (.rightEye, .rightEar),
            (.leftEye, .leftEar)
        ]
    }
}
