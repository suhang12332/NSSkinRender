//
//  CharacterNodeBuilder+Body.swift
//  SkinRenderKit
//
//  Body construction helpers for CharacterNodeBuilder
//

import SceneKit

/// Container for body node hierarchy
struct BodyNodes {
  let group: SCNNode
  let base: SCNNode
  let overlay: SCNNode
}

extension CharacterNodeBuilder {

  // MARK: - Body

  func buildBody(
    skinImage: NSImage,
    parent: SCNNode
  ) -> BodyNodes {
    // Body group positioned at body center
    let bodyGroup = SCNNode()
    bodyGroup.name = "BodyGroup"
    bodyGroup.position = SCNVector3(0, CharacterDimensions.bodyY, 0)
    parent.addChildNode(bodyGroup)

    // Base body
    let bodyGeometry = SCNBox(
      width: CharacterDimensions.bodyWidth,
      height: CharacterDimensions.bodyHeight,
      length: CharacterDimensions.bodyDepth,
      chamferRadius: 0
    )
    bodyGeometry.materials = materialFactory.createBodyMaterials(from: skinImage, isJacket: false)
    let bodyNode = SCNNode(geometry: bodyGeometry)
    bodyNode.name = "Body"
    bodyNode.position = SCNVector3Zero
    bodyGroup.addChildNode(bodyNode)

    // Jacket layer (voxelized outer layer)
    let jacketBoxSize = SCNVector3(
      CharacterDimensions.jacketWidth,
      CharacterDimensions.jacketHeight,
      CharacterDimensions.jacketDepth
    )
    let jacketNode = voxelBuilder.buildVoxelOverlay(
      from: skinImage,
      specs: CubeFace.bodyJacket,
      boxSize: jacketBoxSize,
      position: SCNVector3Zero,
      name: "Jacket"
    )
    bodyGroup.addChildNode(jacketNode)

    return BodyNodes(
      group: bodyGroup,
      base: bodyNode,
      overlay: jacketNode
    )
  }
}
