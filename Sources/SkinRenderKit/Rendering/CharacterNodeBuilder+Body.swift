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
    // Base body (8x12x4)
    let bodyGeometry = SCNBox(width: 8, height: 12, length: 4, chamferRadius: 0)
    bodyGeometry.materials = materialFactory.createBodyMaterials(from: skinImage, isJacket: false)
    let bodyNode = SCNNode(geometry: bodyGeometry)
    bodyNode.name = "Body"
    bodyNode.position = SCNVector3(0, 6, 0)
    parent.addChildNode(bodyNode)

    // Jacket layer (8.5x12.5x4.5)
    let jacketGeometry = SCNBox(width: 8.5, height: 12.5, length: 4.5, chamferRadius: 0)
    jacketGeometry.materials = materialFactory.createBodyMaterials(from: skinImage, isJacket: true)
    let jacketNode = SCNNode(geometry: jacketGeometry)
    jacketNode.name = "Jacket"
    jacketNode.position = SCNVector3(0, 6, 0)
    parent.addChildNode(jacketNode)

    return (bodyNode, jacketNode)
  }
}
