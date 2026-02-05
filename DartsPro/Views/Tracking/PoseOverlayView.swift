//
//  PoseOverlayView.swift
//  DartsPro
//
//  Created by Gazmir Cani on 05/02/2026.
//

import SwiftUI
import Vision

/// Overlay view that draws the detected body pose skeleton
struct PoseOverlayView: View {
    let pose: DetectedPose?
    let viewSize: CGSize
    let isRightHanded: Bool
    
    init(pose: DetectedPose?, viewSize: CGSize, isRightHanded: Bool = true) {
        self.pose = pose
        self.viewSize = viewSize
        self.isRightHanded = isRightHanded
    }
    
    var body: some View {
        Canvas { context, size in
            guard let pose = pose else { return }
            
            // Draw skeleton connections
            drawSkeleton(context: context, pose: pose, size: size)
            
            // Draw joint points
            drawJoints(context: context, pose: pose, size: size)
        }
    }
    
    // MARK: - Draw Skeleton Lines
    
    private func drawSkeleton(context: GraphicsContext, pose: DetectedPose, size: CGSize) {
        for connection in VisionService.skeletonConnections {
            guard let startPoint = pose.bodyPoints[connection.0],
                  let endPoint = pose.bodyPoints[connection.1] else {
                continue
            }
            
            let start = convertToViewCoordinates(startPoint, in: size)
            let end = convertToViewCoordinates(endPoint, in: size)
            
            // Determine line color based on body part
            let color = getConnectionColor(connection)
            
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            
            context.stroke(path, with: .color(color), lineWidth: 3)
        }
    }
    
    // MARK: - Draw Joint Points
    
    private func drawJoints(context: GraphicsContext, pose: DetectedPose, size: CGSize) {
        for (jointName, point) in pose.bodyPoints {
            let viewPoint = convertToViewCoordinates(point, in: size)
            let jointSize: CGFloat = getJointSize(for: jointName)
            let color = getJointColor(for: jointName)
            
            let rect = CGRect(
                x: viewPoint.x - jointSize / 2,
                y: viewPoint.y - jointSize / 2,
                width: jointSize,
                height: jointSize
            )
            
            // Outer glow
            if isKeyJoint(jointName) {
                let glowRect = rect.insetBy(dx: -4, dy: -4)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(color.opacity(0.3))
                )
            }
            
            // Joint circle
            context.fill(
                Circle().path(in: rect),
                with: .color(color)
            )
            
            // Inner highlight
            let innerRect = rect.insetBy(dx: jointSize * 0.25, dy: jointSize * 0.25)
            context.fill(
                Circle().path(in: innerRect),
                with: .color(.white.opacity(0.5))
            )
        }
    }
    
    // MARK: - Coordinate Conversion
    
    private func convertToViewCoordinates(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: point.x * size.width,
            y: point.y * size.height
        )
    }
    
    // MARK: - Styling Helpers
    
    private func getConnectionColor(_ connection: (VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)) -> Color {
        // Highlight throwing arm
        let throwingArmJoints: Set<VNHumanBodyPoseObservation.JointName> = isRightHanded
            ? [.rightShoulder, .rightElbow, .rightWrist]
            : [.leftShoulder, .leftElbow, .leftWrist]
        
        if throwingArmJoints.contains(connection.0) && throwingArmJoints.contains(connection.1) {
            return .dartsRed
        }
        
        return .dartsGreen.opacity(0.8)
    }
    
    private func getJointColor(for joint: VNHumanBodyPoseObservation.JointName) -> Color {
        let throwingArmJoints: Set<VNHumanBodyPoseObservation.JointName> = isRightHanded
            ? [.rightShoulder, .rightElbow, .rightWrist]
            : [.leftShoulder, .leftElbow, .leftWrist]
        
        if throwingArmJoints.contains(joint) {
            return .dartsRed
        }
        
        return .dartsGreen
    }
    
    private func getJointSize(for joint: VNHumanBodyPoseObservation.JointName) -> CGFloat {
        if isKeyJoint(joint) {
            return 16
        }
        return 10
    }
    
    private func isKeyJoint(_ joint: VNHumanBodyPoseObservation.JointName) -> Bool {
        let keyJoints: Set<VNHumanBodyPoseObservation.JointName> = [
            .rightWrist, .rightElbow, .rightShoulder,
            .leftWrist, .leftElbow, .leftShoulder
        ]
        return keyJoints.contains(joint)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.dartsBackground
        
        // Sample pose for preview
        PoseOverlayView(
            pose: DetectedPose(
                bodyPoints: [
                    .nose: CGPoint(x: 0.5, y: 0.15),
                    .neck: CGPoint(x: 0.5, y: 0.22),
                    .rightShoulder: CGPoint(x: 0.35, y: 0.25),
                    .rightElbow: CGPoint(x: 0.25, y: 0.35),
                    .rightWrist: CGPoint(x: 0.2, y: 0.25),
                    .leftShoulder: CGPoint(x: 0.65, y: 0.25),
                    .leftElbow: CGPoint(x: 0.75, y: 0.35),
                    .leftWrist: CGPoint(x: 0.8, y: 0.45),
                    .root: CGPoint(x: 0.5, y: 0.5),
                    .rightHip: CGPoint(x: 0.42, y: 0.52),
                    .leftHip: CGPoint(x: 0.58, y: 0.52)
                ],
                confidence: 0.95
            ),
            viewSize: CGSize(width: 400, height: 800)
        )
    }
}
