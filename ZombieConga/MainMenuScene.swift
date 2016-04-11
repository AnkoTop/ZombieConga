//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Anko Top on 10/04/16.
//  Copyright © 2016 Anko Top. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
    
    override func didMoveToView(view: SKView) {
    
        backgroundColor = SKColor.blackColor()
        let background = SKSpriteNode(imageNamed: "MainMenu")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) // default
        background.zPosition = -1
        addChild(background)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        sceneTapped()
    }
    
    
    func sceneTapped() {
        
        let block = SKAction.runBlock {
            let myScene = GameScene(size: self.size)
            myScene.scaleMode = self.scaleMode
            let doorway = SKTransition.doorsOpenHorizontalWithDuration(1.5)
            self.view?.presentScene(myScene, transition: doorway)
        }
        runAction(block)
    }
    
}
