//
//  SceneKitCharacterViewController.swift
//  SkinRenderKit
//
//  Main view controller for rendering Minecraft character skins using SceneKit
//

import SceneKit

public class SceneKitCharacterViewController: NSViewController {

  // MARK: - Scene Components

  var scnView: SCNView!
  var scene: SCNScene!

  // MARK: - Dependencies

  let materialFactory = CharacterMaterialFactory()
  lazy var nodeBuilder = CharacterNodeBuilder(materialFactory: materialFactory)
  let animationController = CharacterAnimationController()

  // MARK: - Character State

  var characterNodes: CharacterNodeBuilder.CharacterNodes?

  // MARK: - Texture Settings

  var skinTexturePath: String?
  var skinImage: NSImage?
  var capeTexturePath: String?
  var capeImage: NSImage?

  // MARK: - Configuration

  var playerModel: PlayerModel = .steve
  var rotationDuration: TimeInterval = 15.0
  var backgroundColor: NSColor = .clear
  var debugMode: Bool = false

  // MARK: - Bottom Face Configuration

  /// Limb bottom-face flip configuration
  public var limbBottomFlipMode: TextureProcessor.FlipMode {
    get { materialFactory.bottomFaceConfig.limbFlipMode }
    set { materialFactory.bottomFaceConfig.limbFlipMode = newValue }
  }

  public var limbBottomRotate180: Bool {
    get { materialFactory.bottomFaceConfig.limbRotate180 }
    set { materialFactory.bottomFaceConfig.limbRotate180 = newValue }
  }

  public var headBodyBottomFlipMode: TextureProcessor.FlipMode {
    get { materialFactory.bottomFaceConfig.headBodyFlipMode }
    set { materialFactory.bottomFaceConfig.headBodyFlipMode = newValue }
  }

  public var headBodyBottomRotate180: Bool {
    get { materialFactory.bottomFaceConfig.headBodyRotate180 }
    set { materialFactory.bottomFaceConfig.headBodyRotate180 = newValue }
  }

  // MARK: - UI State

  var showOuterLayers: Bool = true
  var showCape: Bool = true

  // MARK: - Debug UI

  private enum DebugButtonConfig {
    static let xPosition: CGFloat = 20
    static let width: CGFloat = 130
    static let height: CGFloat = 30
    static let verticalSpacing: CGFloat = 40
  }

  lazy var toggleButton: NSButton = {
    createDebugButton(
      yPosition: 20,
      title: showOuterLayers ? "Hide Outer Layers" : "Show Outer Layers",
      action: #selector(toggleOuterLayers)
    )
  }()

  lazy var modelTypeButton: NSButton = {
    createDebugButton(
      yPosition: 60,
      title: "Switch to \(playerModel == .steve ? "Alex" : "Steve")",
      action: #selector(switchModelType)
    )
  }()

  lazy var capeToggleButton: NSButton = {
    createDebugButton(
      yPosition: 100,
      title: showCape ? "Hide Cape" : "Show Cape",
      action: #selector(toggleCape)
    )
  }()

  lazy var capeAnimationButton: NSButton = {
    createDebugButton(
      yPosition: 140,
      title: "Disable Animation",
      action: #selector(toggleCapeAnimationAction)
    )
  }()

  lazy var walkingAnimationButton: NSButton = {
    createDebugButton(
      yPosition: 180,
      title: "Start Walking",
      action: #selector(toggleWalkingAnimationAction)
    )
  }()

  private func createDebugButton(yPosition: CGFloat, title: String, action: Selector) -> NSButton {
    let button = NSButton(
      frame: NSRect(
        x: DebugButtonConfig.xPosition,
        y: yPosition,
        width: DebugButtonConfig.width,
        height: DebugButtonConfig.height
      )
    )
    button.title = title
    button.bezelStyle = .rounded
    button.target = self
    button.action = action
    button.autoresizingMask = [.maxXMargin, .maxYMargin]
    return button
  }

  // MARK: - Lifecycle

  public override func loadView() {
    scnView = SCNView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    self.view = scnView
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    // Load default texture if none set
    ensureDefaultTextureLoaded(rebuild: false)

    setupScene()
    rebuildCharacter()
    setupCamera()
    setupLighting()
    setupUI()
    setupGestureRecognizers()
  }

  // MARK: - Character Building

  func rebuildCharacter() {
    // Remove existing character
    characterNodes?.root.removeFromParentNode()

    guard let skinImage = skinImage else {
      return
    }

    // Build new character
    let nodes = nodeBuilder.build(
      skinImage: skinImage,
      capeImage: capeImage,
      playerModel: playerModel
    )

    scene.rootNode.addChildNode(nodes.root)
    characterNodes = nodes

    // Setup animations
    animationController.attach(to: nodes)
    animationController.rotationDuration = rotationDuration
    animationController.setupRotationAnimation()
    animationController.addCapeSwayAnimation()

    // Start walking animation by default
    animationController.startWalkingAnimation()

    // Apply visibility state
    nodes.setOuterLayersHidden(!showOuterLayers)
    nodes.setCapeHidden(!showCape)

    // Enable shadow casting for character
    enableShadowCasting(for: nodes.root)
  }
}
