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
    print("[SceneKitCharacterViewController] applyCapeUpdate 被调用")
    print("[SceneKitCharacterViewController]   path: \(path ?? "nil")")
    print("[SceneKitCharacterViewController]   image: \(image != nil ? "有值" : "nil")")
    
    if let path = path {
      // path 未变化则直接返回，避免无效刷新
      guard capeTexturePath != path else {
        print("[SceneKitCharacterViewController] applyCapeUpdate 跳过：path 未变化")
        return
      }
      print("[SceneKitCharacterViewController] applyCapeUpdate 更新 path")
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
      print("[SceneKitCharacterViewController] applyCapeUpdate 更新图像不重建整个人物")
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
    print("[SceneKitCharacterViewController] updateCapeTexture(image:) 被调用")
    print("[SceneKitCharacterViewController] 当前 capeImage: \(capeImage != nil ? "有值" : "nil")")
    print("[SceneKitCharacterViewController] 新 image: \(image != nil ? "有值" : "nil")")
    print("[SceneKitCharacterViewController] 是否为相同实例: \(capeImage === image)")
    applyCapeUpdate(image: image)
  }

  public func removeCapeTexture() {
    print("[SceneKitCharacterViewController] removeCapeTexture() 被调用")
    print("[SceneKitCharacterViewController] 当前 capeImage: \(capeImage != nil ? "有值" : "nil")")
    print("[SceneKitCharacterViewController] 当前 capeTexturePath: \(capeTexturePath ?? "nil")")
    // Skip if already no cape
    guard capeImage != nil || capeTexturePath != nil else {
      print("[SceneKitCharacterViewController] removeCapeTexture() 跳过：没有披风需要移除")
      return
    }
    print("[SceneKitCharacterViewController] removeCapeTexture() 执行移除操作（不重建整个人物）")
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
      print("[SceneKitCharacterViewController] updateCapeGeometry 跳过：characterNodes 为 nil")
      return
    }
    guard let image = capeImage else {
      print("[SceneKitCharacterViewController] updateCapeGeometry 跳过：capeImage 为 nil")
      return
    }

    if let capeNode = nodes.cape, let geometry = capeNode.geometry {
      print("[SceneKitCharacterViewController] updateCapeGeometry: 直接更新现有披风材质")
      geometry.materials = materialFactory.createCapeMaterials(from: image)
    } else {
      print("[SceneKitCharacterViewController] updateCapeGeometry: 当前无披风，创建新的披风节点")
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
      print("[SceneKitCharacterViewController] removeCapeGeometry 跳过：characterNodes 为 nil")
      return
    }

    if let pivot = nodes.capePivot {
      print("[SceneKitCharacterViewController] removeCapeGeometry: 从场景中移除 capePivot")
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
      print("[SceneKitCharacterViewController] updateSkinGeometry 跳过：characterNodes 为 nil")
      return
    }
    guard let image = skinImage else {
      print("[SceneKitCharacterViewController] updateSkinGeometry 跳过：skinImage 为 nil")
      return
    }

    // 1. 基础几何（SCNBox）直接用 materialFactory 重生成材质
    if let headGeometry = nodes.head.geometry {
      headGeometry.materials = materialFactory.createHeadMaterials(from: image, isHat: false)
    }
    if let bodyGeometry = nodes.body.geometry {
      bodyGeometry.materials = materialFactory.createBodyMaterials(from: image, isJacket: false)
    }

    if let rightArmGeometry = nodes.rightArm.geometry {
      rightArmGeometry.materials = materialFactory.createArmMaterials(
        from: image,
        isLeft: false,
        isSleeve: false,
        playerModel: playerModel
      )
    }
    if let leftArmGeometry = nodes.leftArm.geometry {
      leftArmGeometry.materials = materialFactory.createArmMaterials(
        from: image,
        isLeft: true,
        isSleeve: false,
        playerModel: playerModel
      )
    }

    if let rightLegGeometry = nodes.rightLeg.geometry {
      rightLegGeometry.materials = materialFactory.createLegMaterials(
        from: image,
        isLeft: false,
        isSleeve: false
      )
    }
    if let leftLegGeometry = nodes.leftLeg.geometry {
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
