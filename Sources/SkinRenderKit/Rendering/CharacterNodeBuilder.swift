//
//  CharacterNodeBuilder.swift
//  SkinRenderKit
//
//  Builder for constructing the SceneKit node hierarchy for Minecraft characters
//

import SceneKit

/// Builder responsible for creating the complete character node hierarchy
public final class CharacterNodeBuilder {

  // MARK: - Node References

  /// Container for all character node references
  public final class CharacterNodes {
    public let root: SCNNode

    // Head
    public let headGroup: SCNNode
    public let head: SCNNode
    public let hat: SCNNode

    // Body
    public let body: SCNNode
    public let jacket: SCNNode

    // Arms
    public let rightArmGroup: SCNNode
    public let rightArm: SCNNode
    public let rightArmSleeve: SCNNode
    public let leftArmGroup: SCNNode
    public let leftArm: SCNNode
    public let leftArmSleeve: SCNNode

    // Legs
    public let rightLegGroup: SCNNode
    public let rightLeg: SCNNode
    public let rightLegSleeve: SCNNode
    public let leftLegGroup: SCNNode
    public let leftLeg: SCNNode
    public let leftLegSleeve: SCNNode

    // Cape
    public private(set) var capePivot: SCNNode?
    public private(set) var cape: SCNNode?

    // Elytra
    public private(set) var elytraPivot: SCNNode?
    public private(set) var elytraLeftWing: SCNNode?
    public private(set) var elytraRightWing: SCNNode?

    init(
      root: SCNNode,
      headGroup: SCNNode, head: SCNNode, hat: SCNNode,
      body: SCNNode, jacket: SCNNode,
      rightArmGroup: SCNNode, rightArm: SCNNode, rightArmSleeve: SCNNode,
      leftArmGroup: SCNNode, leftArm: SCNNode, leftArmSleeve: SCNNode,
      rightLegGroup: SCNNode, rightLeg: SCNNode, rightLegSleeve: SCNNode,
      leftLegGroup: SCNNode, leftLeg: SCNNode, leftLegSleeve: SCNNode,
      capePivot: SCNNode? = nil, cape: SCNNode? = nil
    ) {
      self.root = root
      self.headGroup = headGroup
      self.head = head
      self.hat = hat
      self.body = body
      self.jacket = jacket
      self.rightArmGroup = rightArmGroup
      self.rightArm = rightArm
      self.rightArmSleeve = rightArmSleeve
      self.leftArmGroup = leftArmGroup
      self.leftArm = leftArm
      self.leftArmSleeve = leftArmSleeve
      self.rightLegGroup = rightLegGroup
      self.rightLeg = rightLeg
      self.rightLegSleeve = rightLegSleeve
      self.leftLegGroup = leftLegGroup
      self.leftLeg = leftLeg
      self.leftLegSleeve = leftLegSleeve
      self.capePivot = capePivot
      self.cape = cape
    }

    func setCape(pivot: SCNNode, cape: SCNNode) {
      self.capePivot = pivot
      self.cape = cape
    }

    func setElytra(pivot: SCNNode, leftWing: SCNNode, rightWing: SCNNode) {
      self.elytraPivot = pivot
      self.elytraLeftWing = leftWing
      self.elytraRightWing = rightWing
    }

    /// Toggle visibility of outer layers (hat, jacket, sleeves)
    public func setOuterLayersHidden(_ hidden: Bool) {
      hat.isHidden = hidden
      jacket.isHidden = hidden
      rightArmSleeve.isHidden = hidden
      leftArmSleeve.isHidden = hidden
      rightLegSleeve.isHidden = hidden
      leftLegSleeve.isHidden = hidden
    }

    /// Toggle cape visibility
    public func setCapeHidden(_ hidden: Bool) {
      capePivot?.isHidden = hidden
    }

    /// Toggle elytra visibility
    public func setElytraHidden(_ hidden: Bool) {
      elytraPivot?.isHidden = hidden
    }
  }

  // MARK: - Dependencies

  let materialFactory: CharacterMaterialFactory

  // MARK: - Initialization

  public init(materialFactory: CharacterMaterialFactory) {
    self.materialFactory = materialFactory
  }

  // MARK: - Build Character

  /// Build the complete character node hierarchy
  /// - Parameters:
  ///   - skinImage: The skin texture image
  ///   - capeImage: Optional cape texture image
  ///   - elytraImage: Optional elytra texture image (takes priority over cape)
  ///   - playerModel: The player model type (Steve/Alex)
  /// - Returns: CharacterNodes containing all node references
  public func build(
    skinImage: NSImage,
    capeImage: NSImage?,
    elytraImage: NSImage? = nil,
    playerModel: PlayerModel
  ) -> CharacterNodes {
    let root = SCNNode()
    root.name = "CharacterGroup"

    // Build all body parts
    let headNodes = buildHead(skinImage: skinImage, parent: root)
    let bodyNodes = buildBody(skinImage: skinImage, parent: root)
    let armNodes = buildArms(skinImage: skinImage, playerModel: playerModel, parent: root)
    let legNodes = buildLegs(skinImage: skinImage, playerModel: playerModel, parent: root)

    let nodes = CharacterNodes(
      root: root,
      headGroup: headNodes.group,
      head: headNodes.base,
      hat: headNodes.overlay,
      body: bodyNodes.base,
      jacket: bodyNodes.overlay,
      rightArmGroup: armNodes.rightGroup,
      rightArm: armNodes.rightBase,
      rightArmSleeve: armNodes.rightOverlay,
      leftArmGroup: armNodes.leftGroup,
      leftArm: armNodes.leftBase,
      leftArmSleeve: armNodes.leftOverlay,
      rightLegGroup: legNodes.rightGroup,
      rightLeg: legNodes.rightBase,
      rightLegSleeve: legNodes.rightOverlay,
      leftLegGroup: legNodes.leftGroup,
      leftLeg: legNodes.leftBase,
      leftLegSleeve: legNodes.leftOverlay
    )

    // Build elytra if texture provided (elytra takes priority over cape)
    if let elytraImage = elytraImage {
      let elytraNodes = buildElytra(elytraImage: elytraImage, parent: root)
      nodes.setElytra(
        pivot: elytraNodes.pivot,
        leftWing: elytraNodes.leftWing,
        rightWing: elytraNodes.rightWing
      )
    } else if let capeImage = capeImage {
      // Build cape only if no elytra
      let capeNodes = buildCape(capeImage: capeImage, parent: root)
      nodes.setCape(pivot: capeNodes.pivot, cape: capeNodes.cape)
    } else {
      // Try to load default cape from bundle if neither elytra nor cape provided
      if let defaultCape = loadDefaultCapeTexture() {
        let capeNodes = buildCape(capeImage: defaultCape, parent: root)
        nodes.setCape(pivot: capeNodes.pivot, cape: capeNodes.cape)
      }
    }

    // Set rendering priorities
    setupRenderingPriorities(nodes)

    return nodes
  }
}
