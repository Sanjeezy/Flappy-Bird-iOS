//
//  GameScene.swift
//  FloppyBird
//
//  Created by Sanjay Tamizharasu on 7/14/17.
//  Copyright © 2017 SanjayTamizharasu. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var bird = SKSpriteNode()
    var backGround = SKSpriteNode()
    let ground = SKNode()
    var topPipe = SKSpriteNode()
    var bottomPipe = SKSpriteNode()
    var gameOverLabel = SKLabelNode()
    var scoreLabel = SKLabelNode()
    var score = 0
    var gameOver = false
    var timer = Timer()
    enum ColliderType: UInt32 {
        case Bird = 1
        case Object = 2
        case Gap = 4
    }
    
    func makePipes() {
        //// Set up pipes
        let topPipeImg = SKTexture(imageNamed: "pipe1.png")
        let bottomPipeImg = SKTexture(imageNamed: "pipe2.png")

        //Place pipe to the right and move it 2 screens left, time interval is relative to the device screen size (600 pixels = 6 seconds)
        let movePipes = SKAction.move(by: CGVector(dx: -2 * self.frame.width, dy: 0), duration: TimeInterval(self.frame.width / 100))
        
        //distance between pipe and bird
        let gapHeight = bird.size.height * 4
        //Randomizes position of the pipes, max amount can be half the screen size arc4Random generates a random number, modulo it be within range
        let movementAmount = arc4random() % UInt32(self.frame.height/2)
        //moves pipe as well as down, -1/4th of screen height to 1/4th of screen height for the offset
        let pipeOffset = CGFloat(movementAmount) - (self.frame.height/4)
        
        topPipe = SKSpriteNode(texture: topPipeImg)
        topPipe.position = CGPoint(x: self.frame.midX + self.frame.width, y: self.frame.midY + topPipeImg.size().height/2 + gapHeight/2 + pipeOffset)
        topPipe.run(movePipes)
        
        bottomPipe = SKSpriteNode(texture: bottomPipeImg)
        bottomPipe.position = CGPoint(x: self.frame.midX + self.frame.width, y: self.frame.midY - bottomPipeImg.size().height/2 - gapHeight/2 + pipeOffset)
        bottomPipe.run(movePipes)
        
        topPipe.physicsBody = SKPhysicsBody(rectangleOf: topPipeImg.size())
        bottomPipe.physicsBody = SKPhysicsBody(rectangleOf: bottomPipeImg.size())
        
        topPipe.physicsBody?.isDynamic = false
         bottomPipe.physicsBody?.isDynamic = false
        
        topPipe.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
        topPipe.physicsBody?.categoryBitMask = ColliderType.Object.rawValue
        topPipe.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        
        bottomPipe.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
        bottomPipe.physicsBody?.categoryBitMask = ColliderType.Object.rawValue
        bottomPipe.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        
        self.addChild(topPipe)
        self.addChild(bottomPipe)
        
        let gap = SKNode()
        
        gap.position = CGPoint(x: self.frame.midX + self.frame.width, y: self.frame.midY + pipeOffset)
        gap.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: topPipeImg.size().width, height: gapHeight))
        gap.physicsBody?.isDynamic = false
        gap.run(movePipes)
        
        gap.physicsBody?.contactTestBitMask = ColliderType.Bird.rawValue
        gap.physicsBody?.categoryBitMask = ColliderType.Gap.rawValue
        gap.physicsBody?.collisionBitMask = ColliderType.Gap.rawValue
        
        self.addChild(gap)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if gameOver == false {
        
            //Tests to see if collision with gap happened
            if contact.bodyA.categoryBitMask == ColliderType.Gap.rawValue || contact.bodyB.categoryBitMask == ColliderType.Gap.rawValue {
            
                print("Add 1 to score")
                score += 1
                scoreLabel.text = String(score)
            }else{
                print("we have contact")
                //stops the game - triggers game over state
                bird.physicsBody!.isDynamic = false
                self.speed = 0
                gameOver = true
                timer.invalidate()

                gameOverLabel.fontName = "Helvetica"
                gameOverLabel.fontSize = 35
                gameOverLabel.text = "You Done Fucked Up! Tap to play again."
                gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
                gameOverLabel.zPosition = 1
            
                self.addChild(gameOverLabel)
            }
        }
    }
    
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = self
        setupGame()
    }
    
    
    func setupGame() {
        
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.makePipes), userInfo: nil, repeats: true)
        
        let birdImg = SKTexture(imageNamed: "flappy1.png")
        let birdImg2 = SKTexture(imageNamed: "flappy2.png")
        let bgImg = SKTexture(imageNamed: "bg.png")
        
        let animation = SKAction.animate(with: [birdImg, birdImg2], timePerFrame: 0.1)  //Provides flapping animation
        let birdFlap = SKAction.repeatForever(animation) //Repeats above animation forever
        
        //moves background image all the way to left, duration controls how fast the background moves
        let moveBGAnimation = SKAction.move(by: CGVector(dx: -bgImg.size().width, dy:0), duration: 7)
        //jumps image back to right to simulate continuous move
        let shiftBG = SKAction.move(by: CGVector(dx:bgImg.size().width, dy:0), duration: 0)
        let continueBGMove = SKAction.repeatForever(SKAction.sequence([moveBGAnimation, shiftBG]))
        
        //Loops to replace background with itself constantly, so we don't appear to "run out" of background
        var i: CGFloat = 0
        
        while i < 3 {
            backGround = SKSpriteNode(texture: bgImg)
            backGround.position = CGPoint(x: bgImg.size().width * i, y:self.frame.midY)
            backGround.size.height = self.frame.height
            backGround.run(continueBGMove)
            backGround.zPosition = -1
            
            self.addChild(backGround)
            
            i+=1
        }
        
        bird = SKSpriteNode(texture: birdImg)
        bird.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        bird.run(birdFlap)  //Applies the flapping animation to our bird variable
        
        //Sets gravity for bird texture, radius of circle is height of texture divided by 2
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdImg.size().height/2)
        bird.physicsBody?.isDynamic = false
        
        bird.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
        bird.physicsBody?.categoryBitMask = ColliderType.Bird.rawValue
        bird.physicsBody?.collisionBitMask = ColliderType.Bird.rawValue
        
        ground.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
        ground.physicsBody?.categoryBitMask = ColliderType.Object.rawValue
        ground.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        
        self.addChild(bird)
        
        //set up the ground
        ground.position = CGPoint(x:self.frame.midX, y: -self.frame.height/2) //set y to be half the height of the screen, to the bottom
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.width, height: 1))
        ground.physicsBody?.isDynamic = false
        
        self.addChild(ground)
        
        //Set up the score label
        scoreLabel.fontName = "Helvetica"
        scoreLabel.fontSize = 60
        scoreLabel.text = "0"
        scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.height / 2 - 70)
        scoreLabel.zPosition = 1
        
        self.addChild(scoreLabel)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if gameOver == false {
            //Setting isDynamic to true will have gravity affect the bird, set this here so it doesn't begin until user begins tapping
            bird.physicsBody?.isDynamic = true
            //Affects speed at which bird will fall
            bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            //Applies small "jolt" upwards by 50 pixels once screen is tapped
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 50))
        } else{
            //Player has tapped the game to restart
            gameOver = false
            score = 0
            self.speed = 1
            self.removeAllChildren()
            setupGame()
        }
    }
    
    
    
    override func update(_ currentTime: TimeInterval) {
        //Called before each frame is rendered
    }

}
