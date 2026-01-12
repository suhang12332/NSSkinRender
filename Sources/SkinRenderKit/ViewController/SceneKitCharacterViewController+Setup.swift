//
//  SceneKitCharacterViewController+Setup.swift
//  SkinRenderKit
//

import AppKit
import SceneKit

extension SceneKitCharacterViewController {

  func setupScene() {
    scene = SCNScene()
    scnView.scene = scene
    scnView.allowsCameraControl = true
    scnView.backgroundColor = backgroundColor
    scnView.showsStatistics = debugMode
    
    // Enable antialiasing and optimize rendering quality
    scnView.antialiasingMode = .multisampling4X
  }

  func setupCamera() {
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = CharacterDimensions.cameraPosition
    cameraNode.look(at: CharacterDimensions.cameraTarget)
    
    // Configure camera for optimal shadow rendering
    if let camera = cameraNode.camera {
      camera.wantsHDR = false
      camera.wantsExposureAdaptation = false
      camera.exposureAdaptationBrighteningSpeedFactor = 0.5
      camera.exposureAdaptationDarkeningSpeedFactor = 0.5
    }
    
    scene.rootNode.addChildNode(cameraNode)
  }

  func setupLighting() {
    // Ambient light - 柔和的环境光，保持自然层次
    scene.rootNode.addChildNode(createLightNode(
      type: .ambient,
      intensity: 200,
      color: NSColor(white: 0.9, alpha: 1.0)
    ))

    // Main directional light with shadows - 从侧面前方照射，模拟自然光
    let directionalLight = createLightNode(
      type: .directional,
      intensity: 1200,
      color: NSColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 1.0),  // slightly warm
      castsShadow: true,
      eulerAngles: SCNVector3(-Float.pi / 4, Float.pi / 5, 0)  // 侧面前方：前方约36度，高度约45度
    )
    if let light = directionalLight.light {
      configureShadowLight(light)
    }
    scene.rootNode.addChildNode(directionalLight)

    // Fill light (auxiliary directional light) - 从另一侧前方补光，减少对比
    scene.rootNode.addChildNode(createLightNode(
      type: .directional,
      intensity: 500,
      color: NSColor(red: 0.92, green: 0.96, blue: 1.0, alpha: 1.0),  // slightly cool
      eulerAngles: SCNVector3(-Float.pi / 4, -Float.pi / 5, 0)  // 另一侧前方补光
    ))

    // Rim/back light (outline light) - 柔和背光，避免过曝
    scene.rootNode.addChildNode(createLightNode(
      type: .directional,
      intensity: 280,
      color: NSColor(white: 1.0, alpha: 1.0),
      eulerAngles: SCNVector3(-Float.pi / 3, -Float.pi * 0.65, 0)
    ))

    // Top omni light - 少量顶光，提亮头部和肩线
    scene.rootNode.addChildNode(createLightNode(
      type: .omni,
      intensity: 220,
      color: NSColor(white: 1.0, alpha: 1.0),
      position: SCNVector3(0, 25, 0)
    ))

    // Create ground plane (hidden by default for transparent background)
    let groundGeometry = SCNFloor()
    groundGeometry.reflectivity = 0.0
    let groundMaterial = SCNMaterial()
    groundMaterial.diffuse.contents = NSColor(white: 0.9, alpha: 1.0)
    groundMaterial.lightingModel = .lambert
    groundGeometry.materials = [groundMaterial]
    let groundNode = SCNNode(geometry: groundGeometry)
    groundNode.position = SCNVector3(0, -12, 0)
    groundNode.name = "Ground"
    groundNode.castsShadow = false
    groundNode.isHidden = true  // Hide ground for transparent background
    scene.rootNode.addChildNode(groundNode)

    scene.rootNode.categoryBitMask = 0xFFFFFFFF
  }

  // Helper function to create light nodes
  private func createLightNode(
    type: SCNLight.LightType,
    intensity: CGFloat,
    color: NSColor,
    castsShadow: Bool = false,
    position: SCNVector3? = nil,
    eulerAngles: SCNVector3? = nil
  ) -> SCNNode {
    let lightNode = SCNNode()
    lightNode.light = SCNLight()
    lightNode.light?.type = type
    lightNode.light?.intensity = intensity
    lightNode.light?.color = color
    lightNode.light?.castsShadow = castsShadow
    
    if let position = position {
      lightNode.position = position
    }
    if let eulerAngles = eulerAngles {
      lightNode.eulerAngles = eulerAngles
    }
    
    return lightNode
  }

  // Configure shadow settings for main directional light
  // 增强阴影对比度，让光影效果更明显
  private func configureShadowLight(_ light: SCNLight) {
    light.shadowMode = .deferred
    light.shadowRadius = 5.0
    light.shadowColor = NSColor.black.withAlphaComponent(0.55)  // 增强阴影深度
    light.shadowMapSize = CGSize(width: 2048, height: 2048)
    light.shadowBias = 2.0
    light.shadowSampleCount = 32
  }

  func setupUI() {
    guard debugMode else { return }
    allDebugButtons.forEach { view.addSubview($0) }
  }

  func setupGestureRecognizers() {
    let rightClickGesture = NSClickGestureRecognizer(
      target: self,
      action: #selector(handleRightClick(_:))
    )
    rightClickGesture.buttonMask = 0x2
    scnView.addGestureRecognizer(rightClickGesture)
  }

  // MARK: - Shadow Configuration

  /// Recursively enable shadow casting for a node and all its children
  func enableShadowCasting(for node: SCNNode) {
    // If node has geometry, enable shadow casting
    if node.geometry != nil {
      node.castsShadow = true
    }
    
    // Recursively process all child nodes
    for childNode in node.childNodes {
      enableShadowCasting(for: childNode)
    }
  }
}
