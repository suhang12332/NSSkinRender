//
//  SceneKitCharacterViewController.swift
//  SkinRenderKit
//
//  Main view controller for rendering Minecraft character skins using SceneKit
//

import SceneKit

public class SceneKitCharacterViewController: NSViewController {

  // MARK: - Scene Components

  private var scnView: SCNView!
  private var scene: SCNScene!

  // MARK: - Dependencies

  private let materialFactory = CharacterMaterialFactory()
  private lazy var nodeBuilder = CharacterNodeBuilder(materialFactory: materialFactory)
  private let animationController = CharacterAnimationController()

  // MARK: - Character State

  private var characterNodes: CharacterNodeBuilder.CharacterNodes?

  // MARK: - Texture Settings

  private var skinTexturePath: String?
  private var skinImage: NSImage?
  private var capeTexturePath: String?
  private var capeImage: NSImage?

  // MARK: - Configuration

  private var playerModel: PlayerModel = .steve
  private var rotationDuration: TimeInterval = 15.0
  private var backgroundColor: NSColor = .gray
  private var debugMode: Bool = false

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

  private var showOuterLayers: Bool = true
  private var showCape: Bool = true

  // MARK: - Debug UI

  private lazy var toggleButton: NSButton = {
    let button = NSButton(frame: NSRect(x: 20, y: 20, width: 130, height: 30))
    button.title = showOuterLayers ? "Hide Outer Layers" : "Show Outer Layers"
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(toggleOuterLayers)
    button.autoresizingMask = [.maxXMargin, .maxYMargin]
    return button
  }()

  private lazy var modelTypeButton: NSButton = {
    let button = NSButton(frame: NSRect(x: 20, y: 60, width: 130, height: 30))
    button.title = "Switch to \(playerModel == .steve ? "Alex" : "Steve")"
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(switchModelType)
    button.autoresizingMask = [.maxXMargin, .maxYMargin]
    return button
  }()

  private lazy var capeToggleButton: NSButton = {
    let button = NSButton(frame: NSRect(x: 20, y: 100, width: 130, height: 30))
    button.title = showCape ? "Hide Cape" : "Show Cape"
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(toggleCape)
    button.autoresizingMask = [.maxXMargin, .maxYMargin]
    return button
  }()

  private lazy var capeAnimationButton: NSButton = {
    let button = NSButton(frame: NSRect(x: 20, y: 140, width: 130, height: 30))
    button.title = "Disable Animation"
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(toggleCapeAnimationAction)
    button.autoresizingMask = [.maxXMargin, .maxYMargin]
    return button
  }()

  private lazy var walkingAnimationButton: NSButton = {
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
    if skinImage == nil {
      loadDefaultTexture()
    }

    setupScene()
    rebuildCharacter()
    setupCamera()
    setupLighting()
    setupUI()
    setupGestureRecognizers()

    scnView.allowsCameraControl = true
    scnView.backgroundColor = backgroundColor
  }

  // MARK: - Setup

  private func setupScene() {
    scene = SCNScene()
    scnView.scene = scene
  }

  private func setupCamera() {
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(0, 30, 30)
    cameraNode.look(at: SCNVector3(0, 10, 0))
    scene.rootNode.addChildNode(cameraNode)
  }

  private func setupLighting() {
    // Ambient light
    let ambientLight = SCNNode()
    ambientLight.light = SCNLight()
    ambientLight.light?.type = .ambient
    ambientLight.light?.intensity = 300
    scene.rootNode.addChildNode(ambientLight)

    // Directional light
    let directionalLight = SCNNode()
    directionalLight.light = SCNLight()
    directionalLight.light?.type = .directional
    directionalLight.light?.intensity = 500
    directionalLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
    scene.rootNode.addChildNode(directionalLight)
  }

  private func setupUI() {
    guard debugMode else { return }
    view.addSubview(toggleButton)
    view.addSubview(modelTypeButton)
    view.addSubview(capeToggleButton)
    view.addSubview(capeAnimationButton)
    view.addSubview(walkingAnimationButton)
  }

  private func setupGestureRecognizers() {
    let rightClickGesture = NSClickGestureRecognizer(
      target: self,
      action: #selector(handleRightClick(_:))
    )
    rightClickGesture.buttonMask = 0x2
    scnView.addGestureRecognizer(rightClickGesture)
  }

  // MARK: - Character Building

  private func rebuildCharacter() {
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

  // MARK: - Texture Loading

  private func loadTexture() {
    guard let texturePath = skinTexturePath else { return }
    if let image = NSImage(contentsOfFile: texturePath) {
      self.skinImage = image
    } else {
      loadDefaultTexture()
    }
  }

  private func loadCapeTexture(from path: String) {
    if let image = NSImage(contentsOfFile: path) {
      self.capeImage = image
    }
  }

  private func loadDefaultTexture() {
    if let resourceURL = Bundle.module.url(forResource: "alex", withExtension: "png"),
       let image = NSImage(contentsOf: resourceURL) {
      self.skinImage = image
    } else {
      self.skinImage = NSImage(named: "Skin")
    }
  }

  // MARK: - Public Update Methods

  public func updateTexture(path: String) {
    self.skinTexturePath = path
    loadTexture()
    if skinImage != nil {
      rebuildCharacter()
    }
  }

  public func updateTexture(image: NSImage) {
    self.skinImage = image
    self.skinTexturePath = nil
    rebuildCharacter()
  }

  public func updateRotationDuration(_ duration: TimeInterval) {
    self.rotationDuration = duration
    animationController.updateRotationDuration(duration)
  }

  public func updateBackgroundColor(_ color: NSColor) {
    self.backgroundColor = color
    scnView?.backgroundColor = color
  }

  public func updateCapeTexture(path: String) {
    self.capeTexturePath = path
    loadCapeTexture(from: path)
    rebuildCharacter()
  }

  public func updateCapeTexture(image: NSImage) {
    self.capeImage = image
    self.capeTexturePath = nil
    rebuildCharacter()
  }

  public func removeCapeTexture() {
    self.capeImage = nil
    self.capeTexturePath = nil
    rebuildCharacter()
  }

  public func updatePlayerModel(_ model: PlayerModel) {
    self.playerModel = model
    rebuildCharacter()
  }

  public func updateShowButtons(_ show: Bool) {
    guard self.debugMode != show else { return }
    self.debugMode = show

    if !show {
      toggleButton.removeFromSuperview()
      modelTypeButton.removeFromSuperview()
      capeToggleButton.removeFromSuperview()
      capeAnimationButton.removeFromSuperview()
      walkingAnimationButton.removeFromSuperview()
    } else {
      setupUI()
    }
  }

  public func toggleCapeAnimation(_ enabled: Bool) {
    animationController.toggleCapeAnimation(enabled)
  }

  // MARK: - Action Handlers

  @objc private func handleRightClick(_ gestureRecognizer: NSClickGestureRecognizer) {
    let location = gestureRecognizer.location(in: scnView)
    if isPointOverUIButton(location) { return }
    toggleWalkingAnimationAction()
  }

  @objc private func toggleOuterLayers() {
    showOuterLayers.toggle()
    characterNodes?.setOuterLayersHidden(!showOuterLayers)
    toggleButton.title = showOuterLayers ? "Hide Outer Layers" : "Show Outer Layers"
  }

  @objc private func toggleCape() {
    showCape.toggle()
    characterNodes?.setCapeHidden(!showCape)
    capeToggleButton.title = showCape ? "Hide Cape" : "Show Cape"
  }

  @objc private func toggleCapeAnimationAction() {
    let newState = !animationController.capeSwayEnabled
    animationController.toggleCapeAnimation(newState)
    capeAnimationButton.title = newState ? "Disable Animation" : "Enable Animation"
  }

  @objc private func switchModelType() {
    playerModel = (playerModel == .steve) ? .alex : .steve
    modelTypeButton.title = "Switch to \(playerModel == .steve ? "Alex" : "Steve")"
    rebuildCharacter()
  }

  @objc private func toggleWalkingAnimationAction() {
    animationController.toggleWalkingAnimation()
    walkingAnimationButton.title = animationController.walkingEnabled ? "Stop Walking" : "Start Walking"
  }

  private func isPointOverUIButton(_ point: CGPoint) -> Bool {
    guard debugMode else { return false }
    let buttons = [toggleButton, modelTypeButton, capeToggleButton, capeAnimationButton, walkingAnimationButton]
    return buttons.contains { $0.frame.contains(point) }
  }
}

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
