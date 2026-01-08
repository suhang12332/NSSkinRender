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

  // MARK: - Properties

  let texturePath: String?
  let skinImage: NSImage?
  let capeTexturePath: String?
  let capeImage: NSImage?
  let playerModel: PlayerModel
  let rotationDuration: TimeInterval
  let backgroundColor: NSColor
  let debugMode: Bool

  // MARK: - Initializers

  /// Initialize with optional texture paths
  public init(
    texturePath: String? = nil,
    capeTexturePath: String? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    debugMode: Bool = false
  ) {
    self.texturePath = texturePath
    self.skinImage = nil
    self.capeTexturePath = capeTexturePath
    self.capeImage = nil
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
    self.capeTexturePath = nil
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
    self.capeTexturePath = nil
    self.capeImage = capeImage
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode
  }

  /// Initialize with mixed texture inputs (image for skin, path for cape)
  public init(
    skinImage: NSImage,
    capeTexturePath: String,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    debugMode: Bool = false
  ) {
    self.texturePath = nil
    self.skinImage = skinImage
    self.capeTexturePath = capeTexturePath
    self.capeImage = nil
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode
  }

  // MARK: - NSViewControllerRepresentable

  public func makeNSViewController(context: Context) -> SceneKitCharacterViewController {
    // if let skinImage = skinImage {
    //   return SceneKitCharacterViewController(
    //     skinImage: skinImage,
    //     capeImage: capeImage,
    //     playerModel: playerModel,
    //     rotationDuration: rotationDuration,
    //     backgroundColor: backgroundColor,
    //     debugMode: debugMode
    //   )
    // } else if let texturePath = texturePath {
    //   return SceneKitCharacterViewController(
    //     texturePath: texturePath,
    //     capeTexturePath: capeTexturePath,
    //     playerModel: playerModel,
    //     rotationDuration: rotationDuration,
    //     backgroundColor: backgroundColor,
    //     debugMode: debugMode
    //   )
    // } else if let capeImage = capeImage {
    //   let controller = SceneKitCharacterViewController(
    //     playerModel: playerModel,
    //     rotationDuration: rotationDuration,
    //     backgroundColor: backgroundColor,
    //     debugMode: debugMode
    //   )
    //   controller.updateCapeTexture(image: capeImage)
    //   return controller
    // } else {
    //   return SceneKitCharacterViewController(
    //     playerModel: playerModel,
    //     rotationDuration: rotationDuration,
    //     backgroundColor: backgroundColor,
    //     debugMode: debugMode
    //   )
    // }

    return SceneKitCharacterViewController(
      playerModel: playerModel,
      rotationDuration: rotationDuration,
      backgroundColor: backgroundColor,
      debugMode: debugMode
    )
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

    // Update cape texture
    if let capeImage = capeImage {
      nsViewController.updateCapeTexture(image: capeImage)
    } else if let capeTexturePath = capeTexturePath {
      nsViewController.updateCapeTexture(path: capeTexturePath)
    } else {
      nsViewController.removeCapeTexture()
    }

    // Update rotation and background
    nsViewController.updateRotationDuration(rotationDuration)
    nsViewController.updateBackgroundColor(backgroundColor)
  }
}
