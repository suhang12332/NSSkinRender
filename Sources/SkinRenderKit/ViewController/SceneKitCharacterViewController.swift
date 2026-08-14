//
//  SceneKitCharacterViewController.swift
//  SkinRenderKit
//
//  Main view controller for rendering Minecraft character skins using SceneKit
//

import SceneKit

public class SceneKitCharacterViewController: NSViewController {

  var scnView: SCNView!
  var scene: SCNScene!

  /// Shared texture cache for optimizing cropping and transparency detection
  private let sharedTextureCache = TextureCache()
  let materialFactory: CharacterMaterialFactory
  lazy var nodeBuilder = CharacterNodeBuilder(materialFactory: materialFactory)
  let animationController = CharacterAnimationController()
  
  public override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
    // Create materialFactory with shared cache
    self.materialFactory = CharacterMaterialFactory(textureCache: sharedTextureCache)
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  public required init?(coder: NSCoder) {
    // Create materialFactory with shared cache
    self.materialFactory = CharacterMaterialFactory(textureCache: sharedTextureCache)
    super.init(coder: coder)
  }

  var characterNodes: CharacterNodeBuilder.CharacterNodes?

  var skinTexturePath: String?
  var skinImage: NSImage?
  var capeTexturePath: String?
  var capeImage: NSImage?

  var playerModel: PlayerModel = .steve
  var rotationDuration: TimeInterval = 15.0
  var backgroundColor: NSColor = .clear
  var debugMode: Bool = false

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

  var showOuterLayers: Bool = true
  var showCape: Bool = true

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
  
  public override func viewWillDisappear() {
    super.viewWillDisappear()
    // Stop animations and clean up resources immediately when page is about to close
    cleanupResources()
  }
  
  public override func viewDidDisappear() {
    super.viewDidDisappear()
    // Page is closed, ensure all resources are released
    cleanupResources()
  }

  func rebuildCharacter() {
    // Stop all animations before removing nodes
    if let oldNodes = characterNodes {
      animationController.resetAllAnimations()
      // Remove all actions from nodes
      oldNodes.root.removeAllActions()
      oldNodes.root.childNodes.forEach { $0.removeAllActions() }
    }
    
    // Remove existing character and clean up resources
    if let oldRoot = characterNodes?.root {
      // Recursively clean up geometry and materials
      cleanupNode(oldRoot)
      oldRoot.removeFromParentNode()
    }
    
    // Clear texture cache to ensure new skin textures are used
    // This avoids material display errors caused by cache confusion
    materialFactory.textureCache.clear()

    guard let skinImage = skinImage else {
      characterNodes = nil
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
  
  /// Recursively clean up node resources (geometry, materials, textures)
  private func cleanupNode(_ node: SCNNode) {
    // Clean up geometry and materials
    if let geometry = node.geometry {
      // Clear material contents to release texture references
      for material in geometry.materials {
        material.diffuse.contents = nil
        material.ambient.contents = nil
        material.specular.contents = nil
        material.normal.contents = nil
        material.emission.contents = nil
      }
      geometry.materials = []
    }
    
    // Recursively clean up children
    for child in node.childNodes {
      cleanupNode(child)
    }
  }
  
  /// Clean up all resources (called when page is closed)
  /// Can be called manually to ensure resources are released
  func cleanupResources() {
    // Stop all animations
    animationController.resetAllAnimations()
    
    // Clean up character nodes
    if let root = characterNodes?.root {
      // Remove all actions first
      root.removeAllActions()
      root.childNodes.forEach { $0.removeAllActions() }
      
      // Clean up geometry and materials
      cleanupNode(root)
      
      // Remove from scene
      root.removeFromParentNode()
    }
    
    // Clear character nodes reference
    characterNodes = nil
    
    // Clear SceneKit view resources to release GPU memory
    scnView?.scene = nil
    scnView?.delegate = nil
    
    // Clear scene reference
    scene = nil
  }
  
  deinit {
    // Final cleanup, ensure all resources are released
    cleanupResources()
    
    // Clear texture references to help ARC release image memory
    skinImage = nil
    capeImage = nil
    skinTexturePath = nil
    capeTexturePath = nil
  }
}
