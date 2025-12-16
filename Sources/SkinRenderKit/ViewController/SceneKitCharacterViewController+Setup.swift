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
    let ambientLight = SCNNode()
    ambientLight.light = SCNLight()
    ambientLight.light?.type = .ambient
    ambientLight.light?.intensity = CharacterDimensions.Lighting.ambientIntensity
    scene.rootNode.addChildNode(ambientLight)

    // Directional light
    let directionalLight = SCNNode()
    directionalLight.light = SCNLight()
    directionalLight.light?.type = .directional
    directionalLight.light?.intensity = CharacterDimensions.Lighting.directionalIntensity
    directionalLight.eulerAngles = CharacterDimensions.Lighting.directionalAngles
    scene.rootNode.addChildNode(directionalLight)
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
