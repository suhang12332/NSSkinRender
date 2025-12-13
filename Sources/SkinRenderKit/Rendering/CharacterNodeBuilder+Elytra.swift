//
//  CharacterNodeBuilder+Elytra.swift
//  SkinRenderKit
//
//  Elytra construction helpers for CharacterNodeBuilder
//

import SceneKit

/// Container for elytra node hierarchy
struct ElytraNodes {
  let pivot: SCNNode
  let leftWing: SCNNode
  let rightWing: SCNNode
}

extension CharacterNodeBuilder {

  // MARK: - Elytra

  /// Build elytra wings using plane geometry
  /// - Parameters:
  ///   - elytraImage: The elytra texture image (64x32)
  ///   - parent: The parent node to attach the elytra to
  /// - Returns: ElytraNodes containing the pivot node and left/right wing nodes
  func buildElytra(
    elytraImage: NSImage,
    parent: SCNNode
  ) -> ElytraNodes {
    // Pivot node at upper back (shoulder line, same position as cape)
    let elytraPivotNode = SCNNode()
    elytraPivotNode.name = "ElytraPivot"
    elytraPivotNode.position = SCNVector3(
      0,
      CharacterDimensions.elytraPivotY,
      CharacterDimensions.elytraPivotZ
    )

    // Left wing plane geometry
    let leftWingPlane = SCNPlane(
      width: CharacterDimensions.elytraWingWidth,
      height: CharacterDimensions.elytraWingHeight
    )
    leftWingPlane.materials = [materialFactory.createElytraWingMaterial(from: elytraImage, isLeft: true)]

    let leftWingNode = SCNNode(geometry: leftWingPlane)
    leftWingNode.name = "ElytraLeftWing"
    leftWingNode.position = SCNVector3(
      -CharacterDimensions.elytraWingXOffset,
      CharacterDimensions.elytraWingYOffset,
      CharacterDimensions.elytraWingZOffset
    )

    // Apply fold angle and tilt for natural appearance
    leftWingNode.eulerAngles = SCNVector3(
      CharacterDimensions.elytraTiltAngle,  // Forward tilt
      -CharacterDimensions.elytraFoldAngle, // Fold inward
      0
    )

    // Right wing plane geometry
    let rightWingPlane = SCNPlane(
      width: CharacterDimensions.elytraWingWidth,
      height: CharacterDimensions.elytraWingHeight
    )
    rightWingPlane.materials = [materialFactory.createElytraWingMaterial(from: elytraImage, isLeft: false)]

    let rightWingNode = SCNNode(geometry: rightWingPlane)
    rightWingNode.name = "ElytraRightWing"
    rightWingNode.position = SCNVector3(
      CharacterDimensions.elytraWingXOffset,
      CharacterDimensions.elytraWingYOffset,
      CharacterDimensions.elytraWingZOffset
    )

    // Apply fold angle and tilt for natural appearance (mirrored)
    rightWingNode.eulerAngles = SCNVector3(
      CharacterDimensions.elytraTiltAngle,  // Forward tilt
      CharacterDimensions.elytraFoldAngle,  // Fold inward
      0
    )

    elytraPivotNode.addChildNode(leftWingNode)
    elytraPivotNode.addChildNode(rightWingNode)
    parent.addChildNode(elytraPivotNode)

    return ElytraNodes(
      pivot: elytraPivotNode,
      leftWing: leftWingNode,
      rightWing: rightWingNode
    )
  }
}
