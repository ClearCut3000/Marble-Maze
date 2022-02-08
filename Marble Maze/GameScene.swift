//
//  GameScene.swift
//  Marble Maze
//
//  Created by Николай Никитин on 05.02.2022.
//

import SpriteKit
import CoreMotion

final class GameScene: SKScene, SKPhysicsContactDelegate {

  //MARK: - Properties
  private var player: SKSpriteNode!
  private var lastTouchPosition: CGPoint?
  private var motionManager: CMMotionManager?
  private var scoreLabel: SKLabelNode!
  private var score = 0 {
    didSet {
      scoreLabel.text = "Score: \(score)"
    }
  }
  private var isGameOver = false
  private var items = [String]()
  private var teleportDestination = [CGPoint]()

  //MARK: - Scene
  override func didMove(to view: SKView) {
    createBackground()
    createScoreLabel()
    loadLevel()
    createPlayer()
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
    motionManager = CMMotionManager()
    motionManager?.startAccelerometerUpdates()
  }

  override func update(_ currentTime: TimeInterval) {
    guard isGameOver == false else { return }
    #if targetEnvironment(simulator)
    if let lastTouchPosition = lastTouchPosition {
      let diff = CGPoint(x: lastTouchPosition.x - player.position.x, y: lastTouchPosition.y - player.position.y)
      physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
    }
    #else
    if let accelrometerData = motionManager?.accelerometerData {
      physicsWorld.gravity = CGVector(dx: accelrometerData.acceleration.y * -50, dy: accelrometerData.acceleration.x * 50)
    }
    #endif
  }

  //MARK: - UIMethods
  private func loadLevel() {
    var random = Int.random(in: 1...3)
    guard let levelURL = Bundle.main.url(forResource: "level\(random)", withExtension: "txt") else {
      fatalError("Could't find level.txt in the app bundle!")
    }
    guard let levelString = try? String(contentsOf: levelURL) else {
      fatalError("Could't load level.txt in the app bundle!")
    }
    let lines = levelString.components(separatedBy: "\n")
    for (row, line) in lines.reversed().enumerated() {
      for (column, letter) in line.enumerated() {
        let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
        if letter == "x" {
          createBlock(in: position)
        } else if letter == "v" {
          createVortex(in: position)
        } else if letter == "s" {
          createStar(in: position)
        } else if letter == "f" {
          createFinish(in: position)
        } else if letter == "t" {
          createTeleportEntrance(in: position)
        } else if letter == "e" {
          createTeleportExit(in: position)
        } else if letter == " " {
          //just do nothing
        } else {
          fatalError("Unknown level letter: \(letter)")
        }
      }
    }
  }

  private func createBlock(in position: CGPoint) {
    let node = SKSpriteNode(imageNamed: "block")
    node.name = "block"
    items.append(node.name!)
    node.position = position
    node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
    node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
    node.physicsBody?.isDynamic = false
    addChild(node)
  }

  private func createVortex(in position: CGPoint) {
    let node = SKSpriteNode(imageNamed: "vortex")
    node.name = "vortex"
    items.append(node.name!)
    node.position = position
    node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
    node.physicsBody?.isDynamic = false
    node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
    node.physicsBody?.collisionBitMask = 0
    addChild(node)
  }

  private func createStar(in position: CGPoint) {
    let node = SKSpriteNode(imageNamed: "star")
    node.name = "star"
    items.append(node.name!)
    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
    node.physicsBody?.isDynamic = false
    node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
    node.physicsBody?.collisionBitMask = 0
    node.position = position
    addChild(node)
  }

  private func createFinish(in position: CGPoint) {
    let node = SKSpriteNode(imageNamed: "finish")
    node.name = "finish"
    items.append(node.name!)
    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
    node.physicsBody?.isDynamic = false
    node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
    node.physicsBody?.collisionBitMask = 0
    node.position = position
    addChild(node)
  }

  private func createTeleportEntrance(in position: CGPoint) {
    let node = SKSpriteNode(imageNamed: "vortex")
    node.name = "teleportEntrance"
    items.append(node.name!)
    node.position = position
    node.run(SKAction.repeatForever(SKAction.rotate(byAngle: -.pi, duration: 0.25)))
    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
    node.physicsBody?.isDynamic = false
    node.physicsBody?.categoryBitMask = CollisionTypes.teleport.rawValue
    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
    node.physicsBody?.collisionBitMask = 0
    node.color = .green
    node.colorBlendFactor = 0.8
    addChild(node)
  }

  private func createTeleportExit(in position: CGPoint) {
    let node = SKSpriteNode(imageNamed: "vortex")
    node.name = "teleportExit"
    items.append(node.name!)
    node.position = position
    teleportDestination.append(node.position)
    node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 0.25)))
    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
    node.physicsBody?.isDynamic = false
    node.physicsBody?.categoryBitMask = CollisionTypes.teleport.rawValue
    node.physicsBody?.collisionBitMask = 0
    node.color = .green
    node.colorBlendFactor = 0.5
    addChild(node)
  }

  private func createBackground() {
    let background = SKSpriteNode(imageNamed: "background")
    background.position = CGPoint(x: 512, y: 384)
    background.blendMode = .replace
    background.zPosition = -1
    addChild(background)
  }

  private func createScoreLabel() {
    scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    scoreLabel.text = "Score: 0"
    scoreLabel.horizontalAlignmentMode = .left
    scoreLabel.position = CGPoint(x: 16, y: 16)
    scoreLabel.zPosition = 2
    addChild(scoreLabel)
  }

  private func createPlayer() {
    player = SKSpriteNode(imageNamed: "player")
    player.position = CGPoint(x: 96, y: 672)
    player.zPosition = 1
    player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
    player.physicsBody?.allowsRotation = false
    player.physicsBody?.linearDamping = 0.5
    player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
    player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue | CollisionTypes.teleport.rawValue
    player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
    addChild(player)
  }

  private func clearLevel() {
    player.removeFromParent()
    for item in items {
      self.children.filter({$0.name == item}).forEach({$0.removeFromParent()})
    }
    items.removeAll()
    teleportDestination.removeAll()
    }

  //MARK: - SKPhysicsContactDelegate Methods
  func didBegin(_ contact: SKPhysicsContact) {
    guard let nodeA = contact.bodyA.node else { return }
    guard let nodeB = contact.bodyB.node else { return }
    if nodeA == player {
      playerCollided(with: nodeB)
    } else if nodeB == player {
      playerCollided(with: nodeA)
    }
  }

  private func playerCollided(with node: SKNode) {
    if node.name == "vortex" {
      player.physicsBody?.isDynamic = false
      isGameOver = true
      score = (score > 0) ? (score - 1) : 0
      let move = SKAction.move(to: node.position, duration: 0.5)
      let scale = SKAction.scale(to: 0.0001, duration: 0.25)
      let remove = SKAction.removeFromParent()
      let sequence = SKAction.sequence([move, scale, remove])
      player.run(sequence) { [weak self] in
        self?.createPlayer()
        self?.isGameOver = false
      }
    } else if node.name == "star" {
      node.removeFromParent()
      score += 1
    } else if node.name == "teleportEntrance" {
        let move = SKAction.move(to: node.position, duration: 0.25)
        let scale = SKAction.scale(to: 0.0001, duration: 0.25)
        let sequence = SKAction.sequence([move, scale])
      if let teleportation = teleportDestination.randomElement() {
        player.run(sequence) { [weak self] in
          self?.player.run(SKAction.scale(to: 1, duration: 0.5))
          self?.player.position = teleportation
        }
      }
    } else if node.name == "finish" {
      clearLevel()
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        self.loadLevel()
        self.createPlayer()
      }
    }
  }

  //MARK: - Touches Methods
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)
    lastTouchPosition = location
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)
    lastTouchPosition = location
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    lastTouchPosition = nil
  }
}
