//
//  SceneKitCharacterViewController+Convenience.swift
//  SkinRenderKit
//

import SceneKit

// MARK: - Usage Helper

extension SceneKitCharacterViewController {

  public static func presentInNewWindow(
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .gray
  ) {
    let characterVC = SceneKitCharacterViewController(
      playerModel: playerModel,
      rotationDuration: rotationDuration,
      backgroundColor: backgroundColor
    )
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
      styleMask: [.titled, .closable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "SceneKit Minecraft Character - \(playerModel.displayName)"
    window.contentViewController = characterVC
    window.makeKeyAndOrderFront(nil)
  }
}

// MARK: - Convenience Initialization

extension SceneKitCharacterViewController {

  public convenience init(
    texturePath: String,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .gray,
    debugMode: Bool = false
  ) {
    self.init()
    self.skinTexturePath = texturePath
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode
    loadTexture()
  }

  public convenience init(
    texturePath: String,
    capeTexturePath: String? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .gray,
    debugMode: Bool = false
  ) {
    self.init()
    self.skinTexturePath = texturePath
    self.capeTexturePath = capeTexturePath
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode
    loadTexture()
    if let capeTexturePath = capeTexturePath {
      loadCapeTexture(from: capeTexturePath)
    }
  }

  public convenience init(
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .gray,
    debugMode: Bool = false
  ) {
    self.init()
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode
  }

  public convenience init(
    skinImage: NSImage,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .gray,
    debugMode: Bool = false
  ) {
    self.init()
    self.skinImage = skinImage
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode
  }

  public convenience init(
    skinImage: NSImage,
    capeImage: NSImage? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .gray,
    debugMode: Bool = false
  ) {
    self.init()
    self.skinImage = skinImage
    self.capeImage = capeImage
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode
  }

  public convenience init(
    texturePath: String? = nil,
    capeImage: NSImage,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .gray,
    debugMode: Bool = false
  ) {
    self.init()
    self.skinTexturePath = texturePath
    self.capeImage = capeImage
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode
    if texturePath != nil {
      loadTexture()
    }
  }
}

// MARK: - Legacy Compatibility

extension SceneKitCharacterViewController {
  /// Legacy enum for backward compatibility
  public typealias LimbBottomFlipMode = TextureProcessor.FlipMode
}

#Preview {
  SceneKitCharacterViewController(rotationDuration: 12)
}
