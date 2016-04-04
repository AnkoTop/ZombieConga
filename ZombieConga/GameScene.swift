//
//  GameScene.swift
//  ZombieConga
//
//  Created by Anko Top on 03/04/16.
//  Copyright (c) 2016 Anko Top. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    let playableRect: CGRect
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.0/9.0 // 1
        let playableHeight = size.width / maxAspectRatio // 2
        let playableMargin = (size.height-playableHeight)/2.0 // 3
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight) // 4
        super.init(size: size) // 5
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func didMoveToView(view: SKView) {
        
        //Setting the scene for the gaem
        
        // #1: The background
        backgroundColor = SKColor.blackColor()
        let background = SKSpriteNode(imageNamed: "background1")
        
        // center the image (in this case the anchorpoint is the middle of the image
        //background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // alternative method of centering (set anchorpoint to the lower left corner
        //background.anchorPoint = CGPoint.zero
        //background.position = CGPoint.zero
        
        // same as the first one
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) // default
        
        // note needed: rotation of the image (code-example)
        //background.zRotation = CGFloat(M_PI) / 8
        
        // make sure the background will be in the back!
        background.zPosition = -1
        
        addChild(background)
        let mySize = background.size
        print("size: \(mySize)")
        
        // #2: The Zombie
         zombie.position = CGPoint(x: 400, y: 400)
        // Scale it to 2.0 (code-example)
        //zombie.setScale(2.0)
        addChild(zombie)
        
        //debugging
        debugDrawPlayableArea()
    }
    
    
    override func update(currentTime: NSTimeInterval) {
        
        // check time passed since last update
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        print("\(dt*1000) milliseconds since last update")
        
        // movement 1: use fixed amount
        //zombie.position = CGPoint(x: zombie.position.x + 8, y: zombie.position.y)
        // movement 2: velocity * dt
        //moveSprite(zombie, velocity: CGPoint(x: zombieMovePointsPerSec, y: 0))
        // movement 3:
        moveSprite(zombie, velocity: velocity)
        // make sure zombie stays on the screen
        boundsCheckZombie()
        // use correct rotation of the zombie
        rotateSprite(zombie, direction: velocity)
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        // 1a: old version
        //let amountToMove = CGPoint(x: velocity.x * CGFloat(dt), y: velocity.y * CGFloat(dt))
        // 1b: new version thanks to functions in MyyUtils
        let amountToMove = velocity * CGFloat(dt)  // MyUtils
        print("Amount to move: \(amountToMove)")
        // 2a: old version
        //sprite.position = CGPoint(x: sprite.position.x + amountToMove.x, y: sprite.position.y + amountToMove.y )
        // 2b: new version thanks to functions in MyyUtils
        sprite.position += amountToMove // MyUtils
    }
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint) {
        //sprite.zRotation = CGFloat(atan2(Double(direction.y), Double(direction.x)))
        sprite.zRotation = direction.angle
    }
    
    
    func moveZombieToward(location: CGPoint) {
        // get the offset
        //let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
        let offset = location - zombie.position // MyUtils
        // get length of offset
        //let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        // make the offset vector a set length
        //let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        let direction = offset.normalized() // MyUtils
        //velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y: direction.y * zombieMovePointsPerSec)
        velocity = direction * zombieMovePointsPerSec
        
    }
    
    func boundsCheckZombie() {
        // bounds without taking playable recy into account
        //let bottomLeft = CGPointZero
        //let topRight = CGPoint(x: size.width, y: size.height)
        // ... and with
        let bottomLeft = CGPoint(x: 0, y: CGRectGetMinY(playableRect))
        let topRight = CGPoint(x: size.width, y: CGRectGetMaxY(playableRect))
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func sceneTouched(touchLocation:CGPoint) {
        moveZombieToward(touchLocation)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        
        let touchLocation = touch.locationInNode(self)
        sceneTouched(touchLocation)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        
        let touchLocation = touch.locationInNode(self)
        sceneTouched(touchLocation)
    }
    
    
    //MARK: Helper & DEBUG
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, playableRect)
        shape.path = path
        shape.strokeColor = SKColor.redColor()
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
}
