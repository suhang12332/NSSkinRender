//
//  CharacterNodeBuilder+Rendering.swift
//  SkinRenderKit
//
//  Rendering configuration helpers for CharacterNodeBuilder
//

import SceneKit

extension CharacterNodeBuilder {

  // MARK: - Rendering Priorities

  func setupRenderingPriorities(_ nodes: CharacterNodes) {
    // Base layers: body < head < limbs
    nodes.body.renderingOrder = 100
    nodes.head.renderingOrder = 102
    nodes.rightArm.renderingOrder = 105
    nodes.leftArm.renderingOrder = 106
    nodes.rightLeg.renderingOrder = 105
    nodes.leftLeg.renderingOrder = 106

    // Outer layers: jacket < hat < limb sleeves (different orders to prevent Z-fighting)
    nodes.jacket.renderingOrder = 200
    nodes.hat.renderingOrder = 202
    nodes.rightArmSleeve.renderingOrder = 210
    nodes.leftArmSleeve.renderingOrder = 211
    nodes.rightLegSleeve.renderingOrder = 210
    nodes.leftLegSleeve.renderingOrder = 211

    // Cape - between base and outer
    nodes.capePivot?.renderingOrder = 150

    // Elytra - same priority as cape
    nodes.elytraPivot?.renderingOrder = 150

    // MARK: - Z-Fighting Prevention Offsets
    // When two surfaces occupy the same depth position, the GPU cannot determine
    // which should be rendered in front, causing flickering (Z-fighting).
    // We apply tiny position offsets to create depth separation while remaining
    // visually imperceptible.

    // Z-axis offsets: Separate left/right limbs when they overlap (e.g., legs together)
    // Left limbs move forward (+Z), right limbs move backward (-Z)
    // Sleeves need larger offset since they're already offset from base limbs
    applyZOffset(to: nodes.leftLeg, offset: 0.01)
    applyZOffset(to: nodes.leftArm, offset: 0.01)
    applyZOffset(to: nodes.leftLegSleeve, offset: 0.02)
    applyZOffset(to: nodes.leftArmSleeve, offset: 0.02)

    applyZOffset(to: nodes.rightArm, offset: -0.01)
    applyZOffset(to: nodes.rightLeg, offset: -0.01)
    applyZOffset(to: nodes.rightArmSleeve, offset: -0.02)
    applyZOffset(to: nodes.rightLegSleeve, offset: -0.02)

    // X-axis offsets: Separate limb inner surfaces from body sides
    // When limbs swing forward/backward, their inner surfaces can intersect with body
    // Push limbs slightly outward to prevent this overlap
    applyXOffset(to: nodes.leftLeg, offset: -0.01)
    applyXOffset(to: nodes.leftArm, offset: -0.01)
    applyXOffset(to: nodes.leftLegSleeve, offset: -0.01)
    applyXOffset(to: nodes.leftArmSleeve, offset: -0.01)

    applyXOffset(to: nodes.rightLeg, offset: 0.01)
    applyXOffset(to: nodes.rightArm, offset: 0.01)
    applyXOffset(to: nodes.rightLegSleeve, offset: 0.01)
    applyXOffset(to: nodes.rightArmSleeve, offset: 0.01)
  }

  // MARK: - Position Offsets

  /// Applies a small Z position offset to prevent Z-fighting
  private func applyZOffset(to node: SCNNode, offset: Float) {
    node.position.z += CGFloat(offset)
  }

  /// Applies a small X position offset to prevent Z-fighting with body
  private func applyXOffset(to node: SCNNode, offset: Float) {
    node.position.x += CGFloat(offset)
  }
}
