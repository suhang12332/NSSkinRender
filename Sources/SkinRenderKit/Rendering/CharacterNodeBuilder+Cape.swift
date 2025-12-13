//
//  CharacterNodeBuilder+Cape.swift
//  SkinRenderKit
//
//  Cape construction helpers for CharacterNodeBuilder
//

import SceneKit

extension CharacterNodeBuilder {

  // MARK: - Cape

  func buildCape(
    capeImage: NSImage,
    parent: SCNNode
  ) -> (pivot: SCNNode, cape: SCNNode) {
    // Pivot node at upper back (shoulder line)
    let capePivotNode = SCNNode()
    capePivotNode.name = "CapePivot"
    capePivotNode.position = SCNVector3(0, 11, -2.5)

    // Cape geometry (10x16x1)
    let capeGeometry = SCNBox(width: 10, height: 16, length: 1.0, chamferRadius: 0)
    capeGeometry.materials = materialFactory.createCapeMaterials(from: capeImage)

    let capeNode = SCNNode(geometry: capeGeometry)
    capeNode.name = "Cape"
    capeNode.position = SCNVector3(0, -8, 0)

    // Apply slight backward tilt
    capePivotNode.eulerAngles = SCNVector3(Float.pi / 14, 0, 0)

    capePivotNode.addChildNode(capeNode)
    parent.addChildNode(capePivotNode)

    return (capePivotNode, capeNode)
  }

  // MARK: - Default Cape

  func loadDefaultCapeTexture() -> NSImage? {
    if let resourceURL = Bundle.module.url(forResource: "cape", withExtension: "png"),
       let image = NSImage(contentsOf: resourceURL) {
      return image
    }
    return NSImage(named: "cape")
  }
}
