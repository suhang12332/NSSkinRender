//
//  CharacterNodeBuilder+Head.swift
//  SkinRenderKit
//
//  Head construction helpers for CharacterNodeBuilder
//

import SceneKit

/// Container for head node hierarchy
struct HeadNodes {
  let group: SCNNode
  let base: SCNNode
  let overlay: SCNNode
}

extension CharacterNodeBuilder {

  // MARK: - Head

  func buildHead(
    skinImage: NSImage,
    parent: SCNNode
  ) -> HeadNodes {
    // Group positioned at head center for rotations/bobbing
    let headGroup = SCNNode()
    headGroup.name = "HeadGroup"
    headGroup.position = SCNVector3(0, 16, 0)
    parent.addChildNode(headGroup)

    // Base head (8x8x8)
    let headGeometry = SCNBox(width: 8, height: 8, length: 8, chamferRadius: 0)
    headGeometry.materials = materialFactory.createHeadMaterials(from: skinImage, isHat: false)
    let headNode = SCNNode(geometry: headGeometry)
    headNode.name = "Head"
    headNode.position = SCNVector3Zero
    headGroup.addChildNode(headNode)

    // Hat layer (9x9x9)
    let hatGeometry = SCNBox(width: 9, height: 9, length: 9, chamferRadius: 0)
    hatGeometry.materials = materialFactory.createHeadMaterials(from: skinImage, isHat: true)
    let hatNode = SCNNode(geometry: hatGeometry)
    hatNode.name = "Hat"
    hatNode.position = SCNVector3Zero
    headGroup.addChildNode(hatNode)

    return HeadNodes(
      group: headGroup,
      base: headNode,
      overlay: hatNode
    )
  }
}
