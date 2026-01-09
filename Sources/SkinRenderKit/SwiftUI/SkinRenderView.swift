//
//  SkinRenderView.swift
//  SkinRenderKit
//
//  Main SwiftUI View for rendering Minecraft character skins with drag-and-drop support
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers

/// Main SwiftUI View for rendering Minecraft character skins
/// Provides a simple interface for displaying character models with drag-and-drop texture customization
public struct SkinRenderView: View {

  // MARK: - State

  @State private var texturePath: String?
  @State private var internalSkinImage: NSImage?
  
  // 皮肤的外部绑定（可选）
  private var externalSkinImageBinding: Binding<NSImage?>?
  
  // 皮肤路径的外部绑定（可选）
  private var externalTexturePathBinding: Binding<String?>?
  
  // 披风的外部绑定（必需，披风只支持 Binding）
  private var capeImageBinding: Binding<NSImage?>?
  
  // 用于跟踪外部绑定变化的辅助状态
  @State private var externalCapeImageTracker: NSImage?
  
  // 计算属性：皮肤的当前值
  private var currentSkinImage: NSImage? {
    externalSkinImageBinding?.wrappedValue ?? internalSkinImage
  }
  
  // 计算属性：皮肤路径的当前值
  private var currentTexturePath: String? {
    externalTexturePathBinding?.wrappedValue ?? texturePath
  }
  
  // 计算属性：披风的当前值（只支持 Binding）
  private var currentCapeImage: NSImage? {
    capeImageBinding?.wrappedValue
  }


  // MARK: - Configuration

  let playerModel: PlayerModel
  let rotationDuration: TimeInterval
  let backgroundColor: NSColor

  // MARK: - Callbacks

  public let onSkinDropped: ((NSImage) -> Void)?
  public let onCapeDropped: ((NSImage) -> Void)?

  // MARK: - Initialization

  /// Initialize with texture path for skin (cape must use Binding)
  public init(
    texturePath: String? = nil,
    capeImage: Binding<NSImage?>? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: texturePath)
    self._internalSkinImage = State(initialValue: nil)
    self.externalSkinImageBinding = nil
    self.externalTexturePathBinding = nil
    self.capeImageBinding = capeImage
    self._externalCapeImageTracker = State(initialValue: capeImage?.wrappedValue)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }
  
  /// Initialize with texture path binding for skin (cape must use Binding)
  public init(
    texturePath: Binding<String?>,
    capeImage: Binding<NSImage?>? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: texturePath.wrappedValue)
    self._internalSkinImage = State(initialValue: nil)
    self.externalSkinImageBinding = nil
    self.externalTexturePathBinding = texturePath
    self.capeImageBinding = capeImage
    self._externalCapeImageTracker = State(initialValue: capeImage?.wrappedValue)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }

  /// Initialize with direct NSImage texture for skin (cape must use Binding)
  public init(
    skinImage: NSImage,
    capeImage: Binding<NSImage?>? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: nil)
    self._internalSkinImage = State(initialValue: skinImage)
    self.externalSkinImageBinding = nil
    self.externalTexturePathBinding = nil
    self.capeImageBinding = capeImage
    self._externalCapeImageTracker = State(initialValue: capeImage?.wrappedValue)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }
  
  /// Initialize with skin image binding (cape must use Binding)
  public init(
    skinImage: Binding<NSImage?>,
    capeImage: Binding<NSImage?>? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: nil)
    self._internalSkinImage = State(initialValue: nil)
    self.externalSkinImageBinding = skinImage
    self.externalTexturePathBinding = nil
    self.capeImageBinding = capeImage
    self._externalCapeImageTracker = State(initialValue: capeImage?.wrappedValue)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }

  // MARK: - Body

  public var body: some View {
    // 如果使用外部绑定，检查并同步 tracker（使用 let _ = 触发副作用）
    let currentCapeImage = currentCapeImage
    let currentSkinImage = currentSkinImage
    let currentTexturePath = currentTexturePath
    
    return Group {
      if let skinImage = currentSkinImage {
        SceneKitCharacterViewRepresentable(
          skinImage: skinImage,
          capeImage: currentCapeImage,
          playerModel: playerModel,
          rotationDuration: rotationDuration,
          backgroundColor: backgroundColor,
          debugMode: false
        )
      } else {
        SceneKitCharacterViewRepresentable(
          texturePath: currentTexturePath,
          capeImage: currentCapeImage,
          playerModel: playerModel,
          rotationDuration: rotationDuration,
          backgroundColor: backgroundColor,
          debugMode: false
        )
      }
    }
    .frame(minWidth: 400, minHeight: 300)
    .contentShape(Rectangle())
    .onTapGesture {
      showFileImporter()
    }
    .onDrop(
      of: [UTType.image, UTType.fileURL, UTType.png, UTType.jpeg],
      isTargeted: nil
    ) { providers in
      handleDrop(providers: providers, target: .skin)
    }
    // 不再依赖 renderKey / .id 强制重建 NSViewController，
    // 让 SceneKitCharacterViewRepresentable 的 updateNSViewController 接管更新逻辑
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
      // 皮肤变化时更新状态，交由 SceneKitCharacterViewRepresentable 驱动局部刷新
      if let binding = externalSkinImageBinding {
        binding.wrappedValue = validImage
        // 如果有路径绑定，清空它
        externalTexturePathBinding?.wrappedValue = nil
      } else {
        internalSkinImage = validImage
        texturePath = nil
      }
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
      // 披风变化时更新绑定（披风只支持 Binding），交由 SceneKitCharacterViewRepresentable 驱动局部刷新
      if let binding = capeImageBinding {
        binding.wrappedValue = validImage
        onCapeDropped?(validImage)
      } else {
        showDropError("Cape requires Binding. Please use capeImage: Binding<NSImage?> parameter.")
      }
    case .invalidDimensions(let width, let height, let expected):
      showDropError("Cape size error: \(width)×\(height), need \(expected)")
    case .loadFailed(let message):
      showDropError(message)
    }
  }

  private func showDropError(_ message: String) {
    // 调试日志已去掉，如需用户可见的提示可在此处添加 UI 呈现逻辑
  }

  // MARK: - File Import

  private func showFileImporter() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .jpeg, .image]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.prompt = "选择"
    panel.message = "选择一个 Minecraft 皮肤纹理文件（64x64 或 64x32）"

    panel.begin { response in
      if response == .OK, let url = panel.url {
        loadSkinFromFile(at: url)
      }
    }
  }

  private func loadSkinFromFile(at url: URL) {
    guard let image = NSImage(contentsOf: url) else {
      showDropError("无法读取图片文件")
      return
    }

    handleSkinDrop(image)
  }
}
