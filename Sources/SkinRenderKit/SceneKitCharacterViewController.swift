//
//  SceneKitCharacterViewController.swift
//  SkinRender
//

import SceneKit

public class SceneKitCharacterViewController: NSViewController {

  private var scnView: SCNView!
  private var scene: SCNScene!

  // MARK: - Texture Settings

  private var skinTexturePath: String?
  private var skinImage: NSImage?

  // MARK: - Cape Texture Settings

  private var capeTexturePath: String?
  private var capeImage: NSImage?

  private var playerModel: PlayerModel = .steve

  /// The time required for one complete rotation
  private var rotationDuration: TimeInterval = 15.0

  /// Scene background color settings
  private var backgroundColor: NSColor = .gray

  /// UI control settings
  private var debugMode: Bool = false

  // Limb bottom-face flip configuration
  public enum LimbBottomFlipMode {
    case none
    case horizontal
    case vertical
    case both
  }
  public var limbBottomFlipMode: LimbBottomFlipMode = .horizontal
  public var limbBottomRotate180: Bool = true
  public var headBodyBottomFlipMode: LimbBottomFlipMode = .horizontal
  public var headBodyBottomRotate180: Bool = true

  // MARK: - Character body part nodes
  private var characterGroup: SCNNode!
  private var headNode: SCNNode!
  private var hatNode: SCNNode!
  /// Group for head + hat to sync movement
  private var headGroupNode: SCNNode!
  private var bodyNode: SCNNode!
  private var jacketNode: SCNNode!
  private var rightArmNode: SCNNode!
  private var rightArmSleeveNode: SCNNode!
  private var leftArmNode: SCNNode!
  private var leftArmSleeveNode: SCNNode!
  // Limb group nodes for proper pivot (at top hinge)
  private var rightArmGroupNode: SCNNode!
  private var leftArmGroupNode: SCNNode!
  private var rightLegNode: SCNNode!
  private var rightLegSleeveNode: SCNNode!
  private var leftLegNode: SCNNode!
  private var leftLegSleeveNode: SCNNode!
  private var rightLegGroupNode: SCNNode!
  private var leftLegGroupNode: SCNNode!
  private var capeNode: SCNNode!
  /// Pivot for cape rotation/attachment
  private var capePivotNode: SCNNode!

  // Outer layer display control
  private var showOuterLayers: Bool = true
  private lazy var toggleButton: NSButton = {
    let toggleButton = NSButton(frame: NSRect(x: 20, y: 20, width: 130, height: 30))
    toggleButton.title = showOuterLayers ? "Hide Outer Layers" : "Show Outer Layers"
    toggleButton.bezelStyle = .rounded
    toggleButton.target = self
    toggleButton.action = #selector(toggleOuterLayers)
    toggleButton.autoresizingMask = [.maxXMargin, .maxYMargin]
    return toggleButton
  }()

  // Cape display control
  private var showCape: Bool = true
  private lazy var capeToggleButton: NSButton = {
    let capeToggleButton = NSButton(frame: NSRect(x: 20, y: 100, width: 130, height: 30))
    capeToggleButton.title = showCape ? "Hide Cape" : "Show Cape"
    capeToggleButton.bezelStyle = .rounded
    capeToggleButton.target = self
    capeToggleButton.action = #selector(toggleCape)
    capeToggleButton.autoresizingMask = [.maxXMargin, .maxYMargin]
    return capeToggleButton
  }()
  private var capeAnimationEnabled: Bool = true
  private lazy var capeAnimationButton: NSButton = {
    let capeAnimationButton = NSButton(frame: NSRect(x: 20, y: 140, width: 130, height: 30))
    capeAnimationButton.title = capeAnimationEnabled ? "Disable Animation" : "Enable Animation"
    capeAnimationButton.bezelStyle = .rounded
    capeAnimationButton.target = self
    capeAnimationButton.action = #selector(toggleCapeAnimationAction)
    capeAnimationButton.autoresizingMask = [.maxXMargin, .maxYMargin]
    return capeAnimationButton
  }()
  // Cape sway configuration
  private var baseCapeSwayAmplitude: Float = Float.pi / 24  // idle sway amplitude (~7.5°)
  private var walkingCapeSwayMultiplier: Float = 1.9        // amplified when walking
  // Walking animation control
  private var walkingAnimationEnabled: Bool = false
  private lazy var walkingAnimationButton: NSButton = {
    let walkingAnimationButton = NSButton(frame: NSRect(x: 20, y: 180, width: 130, height: 30))
    walkingAnimationButton.title = walkingAnimationEnabled ? "Stop Walking" : "Start Walking"
    walkingAnimationButton.bezelStyle = .rounded
    walkingAnimationButton.target = self
    walkingAnimationButton.action = #selector(toggleWalkingAnimationAction)
    walkingAnimationButton.autoresizingMask = [.maxXMargin, .maxYMargin]
    return walkingAnimationButton
  }()

  // Model type control
  private lazy var modelTypeButton: NSButton = {
    let modelTypeButton = NSButton(frame: NSRect(x: 20, y: 60, width: 130, height: 30))
    modelTypeButton.title = "Switch to \(playerModel == .steve ? "Alex" : "Steve")"
    modelTypeButton.bezelStyle = .rounded
    modelTypeButton.target = self
    modelTypeButton.action = #selector(switchModelType)
    modelTypeButton.autoresizingMask = [.maxXMargin, .maxYMargin]
    return modelTypeButton
  }()

  public override func loadView() {
    scnView = SCNView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    // if debugMode {
    //   scnView.debugOptions = [
    //     .showBoundingBoxes,
    //     .showWireframe,
    //     .renderAsWireframe,
    //     .showSkeletons,
    //     .showPhysicsShapes,
    //     .showCameras,
    //     .showLightInfluences
    //   ]
    // }
    self.view = scnView
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    // If no texture is set through initializer, use default texture
    if skinImage == nil {
      loadDefaultTexture()
    }

    setupScene()
    setupCharacter()
    setupCamera()
    setupLighting()
    setupUI()
    setupGestureRecognizers()

    scnView.allowsCameraControl = true
    scnView.backgroundColor = backgroundColor
  }
}

// MARK: - Setup Methods

extension SceneKitCharacterViewController {

  private func setupScene() {
    scene = SCNScene()
    scnView.scene = scene
  }

  private func setupCharacter() {
    // Create character group node
    characterGroup = SCNNode()
    characterGroup.name = "CharacterGroup"
    scene.rootNode.addChildNode(characterGroup)

    // Create body parts
    createHead()
    createBody()
    createArms()
    createLegs()
    createCape()

    // Set rendering priorities and depth offsets
    setupRenderingPriorities()

    // Add rotation animation
    setupRotationAnimation()

    // Resume walking animation if enabled
    if walkingAnimationEnabled {
      startWalkingAnimation()
    }
  }

  private func setupRotationAnimation() {
    // Remove any existing rotation animations
    characterGroup.removeAllActions()

    // Only add rotation if duration is positive
    guard rotationDuration > 0 else { return }

    let rotationAction = SCNAction.rotateBy(
      x: 0,
      y: CGFloat.pi * 2,
      z: 0,
      duration: rotationDuration
    )
    let repeatAction = SCNAction.repeatForever(rotationAction)
    characterGroup.runAction(repeatAction)
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
    // Add right-click gesture to toggle walking animation
    let rightClickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleRightClick(_:)))
    rightClickGesture.buttonMask = 0x2 // Right mouse button
    scnView.addGestureRecognizer(rightClickGesture)
  }

}

// MARK: - Texture Methods

extension SceneKitCharacterViewController {

  private func loadTexture() {
    guard let texturePath = skinTexturePath else { return }

    if let image = NSImage(contentsOfFile: texturePath) {
      self.skinImage = image
    } else {
      print("Failed to load texture from path: \(texturePath)")
      loadDefaultTexture()
    }
  }

  private func loadCapeTexture(from path: String) {
    if let image = NSImage(contentsOfFile: path) {
      self.capeImage = image
      print("✅ Cape texture loaded from: \(path)")
    } else {
      print("⚠️ Failed to load cape texture from path: \(path)")
    }
  }

  private func loadDefaultTexture() {
    // Try to load alex.png from Swift Package resources
    if let resourceURL = Bundle.module.url(forResource: "alex", withExtension: "png"),
       let image = NSImage(contentsOf: resourceURL) {
      self.skinImage = image
    } else {
      // Fallback: try using NSImage(named:)
      self.skinImage = NSImage(named: "Skin")
      if self.skinImage == nil {
        print("Warning: Could not load default texture")
      }
    }
  }
}

// MARK: - Update Methods

extension SceneKitCharacterViewController {

  public func updateTexture(path: String) {
    self.skinTexturePath = path
    loadTexture()

    // Recreate character to apply new texture
    if skinImage != nil {
      characterGroup?.removeFromParentNode()
      setupCharacter()
    }
  }

  public func updateTexture(image: NSImage) {
    self.skinImage = image
    self.skinTexturePath = nil

    // Recreate character to apply new texture
    characterGroup?.removeFromParentNode()
    setupCharacter()
  }

  public func updateRotationDuration(_ duration: TimeInterval) {
    self.rotationDuration = duration

    // Update the rotation animation if character is already created
    if characterGroup != nil {
      setupRotationAnimation()
    }
  }

  public func updateBackgroundColor(_ color: NSColor) {
    self.backgroundColor = color
    scnView?.backgroundColor = color
  }

  public func updateCapeTexture(path: String) {
    self.capeTexturePath = path
    loadCapeTexture(from: path)

    // Recreate character to apply new cape texture
    if characterGroup != nil {
      characterGroup?.removeFromParentNode()
      setupCharacter()
    }
  }

  public func updateCapeTexture(image: NSImage) {
    self.capeImage = image
    self.capeTexturePath = nil // Clear file path since we're using direct image

    // Recreate character to apply new cape texture
    if characterGroup != nil {
      characterGroup?.removeFromParentNode()
      setupCharacter()
    }
  }

  public func removeCapeTexture() {
    self.capeImage = nil
    self.capeTexturePath = nil

    // Recreate character without cape
    if characterGroup != nil {
      characterGroup?.removeFromParentNode()
      setupCharacter()
    }
  }

  public func updatePlayerModel(_ model: PlayerModel) {
    self.playerModel = model

    // Recreate character to apply new model
    if characterGroup != nil {
      characterGroup?.removeFromParentNode()
      setupCharacter()
    }
  }

  public func updateShowButtons(_ show: Bool) {
    // Don't update if debugMode value hasn't changed
    guard self.debugMode != show else { return }

    self.debugMode = show

    // If hiding buttons, remove them from view
    if !show {
      toggleButton.removeFromSuperview()
      modelTypeButton.removeFromSuperview()
      capeToggleButton.removeFromSuperview()
      capeAnimationButton.removeFromSuperview()
      walkingAnimationButton.removeFromSuperview()
    } else {
      // If showing buttons, recreate them
      setupUI()
    }
  }

  public func toggleCapeAnimation(_ enabled: Bool) {
    guard let capePivotNode = capePivotNode else { return }

    if enabled {
      if capePivotNode.action(forKey: "capeSwayAnimation") == nil {
        addCapeSwayAnimation()
      }
    } else {
      capePivotNode.removeAction(forKey: "capeSwayAnimation")
      // Reset to base rotation
      capePivotNode.eulerAngles = SCNVector3(Float.pi / 14, 0, 0)
      print("🔇 Cape animation disabled")
    }
  }

  private func isPointOverUIButton(_ point: CGPoint) -> Bool {
    // If buttons are not shown, they can't be clicked
    guard debugMode else { return false }

    let buttons = [toggleButton, modelTypeButton, capeToggleButton, capeAnimationButton, walkingAnimationButton]

    for button in buttons {
      if button.frame.contains(point) {
        return true
      }
    }
    return false
  }
}

// MARK: - Action Handlers

extension SceneKitCharacterViewController {

  @objc private func handleRightClick(_ gestureRecognizer: NSClickGestureRecognizer) {
    let location = gestureRecognizer.location(in: scnView)

    // Check if click is over any UI button to avoid conflicts
    if isPointOverUIButton(location) {
      return
    }

    // Toggle walking animation on right-click
    toggleWalkingAnimationAction()

    print("Right-click detected: toggled walking animation to \(walkingAnimationEnabled ? "enabled" : "disabled")")
  }

  @objc private func toggleOuterLayers() {
    showOuterLayers.toggle()

    // Toggle visibility of all outer layers
    hatNode?.isHidden = !showOuterLayers
    jacketNode?.isHidden = !showOuterLayers
    rightArmSleeveNode?.isHidden = !showOuterLayers
    leftArmSleeveNode?.isHidden = !showOuterLayers
    rightLegSleeveNode?.isHidden = !showOuterLayers
    leftLegSleeveNode?.isHidden = !showOuterLayers

    toggleButton.title = showOuterLayers ? "Hide Outer Layers" : "Show Outer Layers"

    print("Outer layers visibility: \(showOuterLayers ? "shown" : "hidden")")
  }

  @objc private func toggleCape() {
    showCape.toggle()

    // Toggle cape visibility
    capePivotNode?.isHidden = !showCape

    capeToggleButton.title = showCape ? "Hide Cape" : "Show Cape"

    print("Cape visibility: \(showCape ? "shown" : "hidden")")
  }

  @objc private func toggleCapeAnimationAction() {
    capeAnimationEnabled.toggle()
    toggleCapeAnimation(capeAnimationEnabled)

    capeAnimationButton.title = capeAnimationEnabled ? "Disable Animation" : "Enable Animation"

    print("Cape animation: \(capeAnimationEnabled ? "enabled" : "disabled")")
  }

  @objc private func switchModelType() {
    // Switch between Steve and Alex models
    playerModel = (playerModel == .steve) ? .alex : .steve

    // Update button text
    modelTypeButton.title = "Switch to \(playerModel == .steve ? "Alex" : "Steve")"

    // Recreate character with new model type
    characterGroup?.removeFromParentNode()
    setupCharacter()

    print("Switched to \(playerModel.displayName) model")
  }

  @objc private func toggleWalkingAnimationAction() {
    walkingAnimationEnabled.toggle()
    if walkingAnimationEnabled {
      startWalkingAnimation()
    } else {
      stopWalkingAnimation()
    }
    walkingAnimationButton.title = walkingAnimationEnabled ? "Stop Walking" : "Start Walking"
    if capeAnimationEnabled { refreshCapeSwayAnimation() }
  }
}

// MARK: - Material Creation Functions

extension SceneKitCharacterViewController {

  private func createHeadMaterials(
    from skinImage: NSImage,
    isHat: Bool = false
  ) -> [SCNMaterial] {
    let specs: [CubeFace.Spec] = isHat ? CubeFace.headHat : CubeFace.headBase
    let headRects: [CGRect] = specs.map { $0.rect }
    let layerName: String = isHat ? "hat" : "head"

    return createMaterials(
      from: skinImage,
      rects: headRects,
      layerName: layerName,
      isOuter: isHat
    )
  }

  private func createBodyMaterials(
    from skinImage: NSImage,
    isJacket: Bool = false
  ) -> [SCNMaterial] {
    let specs: [CubeFace.Spec] = isJacket ? CubeFace.bodyJacket : CubeFace.bodyBase
    let bodyRects: [CGRect] = specs.map { $0.rect }
    let layerName: String = isJacket ? "jacket" : "body"

    return createMaterials(
      from: skinImage,
      rects: bodyRects,
      layerName: layerName,
      isOuter: isJacket
    )
  }

  private func createArmMaterials(
    from skinImage: NSImage,
    isLeft: Bool,
    isSleeve: Bool
  ) -> [SCNMaterial] {
    let armWidth: CGFloat = playerModel.armDimensions.width
    let specs: [CubeFace.Spec] = isSleeve
      ? CubeFace.armSleeve(isLeft: isLeft, armWidth: armWidth)
      : CubeFace.armBase(isLeft: isLeft, armWidth: armWidth)
    let armRects: [CGRect] = specs.map { $0.rect }
    let layerName: String = isSleeve
      ? (isLeft ? "left_arm_sleeve" : "right_arm_sleeve")
      : (isLeft ? "left_arm" : "right_arm")

    return createMaterials(
      from: skinImage,
      rects: armRects,
      layerName: layerName,
      isOuter: isSleeve,
      isLimb: true
    )
  }

  private func createLegMaterials(
    from skinImage: NSImage,
    isLeft: Bool,
    isSleeve: Bool
  ) -> [SCNMaterial] {
    let specs: [CubeFace.Spec] = isSleeve
      ? CubeFace.legSleeve(isLeft: isLeft)
      : CubeFace.legBase(isLeft: isLeft)
    let legRects: [CGRect] = specs.map { $0.rect }
    let layerName: String = isSleeve
      ? (isLeft ? "left_leg_sleeve" : "right_leg_sleeve")
      : (isLeft ? "left_leg" : "right_leg")

    return createMaterials(
      from: skinImage,
      rects: legRects,
      layerName: layerName,
      isOuter: isSleeve,
      isLimb: true
    )
  }

  private func createCapeMaterials(
    from capeImage: NSImage
  ) -> [SCNMaterial] {
    var materials: [SCNMaterial] = []

    for (_, spec) in CubeFace.cape.enumerated() {
      let material = SCNMaterial()

      if let croppedImage = cropImage(capeImage, rect: spec.rect, layerName: "cape") {
        let finalImage = spec.rotate180 ? (rotateImage(croppedImage, degrees: 180) ?? croppedImage) : croppedImage
        material.diffuse.contents = finalImage
        material.diffuse.magnificationFilter = .nearest
        material.diffuse.minificationFilter = .nearest
        material.diffuse.wrapS = .clamp
        material.diffuse.wrapT = .clamp

        // Enhanced material properties for realistic cape appearance
        if hasTransparentPixels(croppedImage) {
          material.transparency = 1.0
          material.blendMode = .alpha
        } else {
          material.transparency = 1.0  // Fully opaque for solid cape
          material.blendMode = .alpha
        }

        // Cape should be double-sided for realistic cloth appearance
        material.isDoubleSided = true

        // Use Phong lighting for better visual depth
        material.lightingModel = .phong
        material.shininess = 0.1  // Low shininess for cloth-like appearance

        // Add subtle ambient and diffuse properties
        material.ambient.contents = NSColor.black.withAlphaComponent(0.2)
        material.specular.contents = NSColor.white.withAlphaComponent(0.1)

        print("✅ Created enhanced cape material for \(spec.face.rawValue)")
      } else {
        // Fallback material with improved properties
        material.diffuse.contents = NSColor.red.withAlphaComponent(0.8)
        material.transparency = 0.8
        material.blendMode = .alpha
        material.isDoubleSided = true
        material.lightingModel = .phong
        print("⚠️ Using fallback material for cape \(spec.face.rawValue)")
      }

      materials.append(material)
    }

    return materials
  }

  // MARK: - General Material Creation Functions

  private func createMaterials(
    from skinImage: NSImage,
    rects: [CGRect],
    layerName: String,
    isOuter: Bool,
    isLimb: Bool = false
  ) -> [SCNMaterial] {
    let faceNames = ["front", "right", "back", "left", "top", "bottom"]
    var materials: [SCNMaterial] = []

    for (index, rect) in rects.enumerated() {
      let material = SCNMaterial()
      print("Processing \(layerName) face \(index) (\(faceNames[index])) with rect: \(rect)")

      if let croppedImage = cropImage(
        skinImage,
        rect: rect,
        layerName: layerName
      ) {
        let finalImage: NSImage
        if index == 5 {  // bottom face
          if isLimb {
            // Limbs (arms and legs) bottom face: optional flip + rotation per configuration
            let flipped: NSImage = {
              switch limbBottomFlipMode {
              case .none:
                return croppedImage
              case .horizontal:
                return flipImageHorizontally(croppedImage) ?? croppedImage
              case .vertical:
                return flipImageVertically(croppedImage) ?? croppedImage
              case .both:
                let h = flipImageHorizontally(croppedImage) ?? croppedImage
                return flipImageVertically(h) ?? h
              }
            }()
            finalImage = limbBottomRotate180 ? (rotateImage(flipped, degrees: 180) ?? flipped) : flipped
          } else {
            // Head and body bottom face: optional flip + rotation per configuration
            let flipped: NSImage = {
              switch headBodyBottomFlipMode {
              case .none:
                return croppedImage
              case .horizontal:
                return flipImageHorizontally(croppedImage) ?? croppedImage
              case .vertical:
                return flipImageVertically(croppedImage) ?? croppedImage
              case .both:
                let h = flipImageHorizontally(croppedImage) ?? croppedImage
                return flipImageVertically(h) ?? h
              }
            }()
            finalImage = headBodyBottomRotate180 ? (rotateImage(flipped, degrees: 180) ?? flipped) : flipped
          }
        } else {
          finalImage = croppedImage
        }

        material.diffuse.contents = finalImage
        material.diffuse.magnificationFilter = .nearest
        material.diffuse.minificationFilter = .nearest
        material.diffuse.wrapS = .clamp
        material.diffuse.wrapT = .clamp

        // Set transparency for outer layers
        if isOuter {
          if hasTransparentPixels(finalImage) {
            material.transparency = 1.0
            material.blendMode = .alpha
            material.isDoubleSided = true
          } else {
            material.transparency = 0.9
            material.blendMode = .alpha
          }
        }

        material.lightingModel = .constant

        print(
          "Successfully created material for \(layerName) face \(index) (\(faceNames[index]))"
        )
      } else {
        material.diffuse.contents = isOuter ? NSColor.blue.withAlphaComponent(0.5) : NSColor.red
        print(
          "Failed to crop texture for \(layerName) face \(index) (\(faceNames[index])), rect: \(rect)"
        )
      }

      materials.append(material)
    }

    return materials
  }
}

// MARK: - Helper Functions

extension SceneKitCharacterViewController {

  private func cropImage(_ image: NSImage, rect: CGRect, layerName: String = "character") -> NSImage? {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      print("❌ Failed to get CGImage from NSImage")
      return nil
    }

    let imageWidth = CGFloat(cgImage.width)
    let imageHeight = CGFloat(cgImage.height)

    let cropRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)

    let imageBounds = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
    if !imageBounds.contains(cropRect) {
      print("⚠️  Crop rect \(cropRect) is outside image bounds \(imageBounds)")
      let intersection = cropRect.intersection(imageBounds)
      if intersection.isEmpty {
        print("❌ No intersection with image bounds")
        return nil
      }
    }

    guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
      print("❌ Failed to crop CGImage with rect: \(cropRect)")
      return nil
    }

    let resultImage = NSImage(
      cgImage: croppedCGImage,
      size: NSSize(width: rect.width, height: rect.height)
    )

    return resultImage
  }

  private func rotateImage(_ image: NSImage, degrees: CGFloat) -> NSImage? {
    let radians = degrees * .pi / 180.0
    let originalSize = image.size
    let newSize = originalSize

    let newImage = NSImage(size: newSize)
    newImage.lockFocus()

    // Disable interpolation/antialiasing to preserve pixel-perfect rendering
    if let context = NSGraphicsContext.current {
      context.imageInterpolation = .none
      context.shouldAntialias = false
      context.cgContext.interpolationQuality = .none
    }

    let transform = NSAffineTransform()
    transform.translateX(by: newSize.width / 2, yBy: newSize.height / 2)
    transform.rotate(byRadians: radians)
    transform.translateX(
      by: -originalSize.width / 2,
      yBy: -originalSize.height / 2
    )
    transform.concat()

    image.draw(
      at: NSPoint.zero,
      from: NSRect.zero,
      operation: .copy,
      fraction: 1.0
    )

    newImage.unlockFocus()

    return newImage
  }

  private func flipImageHorizontally(_ image: NSImage) -> NSImage? {
    let size = image.size
    let newImage = NSImage(size: size)
    newImage.lockFocus()
    if let context = NSGraphicsContext.current {
      context.imageInterpolation = .none
      context.shouldAntialias = false
      context.cgContext.interpolationQuality = .none
    }
    let transform = NSAffineTransform()
    transform.translateX(by: size.width, yBy: 0)
    transform.scaleX(by: -1, yBy: 1)
    transform.concat()
    image.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
    newImage.unlockFocus()
    return newImage
  }

  private func flipImageVertically(_ image: NSImage) -> NSImage? {
    let size = image.size
    let newImage = NSImage(size: size)
    newImage.lockFocus()
    if let context = NSGraphicsContext.current {
      context.imageInterpolation = .none
      context.shouldAntialias = false
      context.cgContext.interpolationQuality = .none
    }
    let transform = NSAffineTransform()
    transform.translateX(by: 0, yBy: size.height)
    transform.scaleX(by: 1, yBy: -1)
    transform.concat()
    image.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
    newImage.unlockFocus()
    return newImage
  }

  private func hasTransparentPixels(_ image: NSImage) -> Bool {
    guard
      let cgImage = image.cgImage(
        forProposedRect: nil,
        context: nil,
        hints: nil
      )
    else {
      return false
    }

    return cgImage.alphaInfo != .none && cgImage.alphaInfo != .noneSkipFirst
      && cgImage.alphaInfo != .noneSkipLast
  }

  private func setupRenderingPriorities() {
    // Set rendering order and depth offset to avoid Z-fighting
    // Rendering order: higher values render later (appear in front)

    // Base layers - lowest priority
    bodyNode?.renderingOrder = 100
    headNode?.renderingOrder = 100
    rightArmNode?.renderingOrder = 105  // Arms slightly higher priority to avoid conflicts with body
    leftArmNode?.renderingOrder = 105
    rightLegNode?.renderingOrder = 105
    leftLegNode?.renderingOrder = 105

    // Outer layers - highest priority, ensuring they display on top of base layers
    hatNode?.renderingOrder = 200
    jacketNode?.renderingOrder = 200
    rightArmSleeveNode?.renderingOrder = 210
    leftArmSleeveNode?.renderingOrder = 210
    rightLegSleeveNode?.renderingOrder = 210
    leftLegSleeveNode?.renderingOrder = 210

    // Cape has special priority - should be behind body but visible
    capePivotNode?.renderingOrder = 150

    // Remove cape depth bias; pivot positioning handles separation
    // (Removed) setDepthBias(for: capeNode, bias: 0.002)
    print("✅ Rendering priorities and depth bias configured")
  }

  private func setDepthBias(for node: SCNNode?, bias: Float) {
    guard let node = node, let geometry = node.geometry else { return }

    for material in geometry.materials {
      material.readsFromDepthBuffer = true
      material.writesToDepthBuffer = true

      // Set transparency sorting to control rendering order
      if bias != 0.0 {
        material.transparency = 0.99999  // Close to 1 but not fully transparent, triggers alpha sorting
        material.blendMode = .alpha
      }
    }

    // Create depth offset effect by fine-tuning node position
    let currentPosition = node.position
    node.position = SCNVector3(
      currentPosition.x,
      currentPosition.y,
      currentPosition.z + CGFloat(bias * 100)  // Amplify offset effect
    )
  }
}

// MARK: - Create Character Parts

extension SceneKitCharacterViewController {

  private func createHead() {
    guard let skinImage = skinImage else { return }
    // Group positioned at head center for rotations / bobbing; children centered inside
    headGroupNode = SCNNode()
    headGroupNode.name = "HeadGroup"
    headGroupNode.position = SCNVector3(0, 16, 0)
    characterGroup.addChildNode(headGroupNode)

    // Base head (8x8x8)
    let headGeometry = SCNBox(width: 8, height: 8, length: 8, chamferRadius: 0)
    headGeometry.materials = createHeadMaterials(from: skinImage, isHat: false)
    headNode = SCNNode(geometry: headGeometry)
    headNode.name = "Head"
    headNode.position = SCNVector3Zero
    headGroupNode.addChildNode(headNode)

    // Hat layer (9x9x9)
    let hatGeometry = SCNBox(width: 9, height: 9, length: 9, chamferRadius: 0)
    hatGeometry.materials = createHeadMaterials(from: skinImage, isHat: true)
    hatNode = SCNNode(geometry: hatGeometry)
    hatNode.name = "Hat"
    hatNode.position = SCNVector3Zero
    headGroupNode.addChildNode(hatNode)
  }

  private func createBody() {
    // Base body (8x12x4)
    let bodyGeometry = SCNBox(width: 8, height: 12, length: 4, chamferRadius: 0)
    guard let skinImage = skinImage else { return }

    bodyGeometry.materials = createBodyMaterials(
      from: skinImage,
      isJacket: false
    )
    bodyNode = SCNNode(geometry: bodyGeometry)
    bodyNode.name = "Body"
    bodyNode.position = SCNVector3(0, 6, 0)  // Body center
    characterGroup.addChildNode(bodyNode)

    // Jacket layer (8.5x12.5x4.5)
    let jacketGeometry = SCNBox(
      width: 8.5,
      height: 12.5,
      length: 4.5,
      chamferRadius: 0
    )
    jacketGeometry.materials = createBodyMaterials(
      from: skinImage,
      isJacket: true
    )
    jacketNode = SCNNode(geometry: jacketGeometry)
    jacketNode.name = "Jacket"
    jacketNode.position = SCNVector3(0, 6, 0)
    characterGroup.addChildNode(jacketNode)
  }

  private func createArms() {
    guard let skinImage = skinImage else { return }

    let armDimensions = playerModel.armDimensions
    let armSleeveDimensions = playerModel.armSleeveDimensions
    let armPositions = playerModel.armPositions
    // Group nodes placed at shoulder pivot (top of arms). Arm height = 12 so child offset -6 to hang down.
    rightArmGroupNode = SCNNode()
    rightArmGroupNode.name = "RightArmGroup"
    rightArmGroupNode.position = SCNVector3(armPositions.right.x, armPositions.right.y + armDimensions.height / 2, armPositions.right.z)
    characterGroup.addChildNode(rightArmGroupNode)

    leftArmGroupNode = SCNNode()
    leftArmGroupNode.name = "LeftArmGroup"
    leftArmGroupNode.position = SCNVector3(armPositions.left.x, armPositions.left.y + armDimensions.height / 2, armPositions.left.z)
    characterGroup.addChildNode(leftArmGroupNode)

    // Right arm geometry
    let rightArmGeometry = SCNBox(width: armDimensions.width, height: armDimensions.height, length: armDimensions.length, chamferRadius: 0)
    rightArmGeometry.materials = createArmMaterials(from: skinImage, isLeft: false, isSleeve: false)
    rightArmNode = SCNNode(geometry: rightArmGeometry)
    rightArmNode.name = "RightArm"
    rightArmNode.position = SCNVector3(0, -armDimensions.height / 2, 0)
    rightArmGroupNode.addChildNode(rightArmNode)

    let rightArmSleeveGeometry = SCNBox(width: armSleeveDimensions.width, height: armSleeveDimensions.height, length: armSleeveDimensions.length, chamferRadius: 0)
    rightArmSleeveGeometry.materials = createArmMaterials(from: skinImage, isLeft: false, isSleeve: true)
    rightArmSleeveNode = SCNNode(geometry: rightArmSleeveGeometry)
    rightArmSleeveNode.name = "RightArmSleeve"
    rightArmSleeveNode.position = SCNVector3(0, -armSleeveDimensions.height / 2, 0)
    rightArmGroupNode.addChildNode(rightArmSleeveNode)

    // Left arm geometry
    let leftArmGeometry = SCNBox(width: armDimensions.width, height: armDimensions.height, length: armDimensions.length, chamferRadius: 0)
    leftArmGeometry.materials = createArmMaterials(from: skinImage, isLeft: true, isSleeve: false)
    leftArmNode = SCNNode(geometry: leftArmGeometry)
    leftArmNode.name = "LeftArm"
    leftArmNode.position = SCNVector3(0, -armDimensions.height / 2, 0)
    leftArmGroupNode.addChildNode(leftArmNode)

    let leftArmSleeveGeometry = SCNBox(width: armSleeveDimensions.width, height: armSleeveDimensions.height, length: armSleeveDimensions.length, chamferRadius: 0)
    leftArmSleeveGeometry.materials = createArmMaterials(from: skinImage, isLeft: true, isSleeve: true)
    leftArmSleeveNode = SCNNode(geometry: leftArmSleeveGeometry)
    leftArmSleeveNode.name = "LeftArmSleeve"
    leftArmSleeveNode.position = SCNVector3(0, -armSleeveDimensions.height / 2, 0)
    leftArmGroupNode.addChildNode(leftArmSleeveNode)
  }

  private func createLegs() {
    guard let skinImage = skinImage else { return }
    // Group nodes at hip pivot (top of legs). Leg height = 12 so child offset -6.
    rightLegGroupNode = SCNNode()
    rightLegGroupNode.name = "RightLegGroup"
    rightLegGroupNode.position = SCNVector3(-2, 0, 0) // Hip y=0 (body center is 6, leg extends downward)
    characterGroup.addChildNode(rightLegGroupNode)

    leftLegGroupNode = SCNNode()
    leftLegGroupNode.name = "LeftLegGroup"
    leftLegGroupNode.position = SCNVector3(2, 0, 0)
    characterGroup.addChildNode(leftLegGroupNode)

    // Right leg
    let rightLegGeometry = SCNBox(width: 4, height: 12, length: 4, chamferRadius: 0)
    rightLegGeometry.materials = createLegMaterials(from: skinImage, isLeft: false, isSleeve: false)
    rightLegNode = SCNNode(geometry: rightLegGeometry)
    rightLegNode.name = "RightLeg"
    rightLegNode.position = SCNVector3(0, -6, 0)
    rightLegGroupNode.addChildNode(rightLegNode)

    let rightLegSleeveGeometry = SCNBox(width: 4.5, height: 12.5, length: 4.5, chamferRadius: 0)
    rightLegSleeveGeometry.materials = createLegMaterials(from: skinImage, isLeft: false, isSleeve: true)
    rightLegSleeveNode = SCNNode(geometry: rightLegSleeveGeometry)
    rightLegSleeveNode.name = "RightLegSleeve"
    rightLegSleeveNode.position = SCNVector3(0, -6.25, 0) // half of 12.5
    rightLegGroupNode.addChildNode(rightLegSleeveNode)

    // Left leg
    let leftLegGeometry = SCNBox(width: 4, height: 12, length: 4, chamferRadius: 0)
    leftLegGeometry.materials = createLegMaterials(from: skinImage, isLeft: true, isSleeve: false)
    leftLegNode = SCNNode(geometry: leftLegGeometry)
    leftLegNode.name = "LeftLeg"
    leftLegNode.position = SCNVector3(0, -6, 0)
    leftLegGroupNode.addChildNode(leftLegNode)

    let leftLegSleeveGeometry = SCNBox(width: 4.5, height: 12.5, length: 4.5, chamferRadius: 0)
    leftLegSleeveGeometry.materials = createLegMaterials(from: skinImage, isLeft: true, isSleeve: true)
    leftLegSleeveNode = SCNNode(geometry: leftLegSleeveGeometry)
    leftLegSleeveNode.name = "LeftLegSleeve"
    leftLegSleeveNode.position = SCNVector3(0, -6.25, 0)
    leftLegGroupNode.addChildNode(leftLegSleeveNode)
  }

  private func createCape() {
    // Try to load cape texture - prioritize custom textures over default
    var capeTextureImage: NSImage?

    // First priority: Use custom cape image if provided
    if let customCapeImage = capeImage {
      capeTextureImage = customCapeImage
      print("✅ Using custom cape NSImage texture")
    }
    // Second priority: Use custom cape texture path if provided
    else if let customCapeTexturePath = capeTexturePath {
      if let image = NSImage(contentsOfFile: customCapeTexturePath) {
        capeTextureImage = image
        print("✅ Using custom cape texture from: \(customCapeTexturePath)")
      } else {
        print("⚠️ Failed to load custom cape texture from: \(customCapeTexturePath)")
      }
    }

    // Third priority: Try to load default cape from bundle resources
    if capeTextureImage == nil {
      if let resourceURL = Bundle.module.url(forResource: "cape", withExtension: "png"),
         let image = NSImage(contentsOf: resourceURL) {
        capeTextureImage = image
        print("✅ Using default cape texture from bundle")
      } else {
        capeTextureImage = NSImage(named: "cap")
        if capeTextureImage != nil {
          print("✅ Using default cape texture from app bundle")
        }
      }
    }

    guard let cape = capeTextureImage else {
      print("⚠️ No cape texture available - skipping cape creation")
      return
    }

    // Pivot node: represents attachment point at upper back (shoulder line)
    // Body top is y=12, shoulder visually ~ y=11. We'll place pivot at y=11.
    capePivotNode = SCNNode()
    capePivotNode.name = "CapePivot"
    // With 1.0 thickness, we need more clearance. Body half-length=2, so -2.5 gives good separation
    capePivotNode.position = SCNVector3(0, 11, -2.5) // Behind body with clearance for thickness

    // Cape geometry: width 10, height 16, realistic thickness like official Minecraft
    // Official cape has visible thickness when viewed from side - approximately 1 unit
    let capeGeometry = SCNBox(width: 10, height: 16, length: 1.0, chamferRadius: 0)
    capeGeometry.materials = createCapeMaterials(from: cape)

    // Cape node: positioned so its top edge aligns with pivot (pivot acts like hinge)
    capeNode = SCNNode(geometry: capeGeometry)
    capeNode.name = "Cape"
    // SCNBox is centered on its node; to hang from top we shift it downward by half its height
    capeNode.position = SCNVector3(0, -8, 0) // half of 16

    // Apply slight backward tilt on pivot (not on cape itself) so rotation hinge feels natural
    capePivotNode.eulerAngles = SCNVector3(Float.pi / 14, 0, 0) // ~12.8° backward

    // Visibility controlled on pivot (affects entire cape assembly)
    capePivotNode.isHidden = !showCape

    // Build hierarchy
    capePivotNode.addChildNode(capeNode)
    characterGroup.addChildNode(capePivotNode)

    // Add subtle swaying animation to make cape more dynamic
    addCapeSwayAnimation()

    print("✅ Cape created with pivot and animation. Pivot pos: \(capePivotNode.position), cape local pos: \(capeNode.position)")
  }
}

// MARK: - Animation

extension SceneKitCharacterViewController {

  private func addCapeSwayAnimation() {
    guard let capePivotNode = capePivotNode else { return }

    // Create subtle swaying motion like wind effect
    let baseRotationX = Float.pi / 14  // Base backward tilt (~12.8°)
    let swayAmplitude: Float = baseCapeSwayAmplitude * (walkingAnimationEnabled ? walkingCapeSwayMultiplier : 1.0)

    // Animation sequence: sway left, center, right, center
    let rotateLeft = SCNAction.rotateTo(
      x: CGFloat(baseRotationX + swayAmplitude),
      y: 0,
      z: CGFloat(Float.pi / 40),  // Slight side rotation
      duration: 2.0
    )

    let rotateCenter = SCNAction.rotateTo(
      x: CGFloat(baseRotationX),
      y: 0,
      z: 0,
      duration: 1.5
    )

    let rotateRight = SCNAction.rotateTo(
      x: CGFloat(baseRotationX + swayAmplitude),
      y: 0,
      z: CGFloat(-Float.pi / 40),  // Slight side rotation opposite
      duration: 2.0
    )

    // Smooth easing for natural movement
    rotateLeft.timingMode = .easeInEaseOut
    rotateCenter.timingMode = .easeInEaseOut
    rotateRight.timingMode = .easeInEaseOut

    // Create animation sequence
    let swaySequence = SCNAction.sequence([
      rotateLeft,
      rotateCenter,
      rotateRight,
      rotateCenter
    ])

    // Repeat the sway animation forever
    let repeatSway = SCNAction.repeatForever(swaySequence)

    capePivotNode.runAction(repeatSway, forKey: "capeSwayAnimation")

    print("🌪️ Cape sway animation added")
  }

  private func refreshCapeSwayAnimation() {
    guard capeAnimationEnabled else { return }
    capePivotNode?.removeAction(forKey: "capeSwayAnimation")
    addCapeSwayAnimation()
  }

  private func startWalkingAnimation() {
    // Remove existing limb actions on group nodes
    rightArmGroupNode?.removeAction(forKey: "walkSwing")
    leftArmGroupNode?.removeAction(forKey: "walkSwing")
    rightLegGroupNode?.removeAction(forKey: "walkSwing")
    leftLegGroupNode?.removeAction(forKey: "walkSwing")

    // Swing amplitude (radians) ~ Minecraft style
    let armAmplitude: CGFloat = .pi / 4 // 45°
    let legAmplitude: CGFloat = .pi / 5 // 36°
    let cycleDuration: TimeInterval = 0.8

    func swingAction(amplitude: CGFloat) -> SCNAction {
      let forward = SCNAction.rotateTo(x: amplitude, y: 0, z: 0, duration: cycleDuration / 2, usesShortestUnitArc: true)
      let backward = SCNAction.rotateTo(x: -amplitude, y: 0, z: 0, duration: cycleDuration / 2, usesShortestUnitArc: true)
      forward.timingMode = .easeInEaseOut
      backward.timingMode = .easeInEaseOut
      return SCNAction.repeatForever(SCNAction.sequence([forward, backward]))
    }

    // Arms: opposite phase using group nodes
    if let rightArmGroupNode = rightArmGroupNode { rightArmGroupNode.runAction(swingAction(amplitude: armAmplitude), forKey: "walkSwing") }
    if let leftArmGroupNode = leftArmGroupNode {
      let delay = SCNAction.wait(duration: cycleDuration / 2)
      leftArmGroupNode.runAction(SCNAction.sequence([delay, swingAction(amplitude: armAmplitude)]), forKey: "walkSwing")
    }

    // Legs: opposite to corresponding arm using group nodes
    if let rightLegGroupNode = rightLegGroupNode {
      let delay = SCNAction.wait(duration: cycleDuration / 2)
      rightLegGroupNode.runAction(SCNAction.sequence([delay, swingAction(amplitude: legAmplitude)]), forKey: "walkSwing")
    }
    if let leftLegGroupNode = leftLegGroupNode { leftLegGroupNode.runAction(swingAction(amplitude: legAmplitude), forKey: "walkSwing") }

    // Slight head bob (small vertical movement) using group node so hat follows
    if let headGroupNode = headGroupNode {
      headGroupNode.removeAction(forKey: "headBob")
      let up = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: cycleDuration / 2)
      let down = SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: cycleDuration / 2)
      up.timingMode = .easeInEaseOut
      down.timingMode = .easeInEaseOut
      headGroupNode.runAction(SCNAction.repeatForever(SCNAction.sequence([up, down])), forKey: "headBob")
    }
  }

  private func stopWalkingAnimation() {
    // Stop limb actions and reset rotations on group nodes
    for node in [rightArmGroupNode, leftArmGroupNode, rightLegGroupNode, leftLegGroupNode] { node?.removeAction(forKey: "walkSwing") }
    for node in [rightArmGroupNode, leftArmGroupNode, rightLegGroupNode, leftLegGroupNode] {
      SCNTransaction.begin()
      SCNTransaction.animationDuration = 0.25
      node?.eulerAngles.x = 0
      SCNTransaction.commit()
    }
    headGroupNode?.removeAction(forKey: "headBob")
    // Reset head group position smoothly
    if let headGroupNode = headGroupNode {
      SCNTransaction.begin()
      SCNTransaction.animationDuration = 0.25
      headGroupNode.position.y = 16
      SCNTransaction.commit()
    }
  }
}

// MARK: - Usage Helper

extension SceneKitCharacterViewController {

  static func presentInNewWindow(
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

  // Convenience initializer
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

  // Convenience initializer with cape texture path
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

  // Convenience initializer with only model type
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

  // Convenience initializer with NSImage texture
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
    // No need to call loadTexture() since we already have the image
  }

  // Convenience initializer with NSImage textures including cape
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
    // No need to call loadTexture() since we already have the images
  }

  // Convenience initializer with mixed texture inputs
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

#Preview {
  SceneKitCharacterViewController(rotationDuration: 12)
}
