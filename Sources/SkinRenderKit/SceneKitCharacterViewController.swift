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
  var backgroundColor: NSColor = .gray
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

  lazy var toggleButton: NSButton = {
    let button = NSButton(frame: NSRect(x: 20, y: 20, width: 130, height: 30))
    button.title = showOuterLayers ? "Hide Outer Layers" : "Show Outer Layers"
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(toggleOuterLayers)
    button.autoresizingMask = [.maxXMargin, .maxYMargin]
    return button
  }()

  lazy var modelTypeButton: NSButton = {
    let button = NSButton(frame: NSRect(x: 20, y: 60, width: 130, height: 30))
    button.title = "Switch to \(playerModel == .steve ? "Alex" : "Steve")"
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(switchModelType)
    button.autoresizingMask = [.maxXMargin, .maxYMargin]
    return button
  }()

  lazy var capeToggleButton: NSButton = {
    let button = NSButton(frame: NSRect(x: 20, y: 100, width: 130, height: 30))
    button.title = showCape ? "Hide Cape" : "Show Cape"
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(toggleCape)
    button.autoresizingMask = [.maxXMargin, .maxYMargin]
    return button
  }()

  lazy var capeAnimationButton: NSButton = {
    let button = NSButton(frame: NSRect(x: 20, y: 140, width: 130, height: 30))
    button.title = "Disable Animation"
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(toggleCapeAnimationAction)
    button.autoresizingMask = [.maxXMargin, .maxYMargin]
    return button
  }()

  lazy var walkingAnimationButton: NSButton = {
    let button = NSButton(frame: NSRect(x: 20, y: 180, width: 130, height: 30))
    button.title = "Start Walking"
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(toggleWalkingAnimationAction)
    button.autoresizingMask = [.maxXMargin, .maxYMargin]
    return button
  }()

  // MARK: - Lifecycle

  public override func loadView() {
    scnView = SCNView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    self.view = scnView
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    // Load default texture if none set
    loadDefaultTextureIfNeeded()

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

    guard let skinImage = skinImage else { return }

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

    // Resume walking if it was enabled
    if animationController.walkingEnabled {
      animationController.startWalkingAnimation()
    }

    // Apply visibility state
    nodes.setOuterLayersHidden(!showOuterLayers)
    nodes.setCapeHidden(!showCape)
  }
}
