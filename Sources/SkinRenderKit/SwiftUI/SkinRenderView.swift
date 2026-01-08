//
//  SkinRenderView.swift
//  SkinRenderKit
//
//  Main SwiftUI View for rendering Minecraft character skins with drag-and-drop support
//

import SwiftUI
internal import UniformTypeIdentifiers

/// Main SwiftUI View for rendering Minecraft character skins
/// Provides a simple interface for displaying character models with drag-and-drop texture customization
public struct SkinRenderView: View {

  // MARK: - State

  @State private var texturePath: String?
  @State private var skinImage: NSImage?
  @State private var capeImage: NSImage?

  // MARK: - Configuration

  let playerModel: PlayerModel
  let rotationDuration: TimeInterval
  let backgroundColor: NSColor

  // MARK: - Callbacks

  public let onSkinDropped: ((NSImage) -> Void)?
  public let onCapeDropped: ((NSImage) -> Void)?

  // MARK: - Initialization

  /// Initialize with an optional texture path
  public init(
    texturePath: String? = nil,
    capeImage: NSImage? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: texturePath)
    self._skinImage = State(initialValue: nil)
    self._capeImage = State(initialValue: capeImage)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }

  /// Initialize with a direct NSImage texture
  public init(
    skinImage: NSImage,
    capeImage: NSImage? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: nil)
    self._skinImage = State(initialValue: skinImage)
    self._capeImage = State(initialValue: capeImage)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }

  /// Initialize with mixed texture inputs
  public init(
    texturePath: String? = nil,
    capeImage: NSImage,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: texturePath)
    self._skinImage = State(initialValue: nil)
    self._capeImage = State(initialValue: capeImage)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }

  // MARK: - Body

  public var body: some View {
    Group {
      if let skinImage = skinImage {
        SceneKitCharacterViewRepresentable(
          skinImage: skinImage,
          capeImage: capeImage,
          playerModel: playerModel,
          rotationDuration: rotationDuration,
          backgroundColor: backgroundColor,
          debugMode: false
        )
      } else {
        SceneKitCharacterViewRepresentable(
          texturePath: texturePath,
          capeImage: capeImage,
          playerModel: playerModel,
          rotationDuration: rotationDuration,
          backgroundColor: backgroundColor,
          debugMode: false
        )
      }
    }
    .frame(minWidth: 400, minHeight: 300)
  }

  // MARK: - Drop Handling

  private enum DropTarget {
    case skin, cape
  }

  private func handleDrop(providers: [NSItemProvider], target: DropTarget) -> Bool {
    guard let provider = providers.first else {
      showDropError("No drag content detected")
      return false
    }

    ImageDropHandler.loadImage(from: provider) { image in
      DispatchQueue.main.async {
        guard let image = image else {
          showDropError("Failed to read image data")
          return
        }

        switch target {
        case .skin:
          handleSkinDrop(image)
        case .cape:
          handleCapeDrop(image)
        }
      }
    }

    return true
  }

  private func handleSkinDrop(_ image: NSImage) {
    switch ImageDropHandler.validateSkin(image) {
    case .valid(let validImage):
      skinImage = validImage
      texturePath = nil
      onSkinDropped?(validImage)
    case .invalidDimensions(let width, let height, let expected):
      showDropError("Skin size error: \(width)×\(height), need \(expected)")
    case .loadFailed(let message):
      showDropError(message)
    }
  }

  private func handleCapeDrop(_ image: NSImage) {
    switch ImageDropHandler.validateCape(image) {
    case .valid(let validImage):
      capeImage = validImage
      onCapeDropped?(validImage)
    case .invalidDimensions(let width, let height, let expected):
      showDropError("Cape size error: \(width)×\(height), need \(expected)")
    case .loadFailed(let message):
      showDropError(message)
    }
  }

  private func showDropError(_ message: String) {
    print("Drop error: \(message)")
  }
}
