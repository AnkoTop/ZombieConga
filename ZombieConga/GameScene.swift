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
    let zombieRotateRadiansPerSec:CGFloat = 4.0 * π
    var velocity = CGPoint.zero
    let playableRect: CGRect
    
    var lastTouchedLocation : CGPoint?
    
    
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
        
        // #1: The background
        backgroundColor = SKColor.blackColor()
        let background = SKSpriteNode(imageNamed: "background1")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) // default
        background.zPosition = -1
        addChild(background)
        
        // #2: The Zombie
        zombie.position = CGPoint(x: 400, y: 400)
        addChild(zombie)
        
        //@DEBUG
        //debugDrawPlayableArea()
    }
    
    
    override func update(currentTime: NSTimeInterval) {
       
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        let amountToMoveZombie = zombieMovePointsPerSec * CGFloat(dt)
        if lastTouchedLocation != nil && (lastTouchedLocation! - zombie.position).length() <= amountToMoveZombie {
            zombie.position = lastTouchedLocation!
            velocity = CGPoint(x: 0, y: 0)
        } else {
            moveSprite(zombie, velocity: velocity)
            // make sure the zombie stays on the screen
            boundsCheckZombie()
            // use correct rotation of the zombie
            rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
        }
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
   
        let amountToMove = velocity * CGFloat(dt)
        // print("Amount to move: \(amountToMove)")
        sprite.position += amountToMove
    }
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        
        // shortest angle to rotate
        let shortest = shortestAngleBetween(sprite.zRotation, angle2: direction.angle)
        // rotation in this frame
        let amtToRotate = rotateRadiansPerSec * CGFloat(dt)
        let amount = min(amtToRotate, abs(shortest))
        
        sprite.zRotation += shortest.sign() * amount
       
        
    }
    
    
    func moveZombieToward(location: CGPoint) {
        // get the offset
        let offset = location - zombie.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
        
    }
    
    func boundsCheckZombie() {
 
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
        lastTouchedLocation = touchLocation
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
