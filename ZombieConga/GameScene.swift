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
    var zombieIsInvincible = false
    var velocity = CGPoint.zero
    let playableRect: CGRect
    let zombieAnimation: SKAction
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    
    var lastTouchedLocation : CGPoint?
    
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.0/9.0 // 1
        let playableHeight = size.width / maxAspectRatio // 2
        let playableMargin = (size.height-playableHeight)/2.0 // 3
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight) // 4
        
        //animate the zombie
        // 1
        var textures:[SKTexture] = []
        // 2
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        // 3
        textures.append(textures[2])
        textures.append(textures[1])
        // 4
        zombieAnimation = SKAction.animateWithTextures(textures, timePerFrame: 0.1)
        
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
        // animate the walk
        //zombie.runAction(SKAction.repeatActionForever(zombieAnimation))
        
        // #3a: The Enemy (once)
        //spawnEnemyOnce()
        // #3b: The Enemy (spawning)
        runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.runBlock(spawnEnemy),SKAction.waitForDuration(2.0)])))
        
        // #4: The Cats
        runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.runBlock(spawnCat),SKAction.waitForDuration(1.0)])))
        
        
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
            // stop the walk animation
            stopZombieAnimation()  
        } else {
            moveSprite(zombie, velocity: velocity)
            // make sure the zombie stays on the screen
            boundsCheckZombie()
            // use correct rotation of the zombie
            rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
        }
        
        
        // Doing it her is the wrong place: it will always be 1 frame behind!
        //checkCollisions()
    }
    
    
    override func didEvaluateActions() {
        checkCollisions()   
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
        // start the walk animation
        startZombieAnimation()
        // get the offset
        let offset = location - zombie.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
        
    }
    
    func startZombieAnimation() {
    
        if zombie.actionForKey("animation") == nil {
            zombie.runAction(
                SKAction.repeatActionForever(zombieAnimation),
                withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
    
        zombie.removeActionForKey("animation")
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
    
    func spawnEnemyOnce() {
        //Create the enemy
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: size.height/2)
        addChild(enemy)
        //And make it move in a straight line
        //let actionMove = SKAction.moveTo(CGPoint(x: -enemy.size.width/2, y: enemy.position.y), duration: 2.0)
        //enemy.runAction(actionMove)
        
        // Or move in a V-shape
        // 1 non reversible
        //let actionMidMove = SKAction.moveTo(CGPoint(x: size.width/2, y: CGRectGetMinY(playableRect) + enemy.size.height/2), duration: 1.0)
        // 2 non reversible
        //let actionMove = SKAction.moveTo(CGPoint(x: -enemy.size.width/2, y: enemy.position.y), duration:1.0)
        // 1 reversible
        let actionMidMove = SKAction.moveByX(-size.width/2-enemy.size.width/2, y: -CGRectGetHeight(playableRect)/2 + enemy.size.height/2, duration: 1.0)
        // 2 reversible
        let actionMove = SKAction.moveByX(-size.width/2-enemy.size.width/2, y: CGRectGetHeight(playableRect)/2 - enemy.size.height/2, duration: 1.0)
        
        
        // 3a simple
        //let sequence = SKAction.sequence([actionMidMove, actionMove])
        // 3b with wait
        //let wait = SKAction.waitForDuration(0.25)
        //let sequence = SKAction.sequence([actionMidMove, wait, actionMove])
        //3c with wait + log message in block
        let wait = SKAction.waitForDuration(0.25)
        let logMessage = SKAction.runBlock() {
            print("Reached bottom!")
            // could be any code here...
        }
        // non reversible
        //let sequence = SKAction.sequence([actionMidMove, logMessage, wait, actionMove])
        //reversible
        //let reverseMid = actionMidMove.reversedAction()
        //let reverseMove = actionMove.reversedAction()
        //let sequence = SKAction.sequence([actionMidMove, logMessage, wait, actionMove, reverseMove, logMessage, wait, reverseMid])
        let halfSequence = SKAction.sequence([actionMidMove, logMessage, wait, actionMove])
        let sequence = SKAction.sequence([halfSequence, halfSequence.reversedAction()])
        // 4a single action
        //enemy.runAction(sequence)
        // 4b forever repeating action
        let repeatAction = SKAction.repeatActionForever(sequence)
        enemy.runAction(repeatAction)
    }
    
    func spawnEnemy() {
        //Create the enemy
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: CGFloat.random(min: CGRectGetMinY(playableRect) + enemy.size.height/2, max: CGRectGetMaxY(playableRect) - enemy.size.height/2))
        addChild(enemy)
        //And make it move in a straight line
        let actionMove = SKAction.moveTo(CGPoint(x: -enemy.size.width/2, y: enemy.position.y), duration: 2.0)
        //enemy.runAction(actionMove)
        // make sure to remove it afterwards...
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
    }
    
    
    func spawnCat() {
        // 1
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(
            x: CGFloat.random(min: CGRectGetMinX(playableRect),
                max: CGRectGetMaxX(playableRect)),
            y: CGFloat.random(min: CGRectGetMinY(playableRect),
                max: CGRectGetMaxY(playableRect)))
        cat.setScale(0)
        addChild(cat)
        // 2
        let appear = SKAction.scaleTo(1.0, duration: 0.5)
        // a) waittime before disappearing
        //let wait = SKAction.waitForDuration(10.0)
        // or wiggle while waiting
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotateByAngle(π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversedAction()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        //let wiggleWait = SKAction.repeatAction(fullWiggle, count: 10)
        // Or wiggle as a group
        let scaleUp = SKAction.scaleBy(1.2, duration: 0.25)
        let scaleDown = scaleUp.reversedAction()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeatAction(group, count: 10)
        let disappear = SKAction.scaleTo(0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        // a) the just wait type
        //let actions = [appear, wait, disappear, removeFromParent]
        // b) the single wiggle type
        //let actions = [appear, wiggleWait, disappear, removeFromParent]
        // b) and the group wiggle
        let actions = [appear, groupWait, disappear, removeFromParent]
        
        cat.runAction(SKAction.sequence(actions))
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
    
    
    
    func zombieHitCat(cat: SKSpriteNode) {
        cat.removeFromParent()
        //runAction(SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false))
        runAction(catCollisionSound)
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
        zombieIsInvincible = true
        //enemy.removeFromParent()
        //runAction(SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false))
        runAction(enemyCollisionSound)

        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customActionWithDuration(duration) {
            node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime) % slice
            node.hidden = remainder > slice / 2
        }
        runAction(blinkAction) { void in
            self.zombie.hidden = false
            self.zombieIsInvincible = false
            
        }
    }
    
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodesWithName("cat") { node, _ in
            let cat = node as! SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.zombie.frame) {
                hitCats.append(cat)
            }
        }
        for cat in hitCats {
            zombieHitCat(cat)
        }
        
        var hitEnemies: [SKSpriteNode] = []
        if !zombieIsInvincible {
            enumerateChildNodesWithName("enemy") { node, _ in
                let enemy = node as! SKSpriteNode
                if CGRectIntersectsRect(
                    CGRectInset(node.frame, 20, 20), self.zombie.frame) {
                    hitEnemies.append(enemy)
                }
            }
            for enemy in hitEnemies {
                zombieHitEnemy(enemy)
            }
        }
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
