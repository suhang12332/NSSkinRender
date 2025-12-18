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

    // Jacket layer
    let jacketGeometry = SCNBox(
      width: CharacterDimensions.jacketWidth,
      height: CharacterDimensions.jacketHeight,
      length: CharacterDimensions.jacketDepth,
      chamferRadius: 0
    )
    jacketGeometry.materials = materialFactory.createBodyMaterials(from: skinImage, isJacket: true)
    let jacketNode = SCNNode(geometry: jacketGeometry)
    jacketNode.name = "Jacket"
    jacketNode.position = SCNVector3Zero
    bodyGroup.addChildNode(jacketNode)

    return BodyNodes(
      group: bodyGroup,
      base: bodyNode,
      overlay: jacketNode
    )
  }
}
