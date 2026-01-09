//
//  SceneKitCharacterViewRepresentable.swift
//  SkinRenderKit
//
//  SwiftUI bridge for NSViewController-based character rendering
//

import AppKit
import SwiftUI

/// SwiftUI bridge for wrapping NSViewController to render Minecraft character skins
/// This representable allows integration of SceneKit-based character rendering into SwiftUI views
public struct SceneKitCharacterViewRepresentable: NSViewControllerRepresentable {
  
  // MARK: - Equatable Conformance
  
  // Note: NSViewControllerRepresentable doesn't require Equatable, but implementing it
  // helps SwiftUI detect changes more reliably, especially for Optional properties

  // MARK: - Properties

  let texturePath: String?
  let skinImage: NSImage?
  let capeImage: NSImage?
  let playerModel: PlayerModel
  let rotationDuration: TimeInterval
  let backgroundColor: NSColor
  let debugMode: Bool

  // MARK: - Initializers

  /// Initialize with optional texture path for skin
  public init(
    texturePath: String? = nil,
    capeImage: NSImage? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    debugMode: Bool = false
  ) {
    self.texturePath = texturePath
    self.skinImage = nil
    self.capeImage = capeImage
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode
  }

  /// Initialize with direct NSImage textures
  public init(
    skinImage: NSImage,
    capeImage: NSImage? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    debugMode: Bool = false
  ) {
    self.texturePath = nil
    self.skinImage = skinImage
    self.capeImage = capeImage
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode
  }

  /// Initialize with mixed texture inputs (path for skin, image for cape)
  public init(
    texturePath: String? = nil,
    capeImage: NSImage,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    debugMode: Bool = false
  ) {
    self.texturePath = texturePath
    self.skinImage = nil
    self.capeImage = capeImage
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode
  }


  // MARK: - NSViewControllerRepresentable

  public func makeNSViewController(context: Context) -> SceneKitCharacterViewController {
    let controller: SceneKitCharacterViewController
    
    // 根据可用的纹理数据创建控制器
    if let skinImage = skinImage {
      controller = SceneKitCharacterViewController(
        skinImage: skinImage,
        capeImage: capeImage,
        playerModel: playerModel,
        rotationDuration: rotationDuration,
        backgroundColor: backgroundColor,
        debugMode: debugMode
      )
    } else if let texturePath = texturePath {
      controller = SceneKitCharacterViewController(
        texturePath: texturePath,
        capeTexturePath: nil,
        playerModel: playerModel,
        rotationDuration: rotationDuration,
        backgroundColor: backgroundColor,
        debugMode: debugMode
      )
      // 如果有 capeImage，直接设置属性（视图加载前）
      if let capeImage = capeImage {
        controller.capeImage = capeImage
        controller.capeTexturePath = nil
      }
    } else {
      controller = SceneKitCharacterViewController(
        playerModel: playerModel,
        rotationDuration: rotationDuration,
        backgroundColor: backgroundColor,
        debugMode: debugMode
      )
      // 如果有 capeImage，直接设置属性（视图加载前）
      if let capeImage = capeImage {
        controller.capeImage = capeImage
        controller.capeTexturePath = nil
      }
    }
    
    return controller
  }

  public func updateNSViewController(
    _ nsViewController: SceneKitCharacterViewController,
    context: Context
  ) {
    // Update player model
    nsViewController.updatePlayerModel(playerModel)

    // Update skin texture
    if let skinImage = skinImage {
      nsViewController.updateTexture(image: skinImage)
    } else if let texturePath = texturePath {
      nsViewController.updateTexture(path: texturePath)
    } else {
      nsViewController.loadDefaultTexture()
    }

    // Update cape texture (only via image memory)
    if let capeImage = capeImage {
      nsViewController.updateCapeTexture(image: capeImage)
    } else {
      nsViewController.removeCapeTexture()
    }

    // Update rotation and background
    nsViewController.updateRotationDuration(rotationDuration)
    nsViewController.updateBackgroundColor(backgroundColor)
  }
}
