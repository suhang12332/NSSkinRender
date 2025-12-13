//
//  PlayerModel.swift
//  SkinRenderKit
//

import SceneKit

/// Simple value type for representing SceneKit box dimensions.
public struct BoxDimensions {
  public let width: CGFloat
  public let height: CGFloat
  public let length: CGFloat

  public init(width: CGFloat, height: CGFloat, length: CGFloat) {
    self.width = width
    self.height = height
    self.length = length
  }
}

// MARK: - Player Model Types

/// Represents the supported Minecraft player model variants.
///
/// Steve and Alex differ primarily in arm width, which affects geometry
/// dimensions and attachment positions used by the SceneKit rig.
public enum PlayerModel: String, CaseIterable {
  /// Classic model with wider arms (4 px in texture terms).
  case steve
  /// Slim model with narrower arms (3 px in texture terms).
  case alex

  /// Human‑readable display name for the model.
  var displayName: String {
    switch self {
    case .steve: return "Steve"
    case .alex:  return "Alex"
    }
  }

  /// Arm box dimensions for the model (width, height, length).
  var armDimensions: BoxDimensions {
    switch self {
    case .steve: return BoxDimensions(width: 4.0, height: 12.0, length: 4.0)
    case .alex:  return BoxDimensions(width: 3.0, height: 12.0, length: 4.0)
    }
  }

  /// Arm sleeve overlay box dimensions (width, height, length).
  var armSleeveDimensions: BoxDimensions {
    switch self {
    case .steve: return BoxDimensions(width: 4.5, height: 12.5, length: 4.5)
    case .alex:  return BoxDimensions(width: 3.5, height: 12.5, length: 4.5)
    }
  }

  /// Local positions for left and right arm attachment points.
  var armPositions: (left: SCNVector3, right: SCNVector3) {
    switch self {
    case .steve: return (SCNVector3(  6, 6, 0), SCNVector3(  -6, 6, 0))
    case .alex:  return (SCNVector3(5.5, 6, 0), SCNVector3(-5.5, 6, 0))
    }
  }
}
