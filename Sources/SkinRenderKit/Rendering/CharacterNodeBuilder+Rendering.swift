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

  // MARK: - Outer Layer Rebuild Helpers

  /// Rebuild voxel-based outer layers (hat, jacket, sleeves) using a new skin image.
  ///
  /// This keeps the base geometry intact and only refreshes the voxel overlays so that
  /// they fully follow the latest skin texture.
  func rebuildOuterLayerVoxels(
    _ nodes: CharacterNodes,
    skinImage: NSImage,
    playerModel: PlayerModel
  ) {
    // Head hat
    let hatSize = CharacterDimensions.hatSize
    let hatBoxSize = SCNVector3(hatSize, hatSize, hatSize)
    let headBaseSize = SCNVector3(
      CharacterDimensions.headSize,
      CharacterDimensions.headSize,
      CharacterDimensions.headSize
    )
    voxelBuilder.rebuildVoxelOverlay(
      in: nodes.hat,
      from: skinImage,
      specs: CubeFace.headHat,
      boxSize: hatBoxSize,
      voxelThickness: 0.5,
      baseSize: headBaseSize
    )

    // Body jacket
    let jacketBoxSize = SCNVector3(
      CharacterDimensions.jacketWidth,
      CharacterDimensions.jacketHeight,
      CharacterDimensions.jacketDepth
    )
    let bodyBaseSize = SCNVector3(
      CharacterDimensions.bodyWidth,
      CharacterDimensions.bodyHeight,
      CharacterDimensions.bodyDepth
    )
    voxelBuilder.rebuildVoxelOverlay(
      in: nodes.jacket,
      from: skinImage,
      specs: CubeFace.bodyJacket,
      boxSize: jacketBoxSize,
      voxelThickness: 0.25,
      baseSize: bodyBaseSize
    )

    // Arms sleeves
    let armDimensions = playerModel.armDimensions
    let armSleeveDimensions = playerModel.armSleeveDimensions
    let armSleeveBoxSize = SCNVector3(
      armSleeveDimensions.width,
      armSleeveDimensions.height,
      armSleeveDimensions.length
    )

    let rightArmSleeveSpecs = CubeFace.armSleeve(
      isLeft: false,
      armWidth: armDimensions.width
    )
    voxelBuilder.rebuildVoxelOverlay(
      in: nodes.rightArmSleeve,
      from: skinImage,
      specs: rightArmSleeveSpecs,
      boxSize: armSleeveBoxSize,
      voxelThickness: 0.25
    )

    let leftArmSleeveSpecs = CubeFace.armSleeve(
      isLeft: true,
      armWidth: armDimensions.width
    )
    voxelBuilder.rebuildVoxelOverlay(
      in: nodes.leftArmSleeve,
      from: skinImage,
      specs: leftArmSleeveSpecs,
      boxSize: armSleeveBoxSize,
      voxelThickness: 0.25
    )

    // Legs sleeves
    let legSleeveDimensions = playerModel.legSleeveDimensions
    let legSleeveBoxSize = SCNVector3(
      legSleeveDimensions.width,
      legSleeveDimensions.height,
      legSleeveDimensions.length
    )

    let rightLegSleeveSpecs = CubeFace.legSleeve(isLeft: false)
    voxelBuilder.rebuildVoxelOverlay(
      in: nodes.rightLegSleeve,
      from: skinImage,
      specs: rightLegSleeveSpecs,
      boxSize: legSleeveBoxSize,
      voxelThickness: 0.25
    )

    let leftLegSleeveSpecs = CubeFace.legSleeve(isLeft: true)
    voxelBuilder.rebuildVoxelOverlay(
      in: nodes.leftLegSleeve,
      from: skinImage,
      specs: leftLegSleeveSpecs,
      boxSize: legSleeveBoxSize,
      voxelThickness: 0.25
    )
  }
}
