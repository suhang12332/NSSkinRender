//
//  SceneKitCharacterViewController+Updates.swift
//  SkinRenderKit
//

import SceneKit

extension SceneKitCharacterViewController {

  private func applySkinUpdate(path: String? = nil, image: NSImage? = nil) {
    if let path = path {
      // Skip if path unchanged
      guard skinTexturePath != path else { return }
      self.skinTexturePath = path
      loadTexture()
      if skinImage != nil {
        updateSkinGeometry()
      }
      return
    }

    if let image = image {
      // No longer short-circuit only through instance equality; allow external code to reuse the same NSImage instance but update its content
      self.skinImage = image
      self.skinTexturePath = nil
      updateSkinGeometry()
    }
  }

  private func applyCapeUpdate(path: String? = nil, image: NSImage? = nil) {
    if let path = path {
      // Return directly if path unchanged to avoid invalid refresh
      guard capeTexturePath != path else {
        return
      }
      self.capeTexturePath = path
      loadCapeTexture(from: path)
      // Update cape geometry only when image is successfully loaded
      if capeImage != nil {
        updateCapeGeometry()
      }
      return
    }

    if let image = image {
      // Allow the same instance to be passed again to support in-place modification of NSImage content
      self.capeImage = image
      self.capeTexturePath = nil
      updateCapeGeometry()
    }
  }

  public func updateTexture(path: String) {
    applySkinUpdate(path: path)
  }

  public func updateTexture(image: NSImage) {
    applySkinUpdate(image: image)
  }

  public func updateRotationDuration(_ duration: TimeInterval) {
    // Skip if duration unchanged
    guard rotationDuration != duration else { return }
    self.rotationDuration = duration
    animationController.updateRotationDuration(duration)
  }

  public func updateBackgroundColor(_ color: NSColor) {
    // Skip if color unchanged
    guard backgroundColor != color else { return }
    self.backgroundColor = color
    scnView?.backgroundColor = color
  }

  public func updateCapeTexture(path: String) {
    applyCapeUpdate(path: path)
  }

  public func updateCapeTexture(image: NSImage) {
    applyCapeUpdate(image: image)
  }

  public func removeCapeTexture() {
    // Skip if already no cape
    guard capeImage != nil || capeTexturePath != nil else {
      return
    }
    self.capeImage = nil
    self.capeTexturePath = nil
    removeCapeGeometry()
  }

  public func updatePlayerModel(_ model: PlayerModel) {
    // Skip if model unchanged
    guard playerModel != model else { return }
    self.playerModel = model
    rebuildCharacter()
  }

  public func updateShowButtons(_ show: Bool) {
    guard self.debugMode != show else { return }
    self.debugMode = show

    if !show {
      allDebugButtons.forEach { $0.removeFromSuperview() }
    } else {
      setupUI()
    }
  }

  public func toggleCapeAnimation(_ enabled: Bool) {
    animationController.toggleCapeAnimation(enabled)
  }

  /// Update or create cape geometry based on current `capeImage` without rebuilding the entire character
  private func updateCapeGeometry() {
    guard let nodes = characterNodes else {
      return
    }
    guard let image = capeImage else {
      return
    }

    if let capeNode = nodes.cape, let geometry = capeNode.geometry {
      // Clean up old materials
      for material in geometry.materials {
        material.diffuse.contents = nil
        material.ambient.contents = nil
        material.specular.contents = nil
      }
      geometry.materials = materialFactory.createCapeMaterials(from: image)
    } else {
      let capeNodes = nodeBuilder.buildCape(capeImage: image, parent: nodes.root)
      nodes.setCape(pivot: capeNodes.pivot, cape: capeNodes.cape)
      nodes.setCapeHidden(!showCape)
      // If cape animation is enabled, refresh the animation once
      animationController.refreshCapeSwayAnimation()
    }
  }

  /// Remove cape geometry without rebuilding the entire character
  private func removeCapeGeometry() {
    guard let nodes = characterNodes else {
      return
    }

    if let pivot = nodes.capePivot {
      pivot.removeAllActions()
      pivot.removeFromParentNode()
    }

    // Clear node references to prevent animation controller from holding old nodes
    nodes.clearCape()
    animationController.toggleCapeAnimation(false)
  }

  /// Only refresh materials based on current `skinImage` without rebuilding the entire character node
  private func updateSkinGeometry() {
    guard let nodes = characterNodes else {
      return
    }
    guard let image = skinImage else {
      return
    }
    
    // Clear texture cache to avoid using old skin cache results
    // This ensures new crop results are used each time the skin updates
    materialFactory.textureCache.clear()

    // 1. Base geometry (SCNBox) clean up old materials then regenerate materials
    if let headGeometry = nodes.head.geometry {
      // Clean up old materials
      for material in headGeometry.materials {
        material.diffuse.contents = nil
        material.ambient.contents = nil
        material.specular.contents = nil
      }
      headGeometry.materials = materialFactory.createHeadMaterials(from: image, isHat: false)
    }
    if let bodyGeometry = nodes.body.geometry {
      for material in bodyGeometry.materials {
        material.diffuse.contents = nil
        material.ambient.contents = nil
        material.specular.contents = nil
      }
      bodyGeometry.materials = materialFactory.createBodyMaterials(from: image, isJacket: false)
    }

    if let rightArmGeometry = nodes.rightArm.geometry {
      for material in rightArmGeometry.materials {
        material.diffuse.contents = nil
        material.ambient.contents = nil
        material.specular.contents = nil
      }
      rightArmGeometry.materials = materialFactory.createArmMaterials(
        from: image,
        isLeft: false,
        isSleeve: false,
        playerModel: playerModel
      )
    }
    if let leftArmGeometry = nodes.leftArm.geometry {
      for material in leftArmGeometry.materials {
        material.diffuse.contents = nil
        material.ambient.contents = nil
        material.specular.contents = nil
      }
      leftArmGeometry.materials = materialFactory.createArmMaterials(
        from: image,
        isLeft: true,
        isSleeve: false,
        playerModel: playerModel
      )
    }

    if let rightLegGeometry = nodes.rightLeg.geometry {
      for material in rightLegGeometry.materials {
        material.diffuse.contents = nil
        material.ambient.contents = nil
        material.specular.contents = nil
      }
      rightLegGeometry.materials = materialFactory.createLegMaterials(
        from: image,
        isLeft: false,
        isSleeve: false
      )
    }
    if let leftLegGeometry = nodes.leftLeg.geometry {
      for material in leftLegGeometry.materials {
        material.diffuse.contents = nil
        material.ambient.contents = nil
        material.specular.contents = nil
      }
      leftLegGeometry.materials = materialFactory.createLegMaterials(
        from: image,
        isLeft: true,
        isSleeve: false
      )
    }

    // 2. Outer layer voxels (Hat / Jacket / Sleeves) completely rebuilt based on new skin texture
    nodeBuilder.rebuildOuterLayerVoxels(
      nodes,
      skinImage: image,
      playerModel: playerModel
    )
  }
}
