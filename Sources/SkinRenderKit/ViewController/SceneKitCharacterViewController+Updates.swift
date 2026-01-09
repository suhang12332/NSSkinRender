//
//  SceneKitCharacterViewController+Updates.swift
//  SkinRenderKit
//

import SceneKit

extension SceneKitCharacterViewController {

  // MARK: - Internal Update Helpers

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
      // 不再仅通过实例相等性短路；允许外部复用同一个 NSImage 实例但更新其内容
      self.skinImage = image
      self.skinTexturePath = nil
      updateSkinGeometry()
    }
  }

  private func applyCapeUpdate(path: String? = nil, image: NSImage? = nil) {
    if let path = path {
      // path 未变化则直接返回，避免无效刷新
      guard capeTexturePath != path else {
        return
      }
      self.capeTexturePath = path
      loadCapeTexture(from: path)
      // 只在成功加载到图片时更新披风几何
      if capeImage != nil {
        updateCapeGeometry()
      }
      return
    }

    if let image = image {
      // 允许同一实例重复传入，以支持外部对 NSImage 内容的就地修改
      self.capeImage = image
      self.capeTexturePath = nil
      updateCapeGeometry()
    }
  }

  // MARK: - Public Update Methods

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

  // MARK: - Cape Geometry Helpers

  /// 根据当前 `capeImage` 更新或创建披风几何，而不重建整个人物
  private func updateCapeGeometry() {
    guard let nodes = characterNodes else {
      return
    }
    guard let image = capeImage else {
      return
    }

    if let capeNode = nodes.cape, let geometry = capeNode.geometry {
      // 清理旧材质
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
      // 如果披风动画已开启，重新刷新一次动画
      animationController.refreshCapeSwayAnimation()
    }
  }

  /// 移除披风几何而不重建整个人物
  private func removeCapeGeometry() {
    guard let nodes = characterNodes else {
      return
    }

    if let pivot = nodes.capePivot {
      pivot.removeAllActions()
      pivot.removeFromParentNode()
    }

    // 清空节点引用，防止动画控制器继续持有旧节点
    nodes.clearCape()
    animationController.toggleCapeAnimation(false)
  }

  // MARK: - Skin Geometry Helpers

  /// 根据当前 `skinImage` 只刷新材质，而不重建整个人物节点
  private func updateSkinGeometry() {
    guard let nodes = characterNodes else {
      return
    }
    guard let image = skinImage else {
      return
    }

    // 1. 基础几何（SCNBox）清理旧材质后重生成材质
    if let headGeometry = nodes.head.geometry {
      // 清理旧材质
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

    // 2. 外层体素（Hat / Jacket / Sleeves）完全根据新皮肤贴图重建
    nodeBuilder.rebuildOuterLayerVoxels(
      nodes,
      skinImage: image,
      playerModel: playerModel
    )
  }
}
