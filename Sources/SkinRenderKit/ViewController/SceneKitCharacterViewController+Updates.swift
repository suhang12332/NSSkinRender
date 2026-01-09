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
        rebuildCharacter()
      }
      return
    }

    if let image = image {
      // Skip if same image instance
      guard skinImage !== image else { return }
      self.skinImage = image
      self.skinTexturePath = nil
      rebuildCharacter()
    }
  }

  private func applyCapeUpdate(path: String? = nil, image: NSImage? = nil) {
    print("[SceneKitCharacterViewController] applyCapeUpdate 被调用")
    print("[SceneKitCharacterViewController]   path: \(path ?? "nil")")
    print("[SceneKitCharacterViewController]   image: \(image != nil ? "有值" : "nil")")
    
    if let path = path {
      // Skip if path unchanged
      guard capeTexturePath != path else {
        print("[SceneKitCharacterViewController] applyCapeUpdate 跳过：path 未变化")
        return
      }
      print("[SceneKitCharacterViewController] applyCapeUpdate 更新 path")
      self.capeTexturePath = path
      loadCapeTexture(from: path)
      if capeImage != nil {
        print("[SceneKitCharacterViewController] applyCapeUpdate 调用 rebuildCharacter()")
        rebuildCharacter()
      }
      return
    }

    if let image = image {
      // Skip if same image instance
      guard capeImage !== image else {
        print("[SceneKitCharacterViewController] applyCapeUpdate 跳过：相同图像实例")
        return
      }
      print("[SceneKitCharacterViewController] applyCapeUpdate 更新图像并重建")
      self.capeImage = image
      self.capeTexturePath = nil
      rebuildCharacter()
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
    print("[SceneKitCharacterViewController] removeCapeTexture() 执行移除操作")
    self.capeImage = nil
    self.capeTexturePath = nil
    print("[SceneKitCharacterViewController] removeCapeTexture() 调用 rebuildCharacter()")
    rebuildCharacter()
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
}
