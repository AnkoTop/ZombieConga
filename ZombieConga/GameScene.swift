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
    let zombieMovePointsPerSec: CGFloat = 480.0
    let zombieRotateRadiansPerSec:CGFloat = 4.0 * π
    var zombieIsInvincible = false
    var zombieLives = 5
    
    let trainCatMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    let playableRect: CGRect
    let zombieAnimation: SKAction
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    
    let cameraNode = SKCameraNode()
    let cameraMovePointsPerSec: CGFloat = 200.0
    
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    var lastTouchedLocation : CGPoint?
    var gameOver = false
    
    //let livesLabel = SKLabelNode(fontNamed: "Chalkduster")
    let livesLabel = SKLabelNode(fontNamed: "Glimstick")
    let catsLabel = SKLabelNode(fontNamed: "Glimstick")
    
    
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
        
        // #0: The Music
        playBackgroundMusic("backgroundMusic.mp3")
        
        // #1: The background
        backgroundColor = SKColor.blackColor()
        // 1a: old version
        //let background = SKSpriteNode(imageNamed: "background1")
        //background.position = CGPoint(x: size.width/2, y: size.height/2)
        //background.anchorPoint = CGPoint(x: 0.5, y: 0.5) // default
        //1b: new version
        //let background = backgroundNode()
        //background.anchorPoint = CGPoint.zero
        //background.position = CGPoint.zero
        //background.name = "background"
        //background.zPosition = -1
        //addChild(background)
    
        //1c: the endless scrolling version
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPointZero
            background.position = CGPoint(x: CGFloat(i)*background.size.width, y: 0)
            background.name = "background"
            background.zPosition = -1
            addChild(background)
        }
        
        
        
        // #2: The Zombie
        zombie.position = CGPoint(x: 400, y: 400)
        zombie.zPosition =  100 // make sure zombie's on top...
    
        addChild(zombie)
        // animate the walk
        //zombie.runAction(SKAction.repeatActionForever(zombieAnimation))
        
        // #3a: The Enemy (once)
        //spawnEnemyOnce()
        // #3b: The Enemy (spawning)
        runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.runBlock(spawnEnemy),SKAction.waitForDuration(2.0)])))
        
        // #4: The Cats
        runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.runBlock(spawnCat),SKAction.waitForDuration(1.0)])))
        
        
        // #5: The camera
        addChild(cameraNode)
        camera = cameraNode
        //cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        setCameraPosition(CGPoint(x: size.width/2, y: size.height/2))
        
        //#6: The Labels
        livesLabel.text = "Lives: X"
        livesLabel.fontColor = SKColor.blackColor()
        livesLabel.fontSize = 100
        livesLabel.zPosition = 100
        livesLabel.horizontalAlignmentMode = .Left
        livesLabel.verticalAlignmentMode = .Bottom
        livesLabel.position = CGPoint(x: -playableRect.size.width/2 + CGFloat(20), y: -playableRect.size.height/2 + CGFloat(20) + overlapAmount()/2)
        cameraNode.addChild(livesLabel) //add it to the camera so it remains visible
        catsLabel.text = "Cats: X"
        catsLabel.fontColor = SKColor.blackColor()
        catsLabel.fontSize = 100
        catsLabel.zPosition = 100
        catsLabel.horizontalAlignmentMode = .Right
        catsLabel.verticalAlignmentMode = .Bottom
        catsLabel.position = CGPoint(x: +playableRect.size.width/2 - CGFloat(20), y: -playableRect.size.height/2 + CGFloat(20) + overlapAmount()/2)
        cameraNode.addChild(catsLabel) //add it to the camera so it remains visible
        
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
        
       
        /* Pre scrolling background
        let amountToMoveZombie = zombieMovePointsPerSec * CGFloat(dt)
         if lastTouchedLocation != nil && (lastTouchedLocation! - zombie.position).length() <= amountToMoveZombie {
            zombie.position = lastTouchedLocation!
            velocity = CGPoint(x: 0, y: 0)
            // stop the walk animation
            stopZombieAnimation()  
        } else {
        */
            moveSprite(zombie, velocity: velocity)
            // make sure the zombie stays on the screen
            boundsCheckZombie()
            // use correct rotation of the zombie
            rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
        //}
        
        
        // Doing it here is the wrong place: it will always be 1 frame behind!
        //checkCollisions()
        
        moveTrain()
        
        moveCamera()
        
        if zombieLives <= 0 {
            gameOver = true
            print ("You Lose: L!!!")
            backgroundMusicPlayer.stop()
            // 1
            //let gameOverScene = GameOverScene(size: size)
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            // 2
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            // 3
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
        
        // update camera position
        //cameraNode.position = zombie.position
        
    }
    
    
    override func didEvaluateActions() {
        checkCollisions()   
    }
    
    
    func backgroundNode() -> SKSpriteNode {
        // 1
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        // 2
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        // 3
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position =
            CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        // 4
        backgroundNode.size = CGSize(
            width: background1.size.width + background2.size.width,
            height: background1.size.height)
     
        return backgroundNode
    
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
        // pre scrolling background
        //let bottomLeft = CGPoint(x: 0, y: CGRectGetMinY(playableRect))
        //let topRight = CGPoint(x: size.width, y: CGRectGetMaxY(playableRect))
        //scrolling background
        let bottomLeft = CGPoint(x: CGRectGetMinX(cameraRect), y: CGRectGetMinY(cameraRect))
        let topRight = CGPoint(x: CGRectGetMaxX(cameraRect),y: CGRectGetMaxY(cameraRect))
        
        
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
    
    /*
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
    */
    
    func spawnEnemy() {
        //Create the enemy
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        // pre scrolling background
        //enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: CGFloat.random(min: CGRectGetMinY(playableRect) + enemy.size.height/2, max: CGRectGetMaxY(playableRect) - enemy.size.height/2))
        // scrolling background
        enemy.position = CGPoint(
            x: CGRectGetMaxX(cameraRect) + enemy.size.width/2,
            y: CGFloat.random(min: CGRectGetMinY(cameraRect) + enemy.size.height/2, max: CGRectGetMaxY(cameraRect) - enemy.size.height/2))
        enemy.zPosition = 50
        
        addChild(enemy)
        //And make it move in a straight line
        //pre scrolling background
        //let actionMove = SKAction.moveTo(CGPoint(x: -enemy.size.width/2, y: enemy.position.y), duration: 2.0)
        //with scrolling background
        let actionMove = SKAction.moveByX( -size.width-enemy.size.width*2, y: 0, duration: 3.0)
        
        //enemy.runAction(actionMove)
        // make sure to remove it afterwards...
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
    }
    
    
    func spawnCat() {
        // 1
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        // pre scrolling background
        //cat.position = CGPoint(
        //    x: CGFloat.random(min: CGRectGetMinX(playableRect),
        //        max: CGRectGetMaxX(playableRect)),
        //    y: CGFloat.random(min: CGRectGetMinY(playableRect),
        //        max: CGRectGetMaxY(playableRect)))
        //scrolling background
        cat.position = CGPoint(
            x: CGFloat.random(min: CGRectGetMinX(cameraRect),
                max: CGRectGetMaxX(cameraRect)),
            y: CGFloat.random(min: CGRectGetMinY(cameraRect),
                max: CGRectGetMaxY(cameraRect)))
        cat.zPosition = 50
        
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
    
    func loseCats() {
        // 1
        var loseCount = 0
        enumerateChildNodesWithName("train") { node, stop in
            // 2
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            // 3
            node.name = ""
            node.runAction(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotateByAngle(π*4, duration: 1.0),
                        SKAction.moveTo(randomSpot, duration: 1.0),
                        SKAction.scaleTo(0, duration: 1.0)
                        ]),
                    SKAction.removeFromParent()
                    ]))
                    // 4
                    loseCount += 1
                    if loseCount >= 2 {
                    stop.memory = true
            }
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
    
    
    
    func zombieHitCat(cat: SKSpriteNode) {
        //runAction(SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false))
        runAction(catCollisionSound)
        
        //Challenge 3: let the cat join the train
        //cat.removeFromParent()
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(CGFloat(1.0))
        cat.zRotation = CGFloat(0)
        let turnGreen = SKAction.colorizeWithColor(SKColor.greenColor(), colorBlendFactor: 1.0, duration: 0.2)
        cat.runAction(turnGreen)
        
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
        zombieIsInvincible = true
        //enemy.removeFromParent()
        //runAction(SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false))
        runAction(enemyCollisionSound)
        loseCats()
        zombieLives -= 1

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
    
    func moveTrain() {
        var trainCount = 0
        var targetPosition = zombie.position
        enumerateChildNodesWithName("train") {
            node, _ in
            trainCount += 1
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.trainCatMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveByX(amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.runAction(moveAction)
            }
            targetPosition = node.position
        }
        if trainCount >= 15 {
            gameOver = true
            print ("You WIN !!! Yeahhhh!")
            backgroundMusicPlayer.stop()
            // 1
            //let gameOverScene = GameOverScene(size: size)
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            // 2
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            // 3
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
        livesLabel.text = "Lives: \(zombieLives)"
        catsLabel.text = "Cats: \(trainCount)"
    }
    
    
    //MARK: Camera
    
    var cameraRect : CGRect {
        return CGRect(
            x: getCameraPosition().x - size.width/2 + (size.width - playableRect.width)/2,
            y: getCameraPosition().y - size.height/2 + (size.height - playableRect.height)/2,
            width: playableRect.width,
            height: playableRect.height)
    }
    
    
    func overlapAmount() -> CGFloat {
        guard let view = self.view else {
            return 0
        }
        let scale = view.bounds.size.width / self.size.width
        let scaledHeight = self.size.height * scale
        let scaledOverlap = scaledHeight - view.bounds.size.height
        return scaledOverlap / scale
    }
    
    func getCameraPosition() -> CGPoint {
        return CGPoint(x: cameraNode.position.x, y: cameraNode.position.y +
            overlapAmount()/2)
    }
    
    func setCameraPosition(position: CGPoint) {
        cameraNode.position = CGPoint(x: position.x, y: position.y -
            overlapAmount()/2)
    }
    
    
    func moveCamera() {
        let backgroundVelocity =
            CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        
        enumerateChildNodesWithName("background") { node, _ in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width <
                self.cameraRect.origin.x {
                background.position = CGPoint(
                    x: background.position.x + background.size.width*2,
                    y: background.position.y)
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
