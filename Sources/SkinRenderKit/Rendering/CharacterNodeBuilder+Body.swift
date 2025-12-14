//
//  CharacterNodeBuilder+Body.swift
//  SkinRenderKit
//
//  Body construction helpers for CharacterNodeBuilder
//

import SceneKit

extension CharacterNodeBuilder {

  // MARK: - Body

  func buildBody(
    skinImage: NSImage,
    parent: SCNNode
  ) -> (base: SCNNode, overlay: SCNNode) {
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
    bodyNode.position = SCNVector3(0, CharacterDimensions.bodyY, 0)
    parent.addChildNode(bodyNode)

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
    jacketNode.position = SCNVector3(0, CharacterDimensions.bodyY, 0)
    parent.addChildNode(jacketNode)

    return (bodyNode, jacketNode)
  }
}
