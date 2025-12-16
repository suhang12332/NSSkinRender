//
//  SceneKitCharacterViewController+Setup.swift
//  SkinRenderKit
//

import SceneKit

extension SceneKitCharacterViewController {

  func setupScene() {
    scene = SCNScene()
    scnView.scene = scene
    scnView.allowsCameraControl = true
    scnView.backgroundColor = backgroundColor
    scnView.showsStatistics = debugMode
  }

  func setupCamera() {
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = CharacterDimensions.cameraPosition
    cameraNode.look(at: CharacterDimensions.cameraTarget)
    scene.rootNode.addChildNode(cameraNode)
  }

  func setupLighting() {
    // Ambient light
    createAndAddLight(
      type: .ambient,
      intensity: CharacterDimensions.Lighting.ambientIntensity
    )

    // Directional light
    createAndAddLight(
      type: .directional,
      intensity: CharacterDimensions.Lighting.directionalIntensity,
      eulerAngles: CharacterDimensions.Lighting.directionalAngles
    )
  }

  private func createAndAddLight(
    type: SCNLight.LightType,
    intensity: CGFloat,
    eulerAngles: SCNVector3 = SCNVector3Zero
  ) {
    let lightNode = SCNNode()
    lightNode.light = SCNLight()
    lightNode.light?.type = type
    lightNode.light?.intensity = intensity
    lightNode.eulerAngles = eulerAngles
    scene.rootNode.addChildNode(lightNode)
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
}
